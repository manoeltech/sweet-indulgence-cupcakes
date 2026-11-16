"""CONTROLLER de autenticação: cadastro, login, logout e perfil."""
from functools import wraps

from flask import Blueprint, abort, flash, g, redirect, render_template, request, session, url_for

from ..models import Endereco, Notificacao, Usuario, db

bp = Blueprint("auth", __name__)


def usuario_atual():
    uid = session.get("usuario_id")
    cache = g.get("usuario_cache")
    if cache is None or cache[0] != uid:  # o cache vale só para o usuário da sessão atual
        g.usuario_cache = (uid, db.session.get(Usuario, uid) if uid else None)
    return g.usuario_cache[1]


def login_obrigatorio(papel=None):
    def decorador(view):
        @wraps(view)
        def envolvida(*args, **kwargs):
            usuario = usuario_atual()
            if usuario is None:
                flash("Entre na sua conta para continuar.", "aviso")
                return redirect(url_for("auth.entrar", proximo=request.path))
            if papel and usuario.papel != papel:
                abort(403, "Esta área é restrita.")
            return view(*args, **kwargs)
        return envolvida
    return decorador


def _destino_seguro(proximo):
    return proximo if proximo and proximo.startswith("/") and not proximo.startswith("//") else None


@bp.route("/cadastro", methods=["GET", "POST"])
def cadastrar():
    dados = request.form
    if request.method == "POST":
        erros = []
        nome, email = dados.get("nome", "").strip(), dados.get("email", "").strip().lower()
        if not nome:
            erros.append("Informe seu nome.")
        if "@" not in email or "." not in email.split("@")[-1]:
            erros.append("Informe um e-mail válido.")
        elif Usuario.query.filter_by(email=email).first():
            erros.append("Já existe uma conta com este e-mail.")
        if dados.get("senha") != dados.get("confirmacao"):
            erros.append("As senhas não conferem.")
        usuario = Usuario(nome=nome, email=email, telefone=dados.get("telefone", "").strip(), papel="cliente")
        try:
            usuario.definir_senha(dados.get("senha"))
        except ValueError as e:
            erros.append(str(e))
        if erros:
            for erro in erros:
                flash(erro, "erro")
            return render_template("auth/cadastro.html", dados=dados), 422
        db.session.add(usuario)
        db.session.commit()
        session.clear()
        session["usuario_id"] = usuario.id
        flash(f"Bem-vindo(a), {usuario.nome}!", "sucesso")
        return redirect(_destino_seguro(request.args.get("proximo")) or url_for("loja.vitrine"))
    return render_template("auth/cadastro.html", dados=dados)


@bp.route("/entrar", methods=["GET", "POST"])
def entrar():
    if request.method == "POST":
        usuario = Usuario.query.filter_by(email=request.form.get("email", "").strip().lower()).first()
        if usuario is None or not usuario.confere_senha(request.form.get("senha")):
            flash("E-mail ou senha incorretos.", "erro")
            return render_template("auth/entrar.html", email=request.form.get("email", "")), 401
        # O carrinho e o cupom do visitante continuam após o login (bug do cupom achado no teste manual).
        mantidos = {k: session[k] for k in ("carrinho", "cupom") if k in session}
        session.clear()
        session.update(mantidos)
        session["usuario_id"] = usuario.id
        destino = _destino_seguro(request.args.get("proximo"))
        if destino:
            return redirect(destino)
        if usuario.admin:
            return redirect(url_for("admin.dashboard"))
        if usuario.entregador:
            return redirect(url_for("entregador.entregas"))
        return redirect(url_for("loja.vitrine"))
    return render_template("auth/entrar.html", email="")


@bp.post("/sair")
def sair():
    session.clear()
    flash("Você saiu da sua conta.", "sucesso")
    return redirect(url_for("loja.vitrine"))


@bp.route("/perfil", methods=["GET", "POST"])
@login_obrigatorio()
def perfil():
    usuario = usuario_atual()
    if request.method == "POST":
        acao = request.form.get("acao")
        if acao == "endereco":
            campos = {c: request.form.get(c, "").strip() for c in ("rua", "numero", "bairro", "cep")}
            if not all(campos.values()):
                flash("Preencha todos os campos do endereço.", "erro")
            else:
                db.session.add(Endereco(usuario=usuario, **campos))
                db.session.commit()
                flash("Endereço salvo.", "sucesso")
        elif acao == "notificacoes":
            usuario.notificacoes_ativas = request.form.get("ativas") == "1"
            db.session.commit()
            flash("Preferência de notificações atualizada.", "sucesso")
        return redirect(url_for("auth.perfil"))
    return render_template("auth/perfil.html", usuario=usuario)


@bp.route("/notificacoes")
@login_obrigatorio()
def notificacoes():
    usuario = usuario_atual()
    lista = Notificacao.query.filter_by(usuario_id=usuario.id).order_by(Notificacao.criado_em.desc()).limit(50).all()
    for n in lista:
        n.lida = True
    db.session.commit()
    return render_template("auth/notificacoes.html", notificacoes=lista)
