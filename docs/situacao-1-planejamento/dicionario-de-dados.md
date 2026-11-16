# Dicionário de dados

Gerado a partir dos models (`app/models/`). Tipos conforme o PostgreSQL de produção.


## categorias

Categorias da vitrine (Chocolate, Frutas, Diet...).

| Coluna | Tipo | Nulo? | Chave | Padrão |
|---|---|---|---|---|
| id | INTEGER | não | PK |  |
| nome | VARCHAR(60) | não | único |  |
| slug | VARCHAR(60) | não | único |  |

## cupons

Cupons de desconto (classe Promocao do PIT I).

| Coluna | Tipo | Nulo? | Chave | Padrão |
|---|---|---|---|---|
| id | INTEGER | não | PK |  |
| codigo | VARCHAR(30) | não | único |  |
| descricao | VARCHAR(120) | não |  |  |
| percentual | INTEGER | não |  |  |
| validade | DATE | não |  |  |
| limite_usos | INTEGER | sim |  |  |
| usos | INTEGER | não |  | 0 |
| ativo | BOOLEAN | não |  | True |

Restrições: `percentual BETWEEN 1 AND 90`

## usuarios

Clientes, administradores e entregadores (campo papel).

| Coluna | Tipo | Nulo? | Chave | Padrão |
|---|---|---|---|---|
| id | INTEGER | não | PK |  |
| nome | VARCHAR(120) | não |  |  |
| email | VARCHAR(160) | não | único |  |
| telefone | VARCHAR(20) | sim |  |  |
| senha_hash | VARCHAR(255) | não |  |  |
| papel | VARCHAR(20) | não |  | cliente |
| notificacoes_ativas | BOOLEAN | não |  | True |
| criado_em | TIMESTAMP WITHOUT TIME ZONE | não |  |  |

## zonas_entrega

Faixas de frete por bairro/distância.

| Coluna | Tipo | Nulo? | Chave | Padrão |
|---|---|---|---|---|
| id | INTEGER | não | PK |  |
| nome | VARCHAR(80) | não | único |  |
| taxa | NUMERIC(6, 2) | não |  |  |
| prazo_min | INTEGER | não |  | 45 |

## cupcakes

Catálogo de produtos com preço, estoque e informação nutricional.

| Coluna | Tipo | Nulo? | Chave | Padrão |
|---|---|---|---|---|
| id | INTEGER | não | PK |  |
| categoria_id | INTEGER | não | FK → categorias.id |  |
| nome | VARCHAR(80) | não |  |  |
| descricao | TEXT | não |  |  |
| ingredientes | TEXT | não |  |  |
| preco | NUMERIC(8, 2) | não |  |  |
| estoque | INTEGER | não |  | 0 |
| estoque_minimo | INTEGER | não |  | 5 |
| calorias | INTEGER | sim |  |  |
| gorduras_g | NUMERIC(5, 1) | sim |  |  |
| acucares_g | NUMERIC(5, 1) | sim |  |  |
| alergenos | VARCHAR(200) | não |  |  |
| cor | VARCHAR(7) | não |  | #f9a8d4 |
| ativo | BOOLEAN | não |  | True |
| criado_em | TIMESTAMP WITHOUT TIME ZONE | não |  |  |

Restrições: `preco > 0`; `estoque >= 0`

## enderecos

Endereços de entrega salvos pelo cliente.

| Coluna | Tipo | Nulo? | Chave | Padrão |
|---|---|---|---|---|
| id | INTEGER | não | PK |  |
| usuario_id | INTEGER | não | FK → usuarios.id |  |
| rua | VARCHAR(160) | não |  |  |
| numero | VARCHAR(10) | não |  |  |
| bairro | VARCHAR(80) | não |  |  |
| cep | VARCHAR(9) | não |  |  |

## pedidos

Pedido do cliente, com valores congelados no momento da compra.

