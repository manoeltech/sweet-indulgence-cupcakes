# Dicionário de dados

Gerado a partir do banco PostgreSQL criado pelas migrations (`db/migrate/`). Datas gravadas em UTC e exibidas no horário de Brasília.

## users

Usuários: clientes, administradores e entregadores (classes Cliente, Administrador e Entregador do PIT I).

| Coluna | Tipo | Nulo? | Chave | Padrão | Descrição |
|---|---|---|---|---|---|
| id | BIGINT | não | PK |  | Identificador |
| name | VARCHAR(120) | não |  |  | Nome completo |
| email | VARCHAR(160) | não | único |  | E-mail de login (minúsculo) |
| phone | VARCHAR(20) | sim |  |  | Celular, usado pelo entregador |
| password_digest | VARCHAR | não |  |  | Hash bcrypt da senha (a senha nunca é gravada) |
| role | VARCHAR(20) | não |  | customer | Papel: customer, admin ou courier |
| notifications_enabled | BOOLEAN | não |  | true | Cliente quer receber avisos dos pedidos (US09) |
| created_at | TIMESTAMP | não |  |  | Criado em (UTC) |
| updated_at | TIMESTAMP | não |  |  | Atualizado em (UTC) |

Restrições: `role IN ('customer', 'admin', 'courier')`

## addresses

Endereços salvos pelo cliente.

| Coluna | Tipo | Nulo? | Chave | Padrão | Descrição |
|---|---|---|---|---|---|
| id | BIGINT | não | PK |  | Identificador |
| user_id | BIGINT | não | FK → users |  | Dono do endereço |
| street | VARCHAR(160) | não |  |  | Rua |
| number | VARCHAR(10) | não |  |  | Número |
| district | VARCHAR(80) | não |  |  | Bairro |
| zip_code | VARCHAR(9) | não |  |  | CEP |
| created_at | TIMESTAMP | não |  |  | Criado em (UTC) |
| updated_at | TIMESTAMP | não |  |  | Atualizado em (UTC) |

## categories

Categorias da vitrine (Chocolate, Frutas, Diet...).

| Coluna | Tipo | Nulo? | Chave | Padrão | Descrição |
|---|---|---|---|---|---|
| id | BIGINT | não | PK |  | Identificador |
| name | VARCHAR(60) | não | único |  | Nome exibido |
| slug | VARCHAR(60) | não | único |  | Identificador usado no filtro da URL |
| created_at | TIMESTAMP | não |  |  | Criado em (UTC) |
| updated_at | TIMESTAMP | não |  |  | Atualizado em (UTC) |

## cupcakes

Produtos do cardápio.

| Coluna | Tipo | Nulo? | Chave | Padrão | Descrição |
|---|---|---|---|---|---|
| id | BIGINT | não | PK |  | Identificador |
| category_id | BIGINT | não | FK → categories |  | Categoria |
| name | VARCHAR(80) | não |  |  | Nome |
| description | TEXT | não |  |  | Descrição |
| ingredients | TEXT | não |  |  | Ingredientes |
| price | NUMERIC(8,2) | não |  |  | Preço atual (R$) |
| stock | INTEGER | não |  | 0 | Unidades em estoque |
| min_stock | INTEGER | não |  | 5 | Abaixo disso, alerta de estoque baixo (US12) |
| calories | INTEGER | sim |  |  | Calorias por unidade (kcal) |
| fat_grams | NUMERIC(5,1) | sim |  |  | Gorduras (g) |
| sugar_grams | NUMERIC(5,1) | sim |  |  | Açúcares (g) |
| allergens | VARCHAR(200) | não |  |  | Alérgenos separados por vírgula (US03) |
| color | VARCHAR(7) | não |  | #f9a8d4 | Cor da cobertura na ilustração |
| active | BOOLEAN | não |  | true | Falso quando sai do cardápio (CU02) |
| created_at | TIMESTAMP | não |  |  | Criado em (UTC) |
| updated_at | TIMESTAMP | não |  |  | Atualizado em (UTC) |

Restrições: `price > 0::numeric`; `stock >= 0`

## favorites

Cupcakes favoritos do cliente (US05).

| Coluna | Tipo | Nulo? | Chave | Padrão | Descrição |
|---|---|---|---|---|---|
| id | BIGINT | não | PK |  | Identificador |
| user_id | BIGINT | não | FK → users |  | Cliente |
| cupcake_id | BIGINT | não | FK → cupcakes |  | Cupcake favoritado |
| created_at | TIMESTAMP | não |  |  | Criado em (UTC) |
| updated_at | TIMESTAMP | não |  |  | Atualizado em (UTC) |

Restrições: único (user_id, cupcake_id)

## coupons

Cupons de desconto (classe Promoção do PIT I, US06).

| Coluna | Tipo | Nulo? | Chave | Padrão | Descrição |
|---|---|---|---|---|---|
| id | BIGINT | não | PK |  | Identificador |
| code | VARCHAR(30) | não | único |  | Código digitado pelo cliente (maiúsculo) |
| description | VARCHAR(120) | não |  |  | Descrição interna |
| percentage | INTEGER | não |  |  | Desconto em % |
| valid_until | DATE | não |  |  | Último dia de validade |
| usage_limit | INTEGER | sim |  |  | Máximo de usos (vazio = sem limite) |
| uses_count | INTEGER | não |  | 0 | Quantas vezes já foi usado |
| active | BOOLEAN | não |  | true | Cupom ativo |
| created_at | TIMESTAMP | não |  |  | Criado em (UTC) |
| updated_at | TIMESTAMP | não |  |  | Atualizado em (UTC) |

