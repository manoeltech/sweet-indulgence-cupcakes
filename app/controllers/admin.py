"""CONTROLLER do administrador: US11, US12, US13, US14, US15 e cupons (US06)."""
import csv
import io
from datetime import date, timedelta
from decimal import Decimal, InvalidOperation

from flask import Blueprint, Response, abort, flash, redirect, render_template, request, url_for

from ..fuso import hoje_local, limites_utc
from ..models import Avaliacao, Categoria, Cupcake, Cupom, Pedido, RegraNegocioErro, Usuario, db
from .auth import login_obrigatorio

bp = Blueprint("admin", __name__, url_prefix="/admin")


@bp.before_request
@login_obrigatorio("admin")
def somente_admin():
    return None


@bp.route("/")
def dashboard():
    """US13: pedidos por estado; por padrão só os ativos (RN#1)."""
    filtro = request.args.get("status") or "ativos"
    consulta = Pedido.query
    if filtro == "ativos":
        consulta = consulta.filter(Pedido.status.in_(Pedido.ATIVOS))
    elif filtro in Pedido.STATUS:
        consulta = consulta.filter_by(status=filtro)
    pedidos = consulta.order_by(Pedido.criado_em.desc()).limit(100).all()
    contagem = {s: Pedido.query.filter_by(status=s).count() for s in Pedido.STATUS}
    de, ate = limites_utc(hoje_local(), hoje_local())
    vendas_hoje = sum((Decimal(p.total) for p in Pedido.query.filter(
        Pedido.criado_em.between(de, ate), Pedido.status.notin_(("cancelado", "aguardando_pagamento")))), Decimal("0"))
    return render_template("admin/dashboard.html", pedidos=pedidos, filtro=filtro, contagem=contagem,
                           vendas_hoje=vendas_hoje, estoque_baixo=Cupcake.estoque_baixo(),
                           entregadores=Usuario.query.filter_by(papel="entregador").order_by(Usuario.nome).all())


@bp.post("/pedido/<int:pedido_id>/status")
def mudar_status(pedido_id):
    pedido = db.session.get(Pedido, pedido_id) or abort(404)
    try:
        pedido.mudar_status(request.form.get("status"))
        flash(f"Pedido #{pedido.codigo}: {pedido.status_legivel}.", "sucesso")
    except RegraNegocioErro as e:
        db.session.rollback()
        flash(str(e), "erro")
    return redirect(request.form.get("voltar") if (request.form.get("voltar") or "").startswith("/admin") else url_for("admin.dashboard"))


@bp.post("/pedido/<int:pedido_id>/entregador")
def atribuir(pedido_id):
    pedido = db.session.get(Pedido, pedido_id) or abort(404)
    entregador = db.session.get(Usuario, int(request.form.get("entregador_id") or 0))
    try:
        pedido.atribuir_entregador(entregador)
        flash(f"Pedido #{pedido.codigo} atribuído a {entregador.nome}.", "sucesso")
    except RegraNegocioErro as e:
        db.session.rollback()
        flash(str(e), "erro")
    return redirect(url_for("admin.dashboard"))


# ---------------- Catálogo (US11) e estoque (US12) ----------------
@bp.route("/produtos")
def produtos():
    return render_template("admin/produtos.html", cupcakes=Cupcake.query.order_by(Cupcake.ativo.desc(), Cupcake.nome).all())


def _preencher(cupcake, f):
    cupcake.nome = f.get("nome", "").strip()
    cupcake.descricao = f.get("descricao", "").strip()
    cupcake.ingredientes = f.get("ingredientes", "").strip()
    cupcake.alergenos = f.get("alergenos", "").strip()
    cupcake.categoria_id = int(f.get("categoria_id") or 0) or None
    cupcake.cor = f.get("cor") or "#f9a8d4"
    erros = []
    try:
        cupcake.preco = Decimal(f.get("preco", "").replace(",", "."))
    except InvalidOperation:
        cupcake.preco = None
    for campo, tipo in (("estoque", int), ("estoque_minimo", int), ("calorias", int)):
        valor = f.get(campo, "").strip()
        try:
            setattr(cupcake, campo, tipo(valor) if valor else (0 if campo != "calorias" else None))
        except ValueError:
            erros.append(f"O campo {campo.replace('_', ' ')} precisa ser um número inteiro.")
    for campo in ("gorduras_g", "acucares_g"):
        valor = f.get(campo, "").strip().replace(",", ".")
        try:
            setattr(cupcake, campo, Decimal(valor) if valor else None)
        except InvalidOperation:
            erros.append("Informações nutricionais precisam ser números.")
    return erros + cupcake.validar()


