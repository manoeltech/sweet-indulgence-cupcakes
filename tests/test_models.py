"""Testes unitários da camada Model (regras de negócio das histórias de usuário)."""
from datetime import date, timedelta
from decimal import Decimal

import pytest

from app.models import Cupcake, Cupom, Notificacao, Pedido, RegraNegocioErro, Usuario, db
from app.pagamento import GatewaySimulado, luhn_valido
from tests.conftest import CARTAO_OK, CARTAO_RECUSADO


def novo_pedido(cliente, cupcake, zona, qtd=2, **kw):
    params = dict(cliente=cliente, carrinho={cupcake.id: qtd}, metodo_entrega="entrega", metodo_pagamento="credito",
                  endereco="Rua A, 10 – Centro", zona_id=zona.id, cartao=CARTAO_OK)
    params.update(kw)
    return Pedido.criar(**params)


# US01 / US02
def test_vitrine_esconde_sem_estoque_e_inativos(cupcake):
    cupcake.estoque = 0
    db.session.commit()
    assert cupcake not in Cupcake.vitrine()


def test_vitrine_filtra_por_categoria_e_busca():
    so_chocolate = Cupcake.vitrine("chocolate")
    assert so_chocolate and all(c.categoria.slug == "chocolate" for c in so_chocolate)
    assert [c.nome for c in Cupcake.vitrine(busca="velvet")] == ["Red Velvet"]


# US11 (CU02-A)
def test_cupcake_invalido_lista_erros():
    erros = Cupcake(nome="", descricao="", preco=Decimal("0"), estoque=-1).validar()
    assert len(erros) == 5


# US06
def test_cupom_valido_calcula_desconto():
    cupom = Cupom.buscar_valido("bemvindo10")
    assert cupom.desconto_sobre(Decimal("50.00")) == Decimal("5.00")


@pytest.mark.parametrize("codigo,mensagem", [("NAOEXISTE", "inválido"), ("VERAO2025", "expirou")])
def test_cupom_invalido_ou_expirado(codigo, mensagem):
    with pytest.raises(RegraNegocioErro, match=mensagem):
        Cupom.buscar_valido(codigo)


def test_cupom_esgotado():
    db.session.add(Cupom(codigo="UNICO", percentual=5, validade=date.today() + timedelta(days=1), limite_usos=1, usos=1))
    db.session.commit()
    with pytest.raises(RegraNegocioErro, match="limite"):
        Cupom.buscar_valido("UNICO")


# US08 – gateway
def test_luhn():
    assert luhn_valido("4111111111111111")
    assert not luhn_valido("4111111111111112")


def test_gateway_recusa_cartao_de_teste_e_vencido():
    g = GatewaySimulado()
    with pytest.raises(RegraNegocioErro, match="recusado"):
        g.cobrar_cartao(CARTAO_RECUSADO, Decimal("10"))
    with pytest.raises(RegraNegocioErro, match="vencido"):
        g.cobrar_cartao(dict(CARTAO_OK, validade="01/20"), Decimal("10"))
    assert g.cobrar_cartao(CARTAO_OK, Decimal("10")).final == "1111"


# CU01 – Realizar pedido
def test_pedido_calcula_totais_e_baixa_estoque(cliente, cupcake, zona):
    estoque_antes = cupcake.estoque
    pedido = novo_pedido(cliente, cupcake, zona, qtd=2, codigo_cupom="BEMVINDO10")
    assert pedido.subtotal == Decimal("23.00")
    assert pedido.desconto == Decimal("2.30")
    assert pedido.frete == Decimal("5.00")
    assert pedido.total == Decimal("25.70")
    assert pedido.status == "pendente"
    assert pedido.cartao_final == "1111"
    assert cupcake.estoque == estoque_antes - 2
    assert Cupom.query.filter_by(codigo="BEMVINDO10").first().usos == 1


def test_pedido_nao_passa_do_estoque(cliente, cupcake, zona):
    with pytest.raises(RegraNegocioErro, match="Só temos"):
        novo_pedido(cliente, cupcake, zona, qtd=cupcake.estoque + 1)


def test_pagamento_recusado_nao_grava_pedido_nem_mexe_no_estoque(cliente, cupcake, zona):
    estoque = cupcake.estoque
    with pytest.raises(RegraNegocioErro, match="recusado"):
        novo_pedido(cliente, cupcake, zona, cartao=CARTAO_RECUSADO)
    db.session.rollback()
    assert Pedido.query.count() == 0
    assert db.session.get(Cupcake, cupcake.id).estoque == estoque