Restrições: `percentage >= 1 AND percentage <= 90`

## delivery_zones

Zonas de entrega com frete e prazo (US07).

| Coluna | Tipo | Nulo? | Chave | Padrão | Descrição |
|---|---|---|---|---|---|
| id | BIGINT | não | PK |  | Identificador |
| name | VARCHAR(80) | não | único |  | Bairro ou faixa de distância |
| fee | NUMERIC(6,2) | não |  |  | Frete (R$) |
| eta_minutes | INTEGER | não |  | 45 | Prazo estimado (min) |
| created_at | TIMESTAMP | não |  |  | Criado em (UTC) |
| updated_at | TIMESTAMP | não |  |  | Atualizado em (UTC) |

Restrições: `fee >= 0::numeric`

## orders

Pedidos (CU01).

| Coluna | Tipo | Nulo? | Chave | Padrão | Descrição |
|---|---|---|---|---|---|
| id | BIGINT | não | PK |  | Identificador |
| code | VARCHAR(12) | não | único |  | Código curto mostrado ao cliente |
| customer_id | BIGINT | não | FK → users |  | Cliente que comprou |
| courier_id | BIGINT | sim | FK → users |  | Entregador atribuído (US14) |
| coupon_id | BIGINT | sim | FK → coupons |  | Cupom usado |
| delivery_zone_id | BIGINT | sim | FK → delivery_zones |  | Zona de entrega |
| status | VARCHAR(30) | não |  | paid | awaiting_payment, paid, preparing, out_for_delivery, ready_for_pickup, delivered ou canceled |
| fulfillment | VARCHAR(10) | não |  |  | delivery (entrega) ou pickup (retirada) |
| delivery_address | VARCHAR(255) | sim |  |  | Endereço de entrega |
| payment_method | VARCHAR(10) | não |  |  | credit, debit ou pix |
| card_last4 | VARCHAR(4) | sim |  |  | 4 últimos dígitos do cartão (o número completo nunca é gravado) |
| pix_code | VARCHAR(255) | sim |  |  | Código PIX copia e cola |
| subtotal | NUMERIC(10,2) | não |  |  | Soma dos itens |
| discount | NUMERIC(10,2) | não |  | 0.0 | Desconto do cupom |
| shipping_fee | NUMERIC(10,2) | não |  | 0.0 | Frete |
| total | NUMERIC(10,2) | não |  |  | Subtotal − desconto + frete |
| created_at | TIMESTAMP | não |  |  | Criado em (UTC) |
| updated_at | TIMESTAMP | não |  |  | Atualizado em (UTC) |

Restrições: `total >= 0::numeric`

## order_items

Itens de cada pedido.

| Coluna | Tipo | Nulo? | Chave | Padrão | Descrição |
|---|---|---|---|---|---|
| id | BIGINT | não | PK |  | Identificador |
| order_id | BIGINT | não | FK → orders |  | Pedido |
| cupcake_id | BIGINT | não | FK → cupcakes |  | Cupcake |
| quantity | INTEGER | não |  |  | Quantidade |
| unit_price | NUMERIC(8,2) | não |  |  | Preço na hora da compra (não muda se o preço do cupcake mudar) |
| created_at | TIMESTAMP | não |  |  | Criado em (UTC) |
| updated_at | TIMESTAMP | não |  |  | Atualizado em (UTC) |

Restrições: `quantity > 0`

## reviews

Avaliações depois da entrega (US10).

| Coluna | Tipo | Nulo? | Chave | Padrão | Descrição |
|---|---|---|---|---|---|
| id | BIGINT | não | PK |  | Identificador |
| user_id | BIGINT | não | FK → users |  | Cliente |
| order_id | BIGINT | não | FK → orders |  | Pedido |
| cupcake_id | BIGINT | não | FK → cupcakes |  | Cupcake avaliado |
| rating | INTEGER | não |  |  | Nota do cupcake (1 a 5) |
| delivery_rating | INTEGER | não |  |  | Nota da entrega (1 a 5) |
| comment | TEXT | não |  |  | Comentário opcional |
| created_at | TIMESTAMP | não |  |  | Criado em (UTC) |
| updated_at | TIMESTAMP | não |  |  | Atualizado em (UTC) |

Restrições: único (order_id, cupcake_id); `delivery_rating >= 1 AND delivery_rating <= 5`; `rating >= 1 AND rating <= 5`

## notifications

Notificações dentro do app (US09).

| Coluna | Tipo | Nulo? | Chave | Padrão | Descrição |
|---|---|---|---|---|---|
| id | BIGINT | não | PK |  | Identificador |
| user_id | BIGINT | não | FK → users |  | Quem recebe |
| order_id | BIGINT | sim | FK → orders |  | Pedido relacionado |
| message | VARCHAR(255) | não |  |  | Texto |
| read | BOOLEAN | não |  | false | Já foi lida |
| created_at | TIMESTAMP | não |  |  | Criado em (UTC) |
| updated_at | TIMESTAMP | não |  |  | Atualizado em (UTC) |

## contact_logs

Registro de ligações e WhatsApp do entregador (US18).

| Coluna | Tipo | Nulo? | Chave | Padrão | Descrição |
|---|---|---|---|---|---|
| id | BIGINT | não | PK |  | Identificador |
| order_id | BIGINT | não | FK → orders |  | Pedido |
| courier_id | BIGINT | não | FK → users |  | Entregador |
| channel | VARCHAR(10) | não |  |  | call (ligação) ou whatsapp |
| created_at | TIMESTAMP | não |  |  | Criado em (UTC) |
| updated_at | TIMESTAMP | não |  |  | Atualizado em (UTC) |
