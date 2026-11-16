"""CONTROLLER do carrinho (US04). O carrinho fica na sessão: {id_do_cupcake: quantidade}."""
from decimal import Decimal

from flask import Blueprint, abort, flash, redirect, render_template, request, session, url_for

from ..models import Cupcake, Cupom, RegraNegocioErro, db

bp = Blueprint("carrinho", __name__, url_prefix="/carrinho")


def carrinho_da_sessao():
    return {int(k): v for k, v in session.get("carrinho", {}).items()}


def salvar(carrinho):
    session["carrinho"] = {str(k): v for k, v in carrinho.items() if v > 0}


def resumo(carrinho, codigo_cupom=None):
    itens, subtotal = [], Decimal("0")
    for cupcake_id, quantidade in carrinho.items():
        cupcake = db.session.get(Cupcake, cupcake_id)
        if cupcake is None or not cupcake.ativo:
            continue
        valor = Decimal(cupcake.preco) * quantidade
        itens.append({"cupcake": cupcake, "quantidade": quantidade, "subtotal": valor})
        subtotal += valor
    cupom, erro_cupom, desconto = None, None, Decimal("0")
    try:
        cupom = Cupom.buscar_valido(codigo_cupom)
        if cupom:
            desconto = cupom.desconto_sobre(subtotal)
    except RegraNegocioErro as e:
        erro_cupom = str(e)
    return {"itens": itens, "subtotal": subtotal, "cupom": cupom, "erro_cupom": erro_cupom,
            "desconto": desconto, "total": subtotal - desconto}


@bp.route("/")
def ver():
    return render_template("loja/carrinho.html", r=resumo(carrinho_da_sessao(), session.get("cupom")))


@bp.post("/adicionar/<int:cupcake_id>")
def adicionar(cupcake_id):
    cupcake = db.session.get(Cupcake, cupcake_id)
    if cupcake is None or not cupcake.ativo:
        abort(404)
    try:
        quantidade = max(1, int(request.form.get("quantidade", 1)))
    except ValueError:
        quantidade = 1
    carrinho = carrinho_da_sessao()
    nova = carrinho.get(cupcake_id, 0) + quantidade
    if nova > cupcake.estoque:  # US04 RNF#1
        flash(f"Só temos {cupcake.estoque} unidade(s) de {cupcake.nome} em estoque.", "erro")
        return redirect(request.referrer or url_for("loja.detalhe", cupcake_id=cupcake_id))
    carrinho[cupcake_id] = nova
    salvar(carrinho)
    flash(f"{cupcake.nome} adicionado ao carrinho.", "sucesso")
    return redirect(url_for("carrinho.ver"))


@bp.post("/atualizar/<int:cupcake_id>")
def atualizar(cupcake_id):
    carrinho = carrinho_da_sessao()
    cupcake = db.session.get(Cupcake, cupcake_id)
    if cupcake_id not in carrinho or cupcake is None:
        return redirect(url_for("carrinho.ver"))
    acao = request.form.get("acao")
    quantidade = carrinho[cupcake_id] + (1 if acao == "mais" else -1 if acao == "menos" else 0)
    if acao == "remover" or quantidade <= 0:
        carrinho.pop(cupcake_id)
        flash(f"{cupcake.nome} removido do carrinho.", "sucesso")
    elif quantidade > cupcake.estoque:
        flash(f"Só temos {cupcake.estoque} unidade(s) de {cupcake.nome}.", "erro")
    else:
        carrinho[cupcake_id] = quantidade
    salvar(carrinho)
    return redirect(url_for("carrinho.ver"))


@bp.post("/cupom")
def aplicar_cupom():
    codigo = request.form.get("codigo", "").strip().upper()
    if request.form.get("acao") == "remover" or not codigo:
        session.pop("cupom", None)
        return redirect(url_for("carrinho.ver"))
    try:
        Cupom.buscar_valido(codigo)
        session["cupom"] = codigo  # US06 RN#2: guarda só um cupom
        flash(f"Cupom {codigo} aplicado!", "sucesso")
    except RegraNegocioErro as e:
        session.pop("cupom", None)
        flash(str(e), "erro")
    return redirect(url_for("carrinho.ver"))
