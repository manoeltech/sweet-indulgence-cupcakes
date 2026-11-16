"""Camada MODEL do padrão MVC: entidades e regras de negócio."""
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

from .usuario import Usuario, Endereco  # noqa: E402,F401
from .catalogo import Categoria, Cupcake, Favorito, Avaliacao  # noqa: E402,F401
from .pedido import Cupom, Pedido, ItemPedido, Notificacao, ZonaEntrega, RegistroContato, RegraNegocioErro  # noqa: E402,F401
