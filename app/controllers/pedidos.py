"""CONTROLLER de checkout e pedidos do cliente: US06, US07, US08, US09, US10."""
from flask import Blueprint, abort, flash, redirect, render_template, request, session, url_for

from ..models import Avaliacao, Pedido, RegraNegocioErro, ZonaEntrega, db
from ..models.pedido import TEMPO_RETIRADA_MIN
from .auth import login_obrigatorio, usuario_atual
from .carrinho import carrinho_da_sessao, resumo

bp = Blueprint("pedidos", __name__)


def _meu_pedido(codigo):
    pedido = Pedido.query.filter_by(codigo=codigo).first()
    if pedido is None or pedido.cliente_id != usuario_atual().id:
        abort(404, "Pedido não encontrado.")
    return pedido


@bp.route("/checkout", methods=["GET", "POST"])
@login_obrigatorio()
def checkout():
    usuario = usuario_atual()
    carrinho = carrinho_da_sessao()
    if not carrinho:
        flash("Seu carrinho está vazio.", "aviso")
        return redirect(url_for("loja.vitrine"))
    zonas = ZonaEntrega.query.order_by(ZonaEntrega.taxa).all()
    r = resumo(carrinho, session.get("cupom"))

    if request.method == "POST":
        f = request.form
        endereco = f.get("endereco", "").strip()
        if f.get("endereco_salvo"):
            salvo = next((e for e in usuario.enderecos if str(e.id) == f.get("endereco_salvo")), None)
            endereco = str(salvo) if salvo else endereco
        try:
            pedido = Pedido.criar(
                cliente=usuario,
                carrinho=carrinho,
                metodo_entrega=f.get("metodo_entrega"),
                metodo_pagamento=f.get("metodo_pagamento"),
                endereco=endereco,
                zona_id=f.get("zona_id") or None,
                codigo_cupom=session.get("cupom"),
                cartao={k: f.get(f"cartao_{k}", "") for k in ("numero", "nome", "validade", "cvv")},
            )
        except RegraNegocioErro as e:  # CU01-A (cupom) e CU01-B (pagamento recusado)
            db.session.rollback()
            flash(str(e), "erro")
            return render_template("loja/checkout.html", r=r, zonas=zonas, dados=f,
                                   tempo_retirada=TEMPO_RETIRADA_MIN), 422
        session.pop("carrinho", None)
        session.pop("cupom", None)
        return redirect(url_for("pedidos.confirmacao", codigo=pedido.codigo))

    return render_template("loja/checkout.html", r=r, zonas=zonas, dados={}, tempo_retirada=TEMPO_RETIRADA_MIN)


@bp.route("/pedido/<codigo>/confirmacao")
@login_obrigatorio()
def confirmacao(codigo):
    return render_template("pedidos/confirmacao.html", pedido=_meu_pedido(codigo), tempo_retirada=TEMPO_RETIRADA_MIN)


@bp.post("/pedido/<codigo>/pix")
@login_obrigatorio()
def confirmar_pix(codigo):
    pedido = _meu_pedido(codigo)
    try:
        pedido.confirmar_pix()
        flash("Pagamento PIX confirmado!", "sucesso")
    except RegraNegocioErro as e:
        flash(str(e), "erro")
    return redirect(url_for("pedidos.acompanhar", codigo=codigo))


@bp.route("/meus-pedidos")
@login_obrigatorio()
def meus_pedidos():
    pedidos = Pedido.query.filter_by(cliente_id=usuario_atual().id).order_by(Pedido.criado_em.desc()).all()
    return render_template("pedidos/lista.html", pedidos=pedidos)


@bp.route("/pedido/<codigo>")
@login_obrigatorio()
def acompanhar(codigo):
    pedido = _meu_pedido(codigo)
    avaliados = {a.cupcake_id for a in Avaliacao.query.filter_by(pedido_id=pedido.id)}
    return render_template("pedidos/acompanhar.html", pedido=pedido, avaliados=avaliados,
                           tempo_retirada=TEMPO_RETIRADA_MIN)


@bp.post("/pedido/<codigo>/avaliar/<int:cupcake_id>")
@login_obrigatorio()
def avaliar(codigo, cupcake_id):
    pedido = _meu_pedido(codigo)
    if pedido.status != "entregue":  # US10 RN#1
        flash("Você poderá avaliar depois que o pedido for entregue.", "erro")
        return redirect(url_for("pedidos.acompanhar", codigo=codigo))
    if cupcake_id not in {i.cupcake_id for i in pedido.itens}:
        abort(404)
    try:
        nota, nota_entrega = int(request.form.get("nota", 0)), int(request.form.get("nota_entrega", 0))
    except ValueError:
        nota = nota_entrega = 0
    if not (1 <= nota <= 5 and 1 <= nota_entrega <= 5):
        flash("Dê uma nota de 1 a 5 estrelas para o cupcake e para a entrega.", "erro")
        return redirect(url_for("pedidos.acompanhar", codigo=codigo))
    if Avaliacao.query.filter_by(pedido_id=pedido.id, cupcake_id=cupcake_id).first():
        flash("Você já avaliou este item.", "aviso")
        return redirect(url_for("pedidos.acompanhar", codigo=codigo))
    db.session.add(Avaliacao(usuario_id=pedido.cliente_id, pedido_id=pedido.id, cupcake_id=cupcake_id,
                             nota=nota, nota_entrega=nota_entrega,
                             comentario=request.form.get("comentario", "").strip()[:1000]))
    db.session.commit()
    flash("Obrigado pela avaliação!", "sucesso")
    return redirect(url_for("pedidos.acompanhar", codigo=codigo))
