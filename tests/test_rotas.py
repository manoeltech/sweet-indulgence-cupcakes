"""Testes de integração: front-end (HTML) + back-end (controllers) + banco."""
from app import create_app
from app.models import Avaliacao, Cupcake, Favorito, Pedido, RegistroContato, Usuario, db
from app.seed import popular_banco
from tests.conftest import entrar


def checkout(client, zona, **extra):
    dados = {"metodo_entrega": "entrega", "zona_id": zona.id, "endereco": "Rua B, 20 – Centro",
             "metodo_pagamento": "credito", "cartao_numero": "4111111111111111", "cartao_nome": "TESTE",
             "cartao_validade": "12/39", "cartao_cvv": "123"}
    dados.update(extra)
    return client.post("/checkout", data=dados)


def test_vitrine_mostra_produtos_e_filtro(client):
    html = client.get("/").get_data(as_text=True)
    assert "Red Velvet" in html and "Brigadeiro Gourmet" in html
    html = client.get("/?categoria=frutas").get_data(as_text=True)
    assert "Morango com Chantilly" in html and "Red Velvet" not in html


def test_detalhe_mostra_nutricional_e_alergenos(client, cupcake):
    html = client.get(f"/cupcake/{cupcake.id}").get_data(as_text=True)
    assert "Informação nutricional" in html and "Lactose" in html and "330 kcal" in html


def test_imagem_svg(client, cupcake):
    resp = client.get(f"/cupcake/{cupcake.id}/imagem.svg")
    assert resp.status_code == 200 and resp.mimetype == "image/svg+xml"


def test_produto_inexistente_404(client):
    assert client.get("/cupcake/9999").status_code == 404


def test_cadastro_valida_e_cria_conta(client):
    resp = client.post("/cadastro", data={"nome": "Ana", "email": "ana@", "senha": "123", "confirmacao": "321"})
    html = resp.get_data(as_text=True)
    assert resp.status_code == 422 and "e-mail válido" in html and "não conferem" in html
    resp = client.post("/cadastro", data={"nome": "Ana", "email": "ana@ex.com", "senha": "segredo1", "confirmacao": "segredo1"})
    assert resp.status_code == 302 and Usuario.query.filter_by(email="ana@ex.com").first()


def test_login_errado(client):
    resp = entrar(client, "cliente@sweetindulgence.com", "errada")
    assert resp.status_code == 401


def test_carrinho_adicionar_alterar_remover(client, cupcake):
    client.post(f"/carrinho/adicionar/{cupcake.id}", data={"quantidade": 2})
    assert "R$ 23,00" in client.get("/carrinho/").get_data(as_text=True)
    client.post(f"/carrinho/atualizar/{cupcake.id}", data={"acao": "mais"})
    assert "R$ 34,50" in client.get("/carrinho/").get_data(as_text=True)
    client.post(f"/carrinho/atualizar/{cupcake.id}", data={"acao": "remover"})
    assert "carrinho está vazio" in client.get("/carrinho/").get_data(as_text=True)


def test_carrinho_respeita_estoque(client):
    caramelo = Cupcake.query.filter_by(nome="Caramelo Salgado").first()  # estoque 4
    resp = client.post(f"/carrinho/adicionar/{caramelo.id}", data={"quantidade": 10}, follow_redirects=True)
    assert "Só temos 4" in resp.get_data(as_text=True)


def test_cupom_invalido_mostra_mensagem(client, cupcake):
    client.post(f"/carrinho/adicionar/{cupcake.id}")
    html = client.post("/carrinho/cupom", data={"codigo": "VERAO2025"}, follow_redirects=True).get_data(as_text=True)
    assert "expirou" in html


def test_checkout_exige_login(client, cupcake):
    client.post(f"/carrinho/adicionar/{cupcake.id}")
    resp = client.get("/checkout")
    assert resp.status_code == 302 and "/entrar" in resp.headers["Location"]


def test_compra_completa_pelo_site(client, cupcake, zona):
    client.post(f"/carrinho/adicionar/{cupcake.id}", data={"quantidade": 2})
    entrar(client, "cliente@sweetindulgence.com")  # carrinho do visitante continua após o login
    client.post("/carrinho/cupom", data={"codigo": "bemvindo10"})
    resp = checkout(client, zona)
    assert resp.status_code == 302
    pedido = Pedido.query.one()
    assert pedido.total == pedido.subtotal - pedido.desconto + pedido.frete
    html = client.get(resp.headers["Location"]).get_data(as_text=True)
    assert f"Pedido #{pedido.codigo} confirmado" in html
    assert "carrinho está vazio" in client.get("/carrinho/").get_data(as_text=True)


def test_cupom_aplicado_antes_do_login_continua_depois(client, cupcake):
    client.post(f"/carrinho/adicionar/{cupcake.id}")
    client.post("/carrinho/cupom", data={"codigo": "BEMVINDO10"})
    entrar(client, "cliente@sweetindulgence.com")
    assert "Cupom BEMVINDO10" in client.get("/checkout").get_data(as_text=True)