| Coluna | Tipo | Nulo? | Chave | Padrão |
|---|---|---|---|---|
| id | INTEGER | não | PK |  |
| codigo | VARCHAR(12) | não | único |  |
| cliente_id | INTEGER | não | FK → usuarios.id |  |
| entregador_id | INTEGER | sim | FK → usuarios.id |  |
| cupom_id | INTEGER | sim | FK → cupons.id |  |
| zona_id | INTEGER | sim | FK → zonas_entrega.id |  |
| status | VARCHAR(30) | não |  | pendente |
| metodo_entrega | VARCHAR(10) | não |  |  |
| endereco_entrega | VARCHAR(255) | sim |  |  |
| metodo_pagamento | VARCHAR(10) | não |  |  |
| cartao_final | VARCHAR(4) | sim |  |  |
| pix_copia_cola | VARCHAR(255) | sim |  |  |
| subtotal | NUMERIC(10, 2) | não |  |  |
| desconto | NUMERIC(10, 2) | não |  | 0 |
| frete | NUMERIC(10, 2) | não |  | 0 |
| total | NUMERIC(10, 2) | não |  |  |
| criado_em | TIMESTAMP WITHOUT TIME ZONE | não |  |  |
| atualizado_em | TIMESTAMP WITHOUT TIME ZONE | não |  |  |

## avaliacoes

Notas de 1 a 5 para o cupcake e para a entrega, após o pedido entregue.

| Coluna | Tipo | Nulo? | Chave | Padrão |
|---|---|---|---|---|
| id | INTEGER | não | PK |  |
| usuario_id | INTEGER | não | FK → usuarios.id |  |
| cupcake_id | INTEGER | não | FK → cupcakes.id |  |
| pedido_id | INTEGER | não | FK → pedidos.id |  |
| nota | INTEGER | não |  |  |
| nota_entrega | INTEGER | não |  |  |
| comentario | TEXT | não |  |  |
| criado_em | TIMESTAMP WITHOUT TIME ZONE | não |  |  |

Restrições: `nota_entrega BETWEEN 1 AND 5`; `nota BETWEEN 1 AND 5`

## favoritos

Lista de desejos do cliente (chave composta usuário + cupcake).

| Coluna | Tipo | Nulo? | Chave | Padrão |
|---|---|---|---|---|
| usuario_id | INTEGER | não | PK FK → usuarios.id |  |
| cupcake_id | INTEGER | não | PK FK → cupcakes.id |  |
| criado_em | TIMESTAMP WITHOUT TIME ZONE | não |  |  |

## itens_pedido

Itens do pedido com o preço unitário da época da compra.

| Coluna | Tipo | Nulo? | Chave | Padrão |
|---|---|---|---|---|
| id | INTEGER | não | PK |  |
| pedido_id | INTEGER | não | FK → pedidos.id |  |
| cupcake_id | INTEGER | não | FK → cupcakes.id |  |
| quantidade | INTEGER | não |  |  |
| preco_unitario | NUMERIC(8, 2) | não |  |  |

Restrições: `quantidade > 0`

## notificacoes

Avisos dentro do app sobre mudanças de status.

| Coluna | Tipo | Nulo? | Chave | Padrão |
|---|---|---|---|---|
| id | INTEGER | não | PK |  |
| usuario_id | INTEGER | não | FK → usuarios.id |  |
| pedido_id | INTEGER | sim | FK → pedidos.id |  |
| mensagem | VARCHAR(255) | não |  |  |
| lida | BOOLEAN | não |  | False |
| criado_em | TIMESTAMP WITHOUT TIME ZONE | não |  |  |

## registros_contato

Auditoria dos contatos do entregador com o cliente (US18).

| Coluna | Tipo | Nulo? | Chave | Padrão |
|---|---|---|---|---|
| id | INTEGER | não | PK |  |
| pedido_id | INTEGER | não | FK → pedidos.id |  |
| entregador_id | INTEGER | não | FK → usuarios.id |  |
| meio | VARCHAR(10) | não |  |  |
| criado_em | TIMESTAMP WITHOUT TIME ZONE | não |  |  |
