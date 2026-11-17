# Situação 2 – Codificação

## Tecnologias

| Camada | Escolha |
|---|---|
| Front-end | HTML5, CSS3 e JavaScript puro (views ERB renderizadas no servidor, sem frameworks de JS) |
| Back-end | Ruby 3.4 com **Ruby on Rails 8.1** |
| Padrão de projeto | **MVC** (o próprio Rails separa models, views e controllers) |
| Banco de dados | PostgreSQL, com o mesmo SGBD em desenvolvimento, testes e produção |
| Testes | Minitest (modelos e integração), RuboCop (estilo) e Brakeman (segurança) |
| Servidor de produção | Puma, no Render |
| Modo de codificação | Tradicional |
| Controle de versão | Git + GitHub, com **uma branch e um Pull Request por tarefa** (ver o README principal) |

## Arquitetura MVC

```
app/
├── models/                 ← MODEL: entidades + regras de negócio
│   ├── user.rb, address.rb
│   ├── category.rb, cupcake.rb, favorite.rb, review.rb
│   ├── coupon.rb, delivery_zone.rb, order.rb, order_item.rb
│   ├── notification.rb, contact_log.rb
│   ├── cart.rb                  carrinho guardado na sessão
│   ├── simulated_gateway.rb     pagamento simulado (isolado para troca futura)
│   └── business_rule_error.rb   erro de regra com mensagem para o usuário
├── controllers/            ← CONTROLLER: recebe a requisição, chama o model, escolhe a view
│   ├── cupcakes_controller.rb, favorites_controller.rb, carts/…, checkouts_controller.rb
│   ├── orders_controller.rb, orders/ (confirmação, PIX, avaliações)
│   ├── sessions_controller.rb, registrations_controller.rb, profiles/…, notifications_controller.rb
│   ├── admin/ (painel, status, entregador, produtos, estoque, cupons, relatórios)
│   ├── courier/ (entregas, contato, marcar entregue)
│   └── concerns/ (authentication.rb, current_cart.rb)
├── views/                  ← VIEW: páginas HTML (ERB)
└── assets/
    ├── stylesheets/application.css   mobile-first
    └── javascripts/application.js    checkout, PIX e confirmações
config/routes.rb            rotas em português (/carrinho, /finalizar, /pedidos, /admin/produtos…)
db/migrate/                 criação das tabelas
db/seeds.rb                 dados de demonstração
test/                       Minitest: models/ e controllers/
```

As regras de negócio ficam **no model**, e os controllers ficam curtos. Por exemplo:
- `Order.place!` confere o estoque (com *lock*, para dois clientes não comprarem a última unidade), o cupom e a zona. Depois cobra, grava o pedido, baixa o estoque e notifica, tudo numa única transação: se o cartão é recusado, nada fica gravado.
- `Order#advance_to!` só aceita transições válidas para o tipo de recebimento e devolve o estoque ao cancelar.

Os controllers seguem o padrão REST do Rails: cada ação do usuário é um recurso. Por exemplo, "marcar como entregue" é `POST /entregador/entregas/:código/entregue` e cai em `Courier::Deliveries::CompletionsController#create`.

### Segurança e tratamento de erros
- **Senhas:** guardadas com hash bcrypt (`has_secure_password`); o login usa `authenticate_by`, que resiste a ataques de tempo.
- **CSRF:** proteção nativa do Rails em todos os formulários.
- **Sessão:** cookie `HttpOnly` e `Secure` em produção, renovada a cada login para evitar fixação de sessão.
- **Acesso por papel:** cliente, admin e entregador. Um cliente só vê os próprios pedidos e um entregador só vê as próprias entregas (os outros dão 404).
- **Cartão:** o número nunca é gravado (só os 4 últimos dígitos) e os dados do cartão são filtrados dos logs.
- **Redirecionamento após o login:** só para caminhos internos, para evitar *open redirect*.
- **Parâmetros:** só os campos permitidos entram (`params.expect`).
- **Restrições no banco:** chaves estrangeiras, índices únicos e `CHECK`.
- **Mensagens de erro:** em português, perto da ação (`BusinessRuleError` e validações).
- **Páginas de erro:** próprias para 403, 404, 422 e 500.
- **Brakeman:** análise de segurança sem avisos ([evidência](../situacao-3-testes/evidencias/qualidade-rubocop-brakeman.txt)).

### Rastreabilidade: histórias de usuário → código

