from datetime import datetime

from werkzeug.security import check_password_hash, generate_password_hash

from . import db


class Usuario(db.Model):
    """Cliente, Administrador e Entregador do diagrama de classes do PIT I.

    Revisão do PIT II: as três classes tinham os mesmos atributos (nome, e-mail),
    então viraram uma única tabela com o campo `papel`, evitando três logins diferentes.
    """

    __tablename__ = "usuarios"

    PAPEIS = ("cliente", "admin", "entregador")

    id = db.Column(db.Integer, primary_key=True)
    nome = db.Column(db.String(120), nullable=False)
    email = db.Column(db.String(160), nullable=False, unique=True, index=True)
    telefone = db.Column(db.String(20))
    senha_hash = db.Column(db.String(255), nullable=False)
    papel = db.Column(db.String(20), nullable=False, default="cliente")
    notificacoes_ativas = db.Column(db.Boolean, nullable=False, default=True)
    criado_em = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)

    enderecos = db.relationship("Endereco", back_populates="usuario", cascade="all, delete-orphan")
    pedidos = db.relationship("Pedido", back_populates="cliente", foreign_keys="Pedido.cliente_id")
    entregas = db.relationship("Pedido", back_populates="entregador", foreign_keys="Pedido.entregador_id")
    favoritos = db.relationship("Favorito", back_populates="usuario", cascade="all, delete-orphan")

    def definir_senha(self, senha):
        if not senha or len(senha) < 6:
            raise ValueError("A senha precisa ter pelo menos 6 caracteres.")
        self.senha_hash = generate_password_hash(senha)

    def confere_senha(self, senha):
        return check_password_hash(self.senha_hash, senha or "")

    @property
    def admin(self):
        return self.papel == "admin"

    @property
    def entregador(self):
        return self.papel == "entregador"

    def favoritou(self, cupcake):
        return any(f.cupcake_id == cupcake.id for f in self.favoritos)

    def ja_comprou(self, cupcake):
        """RN do US10: só avalia quem comprou (pedido entregue)."""
        return any(
            item.cupcake_id == cupcake.id
            for pedido in self.pedidos if pedido.status == "entregue"
            for item in pedido.itens
        )


class Endereco(db.Model):
    __tablename__ = "enderecos"

    id = db.Column(db.Integer, primary_key=True)
    usuario_id = db.Column(db.Integer, db.ForeignKey("usuarios.id"), nullable=False)
    rua = db.Column(db.String(160), nullable=False)
    numero = db.Column(db.String(10), nullable=False)
    bairro = db.Column(db.String(80), nullable=False)
    cep = db.Column(db.String(9), nullable=False)

    usuario = db.relationship("Usuario", back_populates="enderecos")

    def __str__(self):
        return f"{self.rua}, {self.numero} – {self.bairro}, CEP {self.cep}"