def test_entrega_exige_zona_e_endereco(cliente, cupcake, zona):
    with pytest.raises(RegraNegocioErro, match="zona"):
        novo_pedido(cliente, cupcake, zona, zona_id=None)
    with pytest.raises(RegraNegocioErro, match="endereço"):
        novo_pedido(cliente, cupcake, zona, endereco="  ")


def test_retirada_sem_frete(cliente, cupcake, zona):
    pedido = novo_pedido(cliente, cupcake, zona, metodo_entrega="retirada", zona_id=None, endereco=None)
    assert pedido.frete == 0 and pedido.endereco_entrega is None


def test_pix_aguarda_e_confirma(cliente, cupcake, zona):
    pedido = novo_pedido(cliente, cupcake, zona, metodo_pagamento="pix", cartao=None)
    assert pedido.status == "aguardando_pagamento" and pedido.pix_copia_cola
    pedido.confirmar_pix()
    assert pedido.status == "pendente"


# US09 / US12 / US13 / US14 / US17
def test_fluxo_completo_de_entrega_com_notificacoes(cliente, cupcake, zona, entregador):
    pedido = novo_pedido(cliente, cupcake, zona)
    pedido.mudar_status("em_preparacao")
    with pytest.raises(RegraNegocioErro, match="entregador"):
        pedido.mudar_status("saiu_para_entrega")
    pedido.atribuir_entregador(entregador)
    pedido.mudar_status("saiu_para_entrega")
    pedido.mudar_status("entregue", por=entregador)
    assert pedido.status == "entregue"
    mensagens = [n.mensagem for n in Notificacao.query.filter_by(usuario_id=cliente.id)]
    assert any("Em preparação" in m for m in mensagens)
    assert any("Saiu para entrega" in m for m in mensagens)
    assert any("Entregue" in m for m in mensagens)


def test_cliente_que_desativou_notificacoes_nao_recebe(cliente, cupcake, zona):
    cliente.notificacoes_ativas = False
    pedido = novo_pedido(cliente, cupcake, zona)
    pedido.mudar_status("em_preparacao")
    assert Notificacao.query.filter_by(usuario_id=cliente.id).count() == 0


def test_transicao_invalida(cliente, cupcake, zona):
    pedido = novo_pedido(cliente, cupcake, zona)
    with pytest.raises(RegraNegocioErro):
        pedido.mudar_status("entregue")


def test_cancelar_devolve_estoque(cliente, cupcake, zona):
    estoque = cupcake.estoque
    pedido = novo_pedido(cliente, cupcake, zona, qtd=3)
    pedido.mudar_status("cancelado")
    assert cupcake.estoque == estoque


def test_entregador_tem_limite_de_entregas(cliente, cupcake, zona, entregador):
    for _ in range(3):
        novo_pedido(cliente, cupcake, zona, qtd=1).atribuir_entregador(entregador)
    with pytest.raises(RegraNegocioErro, match="máximo"):
        novo_pedido(cliente, cupcake, zona, qtd=1).atribuir_entregador(entregador)


def test_outro_entregador_nao_conclui(cliente, cupcake, zona, entregador):
    outro = Usuario(nome="Outro", email="outro@x.com", papel="entregador")
    outro.definir_senha("senha123")
    db.session.add(outro)
    pedido = novo_pedido(cliente, cupcake, zona)
    pedido.mudar_status("em_preparacao")
    pedido.atribuir_entregador(entregador)
    pedido.mudar_status("saiu_para_entrega")
    with pytest.raises(RegraNegocioErro, match="não está atribuído"):
        pedido.mudar_status("entregue", por=outro)


# US15
def test_relatorio_conta_apenas_entregues(cliente, cupcake, zona):
    entregue = novo_pedido(cliente, cupcake, zona, metodo_entrega="retirada", zona_id=None, qtd=2)
    entregue.mudar_status("em_preparacao")
    entregue.mudar_status("pronto_retirada")
    entregue.mudar_status("entregue")
    novo_pedido(cliente, cupcake, zona)  # pendente: fora do relatório
    dados = Pedido.relatorio(date.today(), date.today())
    assert dados["pedidos"] == 1
    assert dados["total"] == Decimal("23.00")
    assert dados["mais_vendidos"][0][0] == "Red Velvet"


def test_senha_curta(app):
    with pytest.raises(ValueError):
        Usuario(nome="x", email="x@x.com").definir_senha("123")


def test_horario_e_limites_no_fuso_de_brasilia():
    from datetime import datetime
    from app.fuso import limites_utc, para_local
    assert para_local(datetime(2026, 11, 17, 0, 30)).strftime("%d/%m %H:%M") == "16/11 21:30"
    de, ate = limites_utc(date(2026, 11, 16), date(2026, 11, 16))
    assert de == datetime(2026, 11, 16, 3, 0)
    assert ate.date() == date(2026, 11, 17) and ate.hour == 2
