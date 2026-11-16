"""CONTROLLER do entregador: US16, US17, US18."""
from urllib.parse import quote

from flask import Blueprint, abort, flash, redirect, render_template, request, url_for

from ..models import Pedido, RegistroContato, RegraNegocioErro, db
from .auth import login_obrigatorio, usuario_atual

bp = Blueprint("entregador", __name__, url_prefix="/entregador")


@bp.before_request
@login_obrigatorio("entregador")
def somente_entregador():
    return None


def _minha_entrega(codigo):
    """US16 RN#1: o entregador só vê pedidos dele que já saíram para entrega."""
    pedido = Pedido.query.filter_by(codigo=codigo, entregador_id=usuario_atual().id, status="saiu_para_entrega").first()
    if pedido is None:
        abort(404, "Entrega não encontrada ou já concluída.")
    return pedido


@bp.route("/")
def entregas():
    pedidos = (Pedido.query.filter_by(entregador_id=usuario_atual().id, status="saiu_para_entrega")
               .order_by(Pedido.atualizado_em).all())
    return render_template("entregador/lista.html", pedidos=pedidos)


@bp.route("/<codigo>")
def detalhe(codigo):
    pedido = _minha_entrega(codigo)
    mapa = "https://www.google.com/maps/search/?api=1&query=" + quote(pedido.endereco_entrega or "")
    return render_template("entregador/detalhe.html", pedido=pedido, mapa=mapa)


@bp.post("/<codigo>/contato")
def contato(codigo):
    pedido = _minha_entrega(codigo)
    meio = "whatsapp" if request.form.get("meio") == "whatsapp" else "ligacao"
    db.session.add(RegistroContato(pedido_id=pedido.id, entregador_id=usuario_atual().id, meio=meio))  # US18 RN#1
    db.session.commit()
    telefone = "".join(c for c in (pedido.cliente.telefone or "") if c.isdigit())
    if not telefone:
        flash("O cliente não cadastrou telefone.", "erro")
        return redirect(url_for("entregador.detalhe", codigo=codigo))
    if meio == "whatsapp":
        return redirect(f"https://wa.me/55{telefone}?text=" + quote(f"Olá! Sou o entregador da Sweet Indulgence com o pedido #{pedido.codigo}."))
    return redirect(f"tel:+55{telefone}")


@bp.post("/<codigo>/entregue")
def marcar_entregue(codigo):
    pedido = _minha_entrega(codigo)
    if request.form.get("confirmado") != "1":
        flash("Confirme com o cliente antes de marcar como entregue.", "erro")
        return redirect(url_for("entregador.detalhe", codigo=codigo))
    try:
        pedido.mudar_status("entregue", por=usuario_atual())
        flash(f"Pedido #{pedido.codigo} entregue!", "sucesso")
    except RegraNegocioErro as e:
        db.session.rollback()
        flash(str(e), "erro")
    return redirect(url_for("entregador.entregas"))
