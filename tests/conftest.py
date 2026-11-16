import pytest

from app import create_app
from app.models import Cupcake, Usuario, ZonaEntrega, db
from app.seed import popular_banco

CARTAO_OK = {"numero": "4111 1111 1111 1111", "nome": "CLIENTE TESTE", "validade": "12/39", "cvv": "123"}
CARTAO_RECUSADO = dict(CARTAO_OK, numero="4000 0000 0000 0002")


@pytest.fixture(autouse=True)
def app():
    app = create_app({"TESTING": True, "SQLALCHEMY_DATABASE_URI": "sqlite:///:memory:", "WTF_CSRF": False})
    with app.app_context():
        db.create_all()
        popular_banco("senha123")
        yield app
        db.session.remove()
        db.drop_all()


@pytest.fixture
def client(app):
    return app.test_client()


@pytest.fixture
def cliente(app):
    return Usuario.query.filter_by(papel="cliente").first()


@pytest.fixture
def admin(app):
    return Usuario.query.filter_by(papel="admin").first()


@pytest.fixture
def entregador(app):
    return Usuario.query.filter_by(papel="entregador").first()


@pytest.fixture
def cupcake(app):
    return Cupcake.query.filter_by(nome="Red Velvet").first()


@pytest.fixture
def zona(app):
    return ZonaEntrega.query.filter_by(nome="Centro").first()


def entrar(client, email, senha="senha123"):
    return client.post("/entrar", data={"email": email, "senha": senha})
