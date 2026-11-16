"""CONTROLLER da vitrine: US01, US02, US03, US05."""
from flask import Blueprint, Response, abort, flash, redirect, render_template, request, url_for

from ..models import Categoria, Cupcake, Favorito, db
from .auth import _destino_seguro, login_obrigatorio, usuario_atual

bp = Blueprint("loja", __name__)


@bp.route("/")
def vitrine():
    categoria = request.args.get("categoria") or None
    busca = (request.args.get("q") or "").strip() or None
    return render_template(
        "loja/vitrine.html",
        cupcakes=Cupcake.vitrine(categoria, busca),
        categorias=Categoria.query.order_by(Categoria.nome).all(),
        categoria_atual=categoria,
        busca=busca or "",
    )


@bp.route("/cupcake/<int:cupcake_id>")
def detalhe(cupcake_id):
    cupcake = db.session.get(Cupcake, cupcake_id)
    if cupcake is None or not cupcake.ativo:
        abort(404, "Este cupcake não existe ou saiu do cardápio.")
    return render_template("loja/detalhe.html", cupcake=cupcake)


@bp.route("/cupcake/<int:cupcake_id>/imagem.svg")
def imagem(cupcake_id):
    """Ilustração vetorial gerada a partir da cor da cobertura (leve no 4G — US01 RNF#1)."""
    cupcake = db.session.get(Cupcake, cupcake_id) or abort(404)
    svg = render_template("loja/cupcake.svg", cor=cupcake.cor)
    return Response(svg, mimetype="image/svg+xml", headers={"Cache-Control": "public, max-age=86400"})


@bp.route("/favoritos")
@login_obrigatorio()
def favoritos():
    usuario = usuario_atual()
    return render_template("loja/favoritos.html", favoritos=usuario.favoritos)


@bp.post("/cupcake/<int:cupcake_id>/favorito")
@login_obrigatorio()
def alternar_favorito(cupcake_id):
    usuario = usuario_atual()
    cupcake = db.session.get(Cupcake, cupcake_id) or abort(404)
    existente = db.session.get(Favorito, (usuario.id, cupcake.id))
    if existente:
        db.session.delete(existente)
        flash(f"{cupcake.nome} saiu dos favoritos.", "sucesso")
    else:
        db.session.add(Favorito(usuario=usuario, cupcake=cupcake))
        flash(f"{cupcake.nome} foi para os favoritos.", "sucesso")
    db.session.commit()
    return redirect(_destino_seguro(request.form.get("voltar")) or url_for("loja.detalhe", cupcake_id=cupcake.id))