@bp.route("/produtos/novo", methods=["GET", "POST"])
@bp.route("/produtos/<int:cupcake_id>", methods=["GET", "POST"])
def produto(cupcake_id=None):
    cupcake = db.session.get(Cupcake, cupcake_id) if cupcake_id else Cupcake()
    if cupcake is None:
        abort(404)
    categorias = Categoria.query.order_by(Categoria.nome).all()
    if request.method == "POST":
        erros = _preencher(cupcake, request.form)
        if erros:  # CU02-A: dados inválidos — mostra o formulário com o que foi digitado, sem gravar
            for erro in erros:
                flash(erro, "erro")
            with db.session.no_autoflush:
                html = render_template("admin/produto_form.html", cupcake=cupcake, categorias=categorias)
            db.session.rollback()
            return html, 422
        db.session.add(cupcake)
        db.session.commit()
        flash(f"{cupcake.nome} salvo.", "sucesso")
        return redirect(url_for("admin.produtos"))
    return render_template("admin/produto_form.html", cupcake=cupcake, categorias=categorias)


@bp.post("/produtos/<int:cupcake_id>/remover")
def remover_produto(cupcake_id):
    """CU02 passo 5: remoção só com confirmação. Produto com vendas é desativado para manter o histórico."""
    cupcake = db.session.get(Cupcake, cupcake_id) or abort(404)
    if request.form.get("confirmacao") != cupcake.nome:
        flash("Remoção cancelada: digite o nome exato do cupcake para confirmar.", "aviso")  # CU02-B
        return redirect(url_for("admin.produtos"))
    cupcake.ativo = False
    db.session.commit()
    flash(f"{cupcake.nome} saiu do cardápio.", "sucesso")
    return redirect(url_for("admin.produtos"))


@bp.post("/produtos/<int:cupcake_id>/estoque")
def ajustar_estoque(cupcake_id):
    cupcake = db.session.get(Cupcake, cupcake_id) or abort(404)
    try:
        novo = int(request.form.get("estoque", ""))
        if novo < 0:
            raise ValueError
        cupcake.estoque = novo
        db.session.commit()
        flash(f"Estoque de {cupcake.nome} atualizado para {novo}.", "sucesso")
    except ValueError:
        flash("Informe um estoque inteiro igual ou maior que zero.", "erro")
    return redirect(url_for("admin.produtos"))


# ---------------- Cupons (US06) ----------------
@bp.route("/cupons", methods=["GET", "POST"])
def cupons():
    if request.method == "POST":
        f = request.form
        try:
            cupom = Cupom(codigo=f.get("codigo", "").strip().upper(), descricao=f.get("descricao", "").strip(),
                          percentual=int(f.get("percentual", 0)),
                          validade=date.fromisoformat(f.get("validade", "")),
                          limite_usos=int(f["limite_usos"]) if f.get("limite_usos") else None)
            if not cupom.codigo or not 1 <= cupom.percentual <= 90:
                raise ValueError
            if Cupom.query.filter_by(codigo=cupom.codigo).first():
                flash("Já existe um cupom com esse código.", "erro")
            else:
                db.session.add(cupom)
                db.session.commit()
                flash(f"Cupom {cupom.codigo} criado.", "sucesso")
        except ValueError:
            flash("Preencha código, desconto (1 a 90%) e validade corretamente.", "erro")
        return redirect(url_for("admin.cupons"))
    return render_template("admin/cupons.html", cupons=Cupom.query.order_by(Cupom.validade.desc()).all(), hoje=date.today())


# ---------------- Relatórios (US15) e avaliações (US10 CA#3) ----------------
@bp.route("/relatorios")
def relatorios():
    periodo = request.args.get("periodo", "mensal")
    hoje = hoje_local()
    inicio = {"diario": hoje, "semanal": hoje - timedelta(days=6)}.get(periodo, hoje - timedelta(days=29))
    try:
        if request.args.get("inicio"):
            inicio = date.fromisoformat(request.args["inicio"])
        fim = date.fromisoformat(request.args["fim"]) if request.args.get("fim") else hoje
    except ValueError:
        flash("Datas inválidas.", "erro")
        fim = hoje
    dados = Pedido.relatorio(inicio, fim)
    if request.args.get("formato") == "csv":
        saida = io.StringIO()
        w = csv.writer(saida, delimiter=";")
        w.writerow(["Relatório de vendas", f"{inicio:%d/%m/%Y} a {fim:%d/%m/%Y}"])
        w.writerow(["Pedidos concluídos", dados["pedidos"]])
        w.writerow(["Total vendido", f"{dados['total']:.2f}".replace(".", ",")])
        w.writerow([])
        w.writerow(["Sabor", "Quantidade", "Valor"])
        for nome, qtd, valor in dados["mais_vendidos"]:
            w.writerow([nome, qtd, f"{Decimal(valor):.2f}".replace(".", ",")])
        return Response("﻿" + saida.getvalue(), mimetype="text/csv",
                        headers={"Content-Disposition": f"attachment; filename=vendas-{inicio}-{fim}.csv"})
    avaliacoes = Avaliacao.query.order_by(Avaliacao.criado_em.desc()).limit(20).all()
    return render_template("admin/relatorios.html", dados=dados, inicio=inicio, fim=fim, periodo=periodo,
                           avaliacoes=avaliacoes)
