import secrets
from datetime import date, datetime
from decimal import Decimal, ROUND_HALF_UP

from . import db
from .catalogo import Cupcake

CENTAVO = Decimal("0.01")
TEMPO_RETIRADA_MIN = 30          # US07 RN#2
MAX_ENTREGAS_SIMULTANEAS = 3     # US14 RN#1


class RegraNegocioErro(Exception):
    """Erro de regra de negócio, com mensagem pronta para mostrar ao usuário."""


class ZonaEntrega(db.Model):
    """US07 RN#1: o frete varia conforme a zona de entrega."""

    __tablename__ = "zonas_entrega"

    id = db.Column(db.Integer, primary_key=True)
    nome = db.Column(db.String(80), nullable=False, unique=True)
    taxa = db.Column(db.Numeric(6, 2), nullable=False)
    prazo_min = db.Column(db.Integer, nullable=False, default=45)


class Cupom(db.Model):
    """Classe Promocao do PIT I, agora com validade e limite de uso (US06 RN#1)."""

    __tablename__ = "cupons"

    id = db.Column(db.Integer, primary_key=True)
    codigo = db.Column(db.String(30), nullable=False, unique=True)
    descricao = db.Column(db.String(120), nullable=False, default="")
    percentual = db.Column(db.Integer, nullable=False)
    validade = db.Column(db.Date, nullable=False)
    limite_usos = db.Column(db.Integer)
    usos = db.Column(db.Integer, nullable=False, default=0)
    ativo = db.Column(db.Boolean, nullable=False, default=True)

    __table_args__ = (db.CheckConstraint("percentual BETWEEN 1 AND 90", name="ck_cupom_percentual"),)

    @classmethod
    def buscar_valido(cls, codigo, hoje=None):
        """US06 CA#3: informa se o cupom é inválido, expirado ou esgotado."""
        codigo = (codigo or "").strip().upper()
        if not codigo:
            return None
        cupom = cls.query.filter_by(codigo=codigo).first()
        if cupom is None or not cupom.ativo:
            raise RegraNegocioErro("Cupom inválido.")
        if cupom.validade < (hoje or date.today()):
            raise RegraNegocioErro("Este cupom expirou.")
        if cupom.limite_usos is not None and cupom.usos >= cupom.limite_usos:
            raise RegraNegocioErro("Este cupom atingiu o limite de usos.")
        return cupom

    def desconto_sobre(self, valor):
        return (Decimal(valor) * self.percentual / 100).quantize(CENTAVO, ROUND_HALF_UP)