| História | Onde está |
|---|---|
| US01 Vitrine | `Cupcake.storefront`, `CupcakesController#index`, `cupcakes/index.html.erb` |
| US02 Filtro por categoria | `Cupcake.storefront(category_slug:, query:)`, filtros em círculo |
| US03 Nutricional e alérgenos | `cupcakes/show.html.erb` |
| US04 Carrinho | `Cart` (limite = estoque), `Carts::ItemsController` |
| US05 Favoritos | `Favorite.toggle!`, `Cupcakes::FavoritesController`, `/favoritos` |
| US06 Cupons | `Coupon.find_valid!`, `Carts::CouponsController`, `Admin::CouponsController` |
| US07 Entrega/retirada | `DeliveryZone`, `Order#set_delivery`, `checkouts/new.html.erb` |
| US08 Pagamento | `SimulatedGateway` (crédito, débito, PIX), `Orders::PixPaymentsController` |
| US09 Notificações | `Notification.notify`, 🔔 no cabeçalho, preferência no perfil |
| US10 Avaliação | `Review` (só pedido entregue), `Orders::ReviewsController` |
| US11 Catálogo | `Admin::CupcakesController`, `Cupcake#remove_from_menu!` |
| US12 Estoque | `Cupcake#adjust_stock!`, `Cupcake.low_stock`, `Admin::Cupcakes::StocksController` |
| US13 Painel de pedidos | `Admin::DashboardsController`, `Order#advance_to!` |
| US14 Atribuir entregador | `Order#assign_courier!` (máx. 3 simultâneas) |
| US15 Relatórios | `Order.sales_report`, `Admin::ReportsController` (+ CSV) |
| US16 Detalhes da entrega | `Courier::DeliveriesController` (abrir no GPS) |
| US17 Marcar entregue | `Courier::Deliveries::CompletionsController` (exige confirmação) |
| US18 Contatar cliente | `Courier::Deliveries::ContactsController` (ligação/WhatsApp, registrado em `ContactLog`) |

## Manual de uso

### Rodar no computador
Pré-requisitos: Ruby 3.4 e PostgreSQL rodando em `localhost` (usuário/senha `postgres`, ou as variáveis `POSTGRES_USER`, `POSTGRES_PASSWORD` e `POSTGRES_HOST`).

```bash
git clone https://github.com/manoeltech/sweet-indulgence-cupcakes.git
cd sweet-indulgence-cupcakes
bundle install
bin/rails db:prepare   # cria o banco, as tabelas e os dados de demonstração
bin/rails server       # abre em http://localhost:3000
bin/rails test         # roda os testes
```

### Contas de demonstração (senha `cupcake123`)
| Perfil | E-mail |
|---|---|
| Cliente | cliente@sweetindulgence.com |
| Administrador | admin@sweetindulgence.com |
| Entregador | entregador@sweetindulgence.com |

### Dados para testar o pagamento
| Cartão | Resultado |
|---|---|
| 4111 1111 1111 1111 (qualquer nome, validade futura, CVV 123) | Aprovado |
| 4000 0000 0000 0002 | Recusado (fluxo alternativo CU01-B) |
| PIX | Gera o código copia e cola; o botão "Já paguei" simula a confirmação do banco |

Cupons: `BEMVINDO10` (10%, válido) e `VERAO2025` (expirado, para testar o erro).

### Passo a passo
1. **Cliente:**
   1. Escolha cupcakes na vitrine. Dá para filtrar por categoria e buscar pelo nome.
   2. Adicione ao carrinho e aplique um cupom.
   3. Clique em **Continuar para o pagamento**.
   4. Escolha entrega (com o bairro) ou retirada, depois a forma de pagamento, e finalize.
   5. Acompanhe o pedido em **Pedidos** e as notificações no 🔔.
   6. Depois da entrega, avalie o pedido.
2. **Administrador:**
   1. No **Painel**, mova o pedido para **Em preparação** e atribua um entregador.
   2. Clique em **Saiu para entrega**.
   3. Em **Produtos e estoque**, cadastre, edite, reponha ou remova cupcakes.
   4. Em **Cupons**, crie promoções.
   5. Em **Relatórios**, veja as vendas e exporte o CSV.
3. **Entregador:**
   1. Em **Minhas entregas**, abra o pedido.
   2. Use **Abrir no GPS**, **Ligar** ou **WhatsApp**.
   3. Confirme com o cliente e clique em **Marcar como entregue**.

## Publicação (Render + PostgreSQL)
O arquivo [`render.yaml`](../../render.yaml) descreve a aplicação e o banco PostgreSQL, ambos no plano gratuito.

1. No Render, clique em **New → Blueprint** e escolha este repositório.
2. Na primeira publicação, o script [`bin/render-build.sh`](../../bin/render-build.sh) instala as gems, compila os assets, cria as tabelas e insere os dados de demonstração.
3. O Render gera a `SECRET_KEY_BASE` e passa a conexão do banco em `DATABASE_URL`.

Para testar o modo produção na própria máquina, sem HTTPS, use `LOCAL_HTTP=1`.
