# 🧁 Sweet Indulgence Cupcakes

Loja virtual para uma confeitaria de cupcakes gourmet. Tem vitrine, carrinho e cupons, entrega ou retirada, pagamento por cartão ou PIX e acompanhamento do pedido, além do painel do administrador e da área do entregador.

Projeto Integrador Transdisciplinar em Engenharia de Software II – Cruzeiro do Sul Virtual.
Autor: **Manoel Pereira Neto** (RGM 35828617).

| | |
|---|---|
| Front-end | HTML, CSS e JavaScript puro (views ERB), mobile-first |
| Back-end | **Ruby 3.4 + Ruby on Rails 8.1**, padrão **MVC** |
| Banco | PostgreSQL (em desenvolvimento, testes e produção) |
| Testes | Minitest: 101 testes automatizados (modelos e integração) + RuboCop + Brakeman |
| Hospedagem | Render (blueprint em `render.yaml`) – **https://sweet-indulgence-cupcakes.onrender.com** |
| Fotos dos cupcakes | Wikimedia Commons, licenças Creative Commons – [créditos](docs/creditos-das-fotos.md) |

## Documentação por situação-problema

| Pasta | Conteúdo |
|---|---|
| [`docs/situacao-1-planejamento`](docs/situacao-1-planejamento/) | Escopo revisado, UML (casos de uso, classes, sequência, atividades), IHC, projeto conceitual/lógico/físico do banco e dicionário de dados |
| [`docs/situacao-2-codificacao`](docs/situacao-2-codificacao/) | Arquitetura MVC em Rails, rastreabilidade história → código, segurança, **manual de uso** e publicação |
| [`docs/situacao-3-testes`](docs/situacao-3-testes/) | Plano de testes, **laudo de qualidade** com os defeitos encontrados e corrigidos, formulário para os colegas e evidências (prints e saídas dos testes) |

## Como o código foi construído

Cada tarefa foi feita numa **branch própria**, com commits pequenos, e entrou na `main` por **Pull Request**. A tabela mostra os PRs em ordem; cada um depende do anterior.

| PR | Branch | Tarefa |
|---|---|---|
| #1 | `chore/migracao-rails` | Troca da base Flask por Rails (a versão Flask fica na tag `v1-flask`) |
| #2 | `feature/modelos-e-banco` | Tabelas, regras de negócio e testes dos modelos |
| #3 | `feature/tela-vitrine` | Layout base, vitrine e detalhe do cupcake |
| #4 | `feature/autenticacao` | Cadastro, login, perfil e notificações |
| #5 | `feature/favoritos` | Favoritos |
| #6 | `feature/tela-carrinho` | Carrinho e cupom |
| #7 | `feature/tela-checkout` | Checkout, pagamento e confirmação |
| #8 | `feature/acompanhamento-de-pedidos` | Meus pedidos, acompanhamento e avaliação |
| #9 | `feature/painel-admin` | Painel de pedidos do administrador |
| #10 | `feature/admin-produtos-e-estoque` | Catálogo e estoque |
| #11 | `feature/admin-cupons-e-relatorios` | Cupons e relatório de vendas |
| #12 | `feature/area-entregador` | Área do entregador |
| #13 | `chore/deploy-render` | Publicação no Render |
| #14 | `docs/documentacao-rails` | Documentação, laudo e evidências |

## Rodar localmente

Pré-requisitos: Ruby 3.4 e um PostgreSQL rodando em `localhost` (usuário e senha `postgres`, ou as variáveis `POSTGRES_USER`/`POSTGRES_PASSWORD`).

```bash
bundle install
bin/rails db:prepare   # cria o banco, as tabelas e os dados de demonstração
bin/rails server       # http://localhost:3000
bin/rails test         # 101 testes
```

Contas de demonstração (senha `cupcake123`): `cliente@sweetindulgence.com`, `admin@sweetindulgence.com`, `entregador@sweetindulgence.com`.
Cartão de teste aprovado: `4111 1111 1111 1111`. Cartão de teste recusado: `4000 0000 0000 0002`. O pagamento é **simulado**: não use cartão real.
