# 🧁 Sweet Indulgence Cupcakes

Loja virtual para uma confeitaria de cupcakes gourmet: vitrine, carrinho, cupons, entrega ou retirada, pagamento (cartão/PIX), acompanhamento do pedido, painel do administrador e área do entregador.

Projeto Integrador Transdisciplinar em Engenharia de Software II – Cruzeiro do Sul Virtual.
Autor: **Manoel Pereira Neto** (RGM 35828617).

| | |
|---|---|
| Front-end | HTML, CSS e JavaScript (Jinja2), mobile-first |
| Back-end | Python + Flask, padrão **MVC** |
| Banco | PostgreSQL (produção) / SQLite (desenvolvimento) |
| Testes | pytest – 44 testes automatizados |
| Hospedagem | Render (blueprint em `render.yaml`) |

## Documentação por situação-problema

| Pasta | Conteúdo |
|---|---|
| [`docs/situacao-1-planejamento`](docs/situacao-1-planejamento/) | Escopo revisado, UML (casos de uso, classes, sequência, atividades), IHC, projeto conceitual/lógico/físico do banco e dicionário de dados |
| [`docs/situacao-2-codificacao`](docs/situacao-2-codificacao/) | Arquitetura MVC, rastreabilidade história → código, segurança, **manual de uso** e publicação |
| [`docs/situacao-3-testes`](docs/situacao-3-testes/) | Plano de testes, **laudo de qualidade** com os defeitos encontrados e corrigidos, formulário para os colegas e evidências (prints e saídas do pytest) |

## Rodar localmente

```bash
pip install -r requirements.txt
flask --app wsgi popular   # tabelas + dados de demonstração
flask --app wsgi run       # http://127.0.0.1:5000
pytest
```

Contas de demonstração (senha `cupcake123`): `cliente@sweetindulgence.com`, `admin@sweetindulgence.com`, `entregador@sweetindulgence.com`.
Cartão de teste aprovado `4111 1111 1111 1111`; recusado `4000 0000 0000 0002`. O pagamento é **simulado** – não use cartão real.