class Pedido(db.Model):
    __tablename__ = "pedidos"

    STATUS = {
        "aguardando_pagamento": "Aguardando pagamento",
        "pendente": "Pagamento aprovado",
        "em_preparacao": "Em preparação",
        "saiu_para_entrega": "Saiu para entrega",
        "pronto_retirada": "Pronto para retirada",
        "entregue": "Entregue",
        "cancelado": "Cancelado",
    }
    ATIVOS = ("aguardando_pagamento", "pendente", "em_preparacao", "saiu_para_entrega", "pronto_retirada")
    # Transições permitidas para o administrador (o entregador só marca "entregue").
    TRANSICOES = {
        "aguardando_pagamento": ("cancelado",),
        "pendente": ("em_preparacao", "cancelado"),
        "em_preparacao": ("saiu_para_entrega", "pronto_retirada", "cancelado"),
        "saiu_para_entrega": ("entregue",),
        "pronto_retirada": ("entregue",),
    }

    id = db.Column(db.Integer, primary_key=True)
    codigo = db.Column(db.String(12), nullable=False, unique=True, default=lambda: secrets.token_hex(3).upper())
    cliente_id = db.Column(db.Integer, db.ForeignKey("usuarios.id"), nullable=False)
    entregador_id = db.Column(db.Integer, db.ForeignKey("usuarios.id"))
    cupom_id = db.Column(db.Integer, db.ForeignKey("cupons.id"))
    zona_id = db.Column(db.Integer, db.ForeignKey("zonas_entrega.id"))
    status = db.Column(db.String(30), nullable=False, default="pendente", index=True)
    metodo_entrega = db.Column(db.String(10), nullable=False)        # entrega | retirada
    endereco_entrega = db.Column(db.String(255))
    metodo_pagamento = db.Column(db.String(10), nullable=False)      # credito | debito | pix
    cartao_final = db.Column(db.String(4))                           # nunca guardamos o número completo
    pix_copia_cola = db.Column(db.String(255))
    subtotal = db.Column(db.Numeric(10, 2), nullable=False)
    desconto = db.Column(db.Numeric(10, 2), nullable=False, default=0)
    frete = db.Column(db.Numeric(10, 2), nullable=False, default=0)
    total = db.Column(db.Numeric(10, 2), nullable=False)
    criado_em = db.Column(db.DateTime, nullable=False, default=datetime.utcnow, index=True)
    atualizado_em = db.Column(db.DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)

    cliente = db.relationship("Usuario", back_populates="pedidos", foreign_keys=[cliente_id])
    entregador = db.relationship("Usuario", back_populates="entregas", foreign_keys=[entregador_id])
    cupom = db.relationship("Cupom")
    zona = db.relationship("ZonaEntrega")
    itens = db.relationship("ItemPedido", back_populates="pedido", cascade="all, delete-orphan")

    @property
    def status_legivel(self):
        return self.STATUS.get(self.status, self.status)

    @property
    def ativo(self):
        return self.status in self.ATIVOS

    @property
    def etapas(self):
        """Linha do tempo da tela de acompanhamento."""
        final = "saiu_para_entrega" if self.metodo_entrega == "entrega" else "pronto_retirada"
        return ["pendente", "em_preparacao", final, "entregue"]

    # ---------- criação do pedido (CU01 – Realizar Pedido) ----------
    @classmethod
    def criar(cls, cliente, carrinho, metodo_entrega, metodo_pagamento,
              endereco=None, zona_id=None, codigo_cupom=None, cartao=None, gateway=None):
        from ..pagamento import GatewaySimulado

        if not carrinho:
            raise RegraNegocioErro("Seu carrinho está vazio.")
        if metodo_entrega not in ("entrega", "retirada"):
            raise RegraNegocioErro("Escolha entrega ou retirada na loja.")
        if metodo_pagamento not in ("credito", "debito", "pix"):
            raise RegraNegocioErro("Escolha a forma de pagamento.")

        with db.session.no_autoflush:
            return cls._montar(cliente, carrinho, metodo_entrega, metodo_pagamento,
                               endereco, zona_id, codigo_cupom, cartao, gateway or GatewaySimulado())

    @classmethod
    def _montar(cls, cliente, carrinho, metodo_entrega, metodo_pagamento, endereco, zona_id, codigo_cupom, cartao, gateway):
        # Desconto e frete começam em zero de forma explícita: o default da coluna
        # só vale quando o registro é gravado (bug encontrado na 1ª execução dos testes).
        pedido = cls(metodo_entrega=metodo_entrega, metodo_pagamento=metodo_pagamento,
                     desconto=Decimal("0.00"), frete=Decimal("0.00"))

        subtotal = Decimal("0")
        for cupcake_id, quantidade in carrinho.items():
            cupcake = db.session.get(Cupcake, int(cupcake_id))
            if cupcake is None or not cupcake.ativo:
                raise RegraNegocioErro("Um item do carrinho não está mais disponível.")
            if quantidade > cupcake.estoque:
                raise RegraNegocioErro(f"Só temos {cupcake.estoque} unidade(s) de {cupcake.nome}.")
            pedido.itens.append(ItemPedido(cupcake=cupcake, quantidade=quantidade, preco_unitario=cupcake.preco))
            subtotal += Decimal(cupcake.preco) * quantidade

        pedido.subtotal = subtotal.quantize(CENTAVO)

        cupom = Cupom.buscar_valido(codigo_cupom)  # RN#2: só um cupom por pedido
        if cupom:
            pedido.cupom = cupom
            pedido.desconto = cupom.desconto_sobre(subtotal)

        if metodo_entrega == "entrega":
            zona = db.session.get(ZonaEntrega, int(zona_id)) if zona_id else None
            if zona is None:
                raise RegraNegocioErro("Escolha o bairro/zona de entrega.")
            if not (endereco or "").strip():
                raise RegraNegocioErro("Informe o endereço de entrega.")
            pedido.zona = zona
            pedido.frete = zona.taxa
            pedido.endereco_entrega = endereco.strip()

        pedido.total = (pedido.subtotal - Decimal(pedido.desconto) + Decimal(pedido.frete)).quantize(CENTAVO)

        if metodo_pagamento == "pix":
            pedido.status = "aguardando_pagamento"
            pedido.pix_copia_cola = gateway.gerar_pix(pedido.total)
        else:
            resultado = gateway.cobrar_cartao(cartao or {}, pedido.total)  # CU01-B: pode ser recusado
            pedido.cartao_final = resultado.final
            pedido.status = "pendente"

        for item in pedido.itens:  # US12 RN#1: baixa de estoque (reserva) ao registrar o pedido
            item.cupcake.ajustar_estoque(-item.quantidade)
        if cupom:
            cupom.usos += 1

        pedido.cliente = cliente  # só agora entra na sessão, depois de todas as validações
        db.session.add(pedido)
        db.session.flush()
        Notificacao.para_admins(f"Novo pedido #{pedido.codigo} de {cliente.nome} – R$ {pedido.total}")
        if pedido.status == "pendente":
            Notificacao.avisar(cliente, pedido, f"Pedido #{pedido.codigo} confirmado! Pagamento aprovado.")
        db.session.commit()
        return pedido

    def confirmar_pix(self):
        if self.status != "aguardando_pagamento":
            raise RegraNegocioErro("Este pedido não está aguardando pagamento.")
        self.status = "pendente"
        Notificacao.avisar(self.cliente, self, f"Pagamento PIX do pedido #{self.codigo} confirmado.")
        db.session.commit()

    # ---------- mudanças de estado (US09, US13, US14, US17) ----------
    def mudar_status(self, novo, por=None):
        if novo not in self.TRANSICOES.get(self.status, ()):
            raise RegraNegocioErro(f"Não é possível passar de “{self.status_legivel}” para “{self.STATUS.get(novo, novo)}”.")
        if novo == "saiu_para_entrega":
            if self.metodo_entrega != "entrega":
                raise RegraNegocioErro("Pedido de retirada não sai para entrega.")
            if self.entregador is None:
                raise RegraNegocioErro("Atribua um entregador antes de enviar o pedido.")
        if novo == "pronto_retirada" and self.metodo_entrega != "retirada":
            raise RegraNegocioErro("Este pedido é de entrega, não de retirada.")
        if novo == "entregue" and por is not None and por.entregador and self.entregador_id != por.id:
            raise RegraNegocioErro("Este pedido não está atribuído a você.")
        if novo == "cancelado":
            for item in self.itens:  # US12 RN#2: devolve o estoque
                item.cupcake.ajustar_estoque(item.quantidade)
        self.status = novo
        Notificacao.avisar(self.cliente, self, f"Pedido #{self.codigo}: {self.status_legivel}.")
        db.session.commit()

    def atribuir_entregador(self, entregador):
        if self.metodo_entrega != "entrega":
            raise RegraNegocioErro("Pedidos de retirada não precisam de entregador.")
        if self.status not in ("pendente", "em_preparacao"):
            raise RegraNegocioErro("Só é possível atribuir pedidos ainda não enviados.")
        if entregador is None or not entregador.entregador:
            raise RegraNegocioErro("Escolha um entregador válido.")
        ativos = Pedido.query.filter(Pedido.entregador_id == entregador.id,
                                     Pedido.status.in_(cls_ativos_entrega())).count()
        if ativos >= MAX_ENTREGAS_SIMULTANEAS:
            raise RegraNegocioErro(f"{entregador.nome} já tem {ativos} entregas em andamento (máximo {MAX_ENTREGAS_SIMULTANEAS}).")
        self.entregador = entregador
        Notificacao.criar(entregador, self, f"Você recebeu o pedido #{self.codigo} para entregar.")
        db.session.commit()

    @classmethod
    def relatorio(cls, inicio, fim):
        """US15 RN#1: considera apenas pedidos concluídos (entregues)."""
        from ..fuso import limites_utc
        de, ate = limites_utc(inicio, fim)
        pedidos = cls.query.filter(cls.status == "entregue", cls.criado_em >= de, cls.criado_em <= ate).all()
        from .catalogo import mais_vendidos
        return {
            "pedidos": len(pedidos),
            "total": sum((Decimal(p.total) for p in pedidos), Decimal("0")),
            "mais_vendidos": mais_vendidos([p.id for p in pedidos]),
        }


