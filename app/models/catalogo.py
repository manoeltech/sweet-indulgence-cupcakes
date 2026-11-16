from datetime import datetime
from decimal import Decimal

from sqlalchemy import func

from . import db


class Categoria(db.Model):
    __tablename__ = "categorias"

    id = db.Column(db.Integer, primary_key=True)
    nome = db.Column(db.String(60), nullable=False, unique=True)
    slug = db.Column(db.String(60), nullable=False, unique=True)

    cupcakes = db.relationship("Cupcake", back_populates="categoria")


class Cupcake(db.Model):
    __tablename__ = "cupcakes"

    id = db.Column(db.Integer, primary_key=True)
    categoria_id = db.Column(db.Integer, db.ForeignKey("categorias.id"), nullable=False)
    nome = db.Column(db.String(80), nullable=False)
    descricao = db.Column(db.Text, nullable=False)
    ingredientes = db.Column(db.Text, nullable=False, default="")
    preco = db.Column(db.Numeric(8, 2), nullable=False)
    estoque = db.Column(db.Integer, nullable=False, default=0)
    estoque_minimo = db.Column(db.Integer, nullable=False, default=5)
    calorias = db.Column(db.Integer)
    gorduras_g = db.Column(db.Numeric(5, 1))
    acucares_g = db.Column(db.Numeric(5, 1))
    alergenos = db.Column(db.String(200), nullable=False, default="")
    cor = db.Column(db.String(7), nullable=False, default="#f9a8d4")  # cor da cobertura na ilustração
    ativo = db.Column(db.Boolean, nullable=False, default=True)
    criado_em = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)

    categoria = db.relationship("Categoria", back_populates="cupcakes")
    avaliacoes = db.relationship("Avaliacao", back_populates="cupcake", cascade="all, delete-orphan")

    __table_args__ = (
        db.CheckConstraint("preco > 0", name="ck_cupcake_preco_positivo"),
        db.CheckConstraint("estoque >= 0", name="ck_cupcake_estoque_nao_negativo"),
    )

    @classmethod
    def vitrine(cls, categoria_slug=None, busca=None):
        """US01 RN#1: só aparecem cupcakes ativos e com estoque. US02: filtro por categoria."""
        consulta = cls.query.filter(cls.ativo.is_(True), cls.estoque > 0)
        if categoria_slug:
            consulta = consulta.join(Categoria).filter(Categoria.slug == categoria_slug)
        if busca:
            consulta = consulta.filter(cls.nome.ilike(f"%{busca}%"))
        return consulta.order_by(cls.nome).all()

    @classmethod
    def estoque_baixo(cls):
        """US12 CA#3: alerta de estoque baixo para o administrador."""
        return cls.query.filter(cls.ativo.is_(True), cls.estoque <= cls.estoque_minimo).order_by(cls.estoque).all()

    @property
    def lista_alergenos(self):
        return [a.strip() for a in self.alergenos.split(",") if a.strip()]

    @property
    def nota_media(self):
        if not self.avaliacoes:
            return None
        return round(sum(a.nota for a in self.avaliacoes) / len(self.avaliacoes), 1)

    def validar(self):
        erros = []
        if not (self.nome or "").strip():
            erros.append("Informe o nome do cupcake.")
        if not (self.descricao or "").strip():
            erros.append("Informe a descrição.")
        if self.preco is None or Decimal(self.preco) <= 0:
            erros.append("O preço precisa ser maior que zero.")
        if self.estoque is None or int(self.estoque) < 0:
            erros.append("O estoque não pode ser negativo.")
        if not self.categoria_id:
            erros.append("Escolha uma categoria.")
        return erros

    def ajustar_estoque(self, delta):
        novo = self.estoque + delta
        if novo < 0:
            raise ValueError(f"Estoque insuficiente de {self.nome}.")
        self.estoque = novo


class Favorito(db.Model):
    __tablename__ = "favoritos"

    usuario_id = db.Column(db.Integer, db.ForeignKey("usuarios.id"), primary_key=True)
    cupcake_id = db.Column(db.Integer, db.ForeignKey("cupcakes.id"), primary_key=True)
    criado_em = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)

    usuario = db.relationship("Usuario", back_populates="favoritos")
    cupcake = db.relationship("Cupcake")


class Avaliacao(db.Model):
    __tablename__ = "avaliacoes"

    id = db.Column(db.Integer, primary_key=True)
    usuario_id = db.Column(db.Integer, db.ForeignKey("usuarios.id"), nullable=False)
    cupcake_id = db.Column(db.Integer, db.ForeignKey("cupcakes.id"), nullable=False)
    pedido_id = db.Column(db.Integer, db.ForeignKey("pedidos.id"), nullable=False)
    nota = db.Column(db.Integer, nullable=False)
    nota_entrega = db.Column(db.Integer, nullable=False)
    comentario = db.Column(db.Text, nullable=False, default="")
    criado_em = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)

    usuario = db.relationship("Usuario")
    cupcake = db.relationship("Cupcake", back_populates="avaliacoes")

    __table_args__ = (
        db.UniqueConstraint("usuario_id", "pedido_id", "cupcake_id", name="uq_avaliacao_por_item"),
        db.CheckConstraint("nota BETWEEN 1 AND 5", name="ck_avaliacao_nota"),
        db.CheckConstraint("nota_entrega BETWEEN 1 AND 5", name="ck_avaliacao_nota_entrega"),
    )


def mais_vendidos(pedidos_ids):
    from .pedido import ItemPedido
    if not pedidos_ids:
        return []
    return (
        db.session.query(Cupcake.nome, func.sum(ItemPedido.quantidade).label("qtd"),
                         func.sum(ItemPedido.quantidade * ItemPedido.preco_unitario).label("valor"))
        .join(ItemPedido, ItemPedido.cupcake_id == Cupcake.id)
        .filter(ItemPedido.pedido_id.in_(pedidos_ids))
        .group_by(Cupcake.nome)
        .order_by(func.sum(ItemPedido.quantidade).desc())
        .all()
    )