def test_cartao_recusado_volta_ao_checkout(client, cupcake, zona):
    entrar(client, "cliente@sweetindulgence.com")
    client.post(f"/carrinho/adicionar/{cupcake.id}")
    resp = checkout(client, zona, cartao_numero="4000000000000002")
    assert resp.status_code == 422 and "recusado" in resp.get_data(as_text=True)
    assert Pedido.query.count() == 0


def test_favoritos(client, cupcake):
    entrar(client, "cliente@sweetindulgence.com")
    client.post(f"/cupcake/{cupcake.id}/favorito")
    assert "Red Velvet" in client.get("/favoritos").get_data(as_text=True)
    client.post(f"/cupcake/{cupcake.id}/favorito")
    assert Favorito.query.count() == 0


def test_area_admin_bloqueada_para_cliente(client):
    entrar(client, "cliente@sweetindulgence.com")
    assert client.get("/admin/").status_code == 403


def test_admin_crud_produto(client):
    entrar(client, "admin@sweetindulgence.com")
    resp = client.post("/admin/produtos/novo", data={"nome": "", "preco": "abc", "categoria_id": ""})
    assert resp.status_code == 422 and "Informe o nome" in resp.get_data(as_text=True)
    cat = Cupcake.query.first().categoria_id
    client.post("/admin/produtos/novo", data={"nome": "Pistache", "descricao": "Novo", "preco": "13,50",
                                              "estoque": "10", "categoria_id": cat, "alergenos": "Oleaginosas"})
    novo = Cupcake.query.filter_by(nome="Pistache").one()
    assert str(novo.preco) == "13.50"
    client.post(f"/admin/produtos/{novo.id}/remover", data={"confirmacao": "errado"})
    assert db.session.get(Cupcake, novo.id).ativo  # CU02-B: sem confirmação não remove
    client.post(f"/admin/produtos/{novo.id}/remover", data={"confirmacao": "Pistache"})
    assert not db.session.get(Cupcake, novo.id).ativo


def test_fluxo_admin_entregador_avaliacao(client, cupcake, zona):
    entrar(client, "cliente@sweetindulgence.com")
    client.post(f"/carrinho/adicionar/{cupcake.id}")
    checkout(client, zona)
    pedido = Pedido.query.one()
    entregador = Usuario.query.filter_by(papel="entregador").one()

    entrar(client, "admin@sweetindulgence.com")
    client.post(f"/admin/pedido/{pedido.id}/status", data={"status": "em_preparacao"})
    client.post(f"/admin/pedido/{pedido.id}/entregador", data={"entregador_id": entregador.id})
    client.post(f"/admin/pedido/{pedido.id}/status", data={"status": "saiu_para_entrega"})

    entrar(client, "entregador@sweetindulgence.com")
    assert pedido.codigo in client.get("/entregador/").get_data(as_text=True)
    resp = client.post(f"/entregador/{pedido.codigo}/contato", data={"meio": "whatsapp"})
    assert resp.headers["Location"].startswith("https://wa.me/55")
    assert RegistroContato.query.count() == 1
    client.post(f"/entregador/{pedido.codigo}/entregue", data={"confirmado": "1"})
    assert db.session.get(Pedido, pedido.id).status == "entregue"

    entrar(client, "cliente@sweetindulgence.com")
    client.post(f"/pedido/{pedido.codigo}/avaliar/{cupcake.id}", data={"nota": 5, "nota_entrega": 4, "comentario": "Ótimo"})
    assert Avaliacao.query.one().nota == 5


def test_cliente_nao_ve_pedido_de_outro(client, cupcake, zona):
    entrar(client, "cliente@sweetindulgence.com")
    client.post(f"/carrinho/adicionar/{cupcake.id}")
    checkout(client, zona)
    codigo = Pedido.query.one().codigo
    client.post("/cadastro", data={"nome": "Bia", "email": "bia@ex.com", "senha": "segredo1", "confirmacao": "segredo1"})
    assert client.get(f"/pedido/{codigo}").status_code == 404


def test_relatorio_csv(client):
    entrar(client, "admin@sweetindulgence.com")
    resp = client.get("/admin/relatorios?formato=csv")
    assert resp.mimetype == "text/csv" and "Relatório de vendas" in resp.get_data(as_text=True)


def test_csrf_bloqueia_post_sem_token():
    app = create_app({"TESTING": True, "SQLALCHEMY_DATABASE_URI": "sqlite:///:memory:"})
    with app.app_context():
        db.create_all()
        popular_banco("senha123")
        resp = app.test_client().post("/entrar", data={"email": "a", "senha": "b"})
        assert resp.status_code == 400
        db.drop_all()