def cls_ativos_entrega():
    return ("pendente", "em_preparacao", "saiu_para_entrega")


class ItemPedido(db.Model):
    __tablename__ = "itens_pedido"

    id = db.Column(db.Integer, primary_key=True)
    pedido_id = db.Column(db.Integer, db.ForeignKey("pedidos.id"), nullable=False)
    cupcake_id = db.Column(db.Integer, db.ForeignKey("cupcakes.id"), nullable=False)
    quantidade = db.Column(db.Integer, nullable=False)
    preco_unitario = db.Column(db.Numeric(8, 2), nullable=False)  # preço congelado no momento da compra

    pedido = db.relationship("Pedido", back_populates="itens")
    cupcake = db.relationship("Cupcake")

    __table_args__ = (db.CheckConstraint("quantidade > 0", name="ck_item_quantidade"),)

    @property
    def subtotal(self):
        return Decimal(self.preco_unitario) * self.quantidade


class Notificacao(db.Model):
    """US09: notificações dentro do app (o push nativo fica para a versão mobile)."""

    __tablename__ = "notificacoes"

    id = db.Column(db.Integer, primary_key=True)
    usuario_id = db.Column(db.Integer, db.ForeignKey("usuarios.id"), nullable=False, index=True)
    pedido_id = db.Column(db.Integer, db.ForeignKey("pedidos.id"))
    mensagem = db.Column(db.String(255), nullable=False)
    lida = db.Column(db.Boolean, nullable=False, default=False)
    criado_em = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)

    usuario = db.relationship("Usuario")

    @classmethod
    def criar(cls, usuario, pedido, mensagem):
        db.session.add(cls(usuario=usuario, pedido_id=pedido.id if pedido else None, mensagem=mensagem))

    @classmethod
    def avisar(cls, cliente, pedido, mensagem):
        """US09 RNF#2: respeita a preferência do cliente."""
        if cliente.notificacoes_ativas:
            cls.criar(cliente, pedido, mensagem)

    @classmethod
    def para_admins(cls, mensagem):
        from .usuario import Usuario
        for admin in Usuario.query.filter_by(papel="admin"):
            cls.criar(admin, None, mensagem)


class RegistroContato(db.Model):
    """US18 RN#1: contatos do entregador com o cliente ficam registrados para auditoria."""

    __tablename__ = "registros_contato"

    id = db.Column(db.Integer, primary_key=True)
    pedido_id = db.Column(db.Integer, db.ForeignKey("pedidos.id"), nullable=False)
    entregador_id = db.Column(db.Integer, db.ForeignKey("usuarios.id"), nullable=False)
    meio = db.Column(db.String(10), nullable=False)  # ligacao | whatsapp
    criado_em = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
