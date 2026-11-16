import os
import secrets

from flask import Flask, abort, render_template, request, session

from .models import Cupcake, Notificacao, db


def _database_url():
    url = os.environ.get("DATABASE_URL", "sqlite:///cupcakes.db")
    # Render/Heroku entregam "postgres://", o SQLAlchemy espera "postgresql://".
    return url.replace("postgres://", "postgresql://", 1)


def create_app(config=None):
    app = Flask(__name__, instance_relative_config=True)
    app.config.update(
        SECRET_KEY=os.environ.get("SECRET_KEY", "dev-troque-em-producao"),
        SQLALCHEMY_DATABASE_URI=_database_url(),
        SQLALCHEMY_TRACK_MODIFICATIONS=False,
        SESSION_COOKIE_HTTPONLY=True,
        SESSION_COOKIE_SAMESITE="Lax",
        WTF_CSRF=True,
    )
    if config:
        app.config.update(config)

    db.init_app(app)

    from .controllers import admin, auth, carrinho, entregador, loja, pedidos
    for bp in (loja.bp, auth.bp, carrinho.bp, pedidos.bp, admin.bp, entregador.bp):
        app.register_blueprint(bp)

    from .seed import registrar_comandos
    registrar_comandos(app)

    @app.before_request
    def proteger_csrf():
        """Todo formulário POST precisa do token da sessão (proteção contra CSRF)."""
        if request.method == "POST" and app.config.get("WTF_CSRF"):
            enviado = request.form.get("csrf_token") or request.headers.get("X-CSRF-Token")
            if not enviado or enviado != session.get("csrf_token"):
                abort(400, "Formulário expirado. Recarregue a página e tente novamente.")

    @app.context_processor
    def contexto_global():
        from .controllers.auth import usuario_atual
        if "csrf_token" not in session:
            session["csrf_token"] = secrets.token_urlsafe(32)
        usuario = usuario_atual()
        nao_lidas = Notificacao.query.filter_by(usuario_id=usuario.id, lida=False).count() if usuario else 0
        return {
            "usuario_atual": usuario,
            "csrf_token": session["csrf_token"],
            "itens_no_carrinho": sum(session.get("carrinho", {}).values()),
            "notificacoes_nao_lidas": nao_lidas,
        }

    @app.template_filter("brl")
    def brl(valor):
        valor = float(valor or 0)
        return "R$ " + f"{valor:,.2f}".replace(",", "X").replace(".", ",").replace("X", ".")

    @app.template_filter("data")
    def data(valor):
        from .fuso import para_local
        return para_local(valor).strftime("%d/%m/%Y %H:%M") if valor else ""

    for codigo, titulo in ((400, "Algo deu errado"), (403, "Acesso negado"), (404, "Página não encontrada")):
        app.register_error_handler(
            codigo,
            lambda e, c=codigo, t=titulo: (render_template("erro.html", codigo=c, titulo=t, mensagem=e.description), c),
        )

    @app.errorhandler(500)
    def erro_interno(e):
        db.session.rollback()
        return render_template("erro.html", codigo=500, titulo="Erro interno",
                               mensagem="Tivemos um problema. Tente novamente em instantes."), 500

    app.jinja_env.globals["Cupcake"] = Cupcake
    return app
