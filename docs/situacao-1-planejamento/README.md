# Situação 1 – Plano de projeto atualizado

Revisão (kaizen) da documentação feita no PIT I para a loja **Sweet Indulgence Cupcakes**: escopo, modelagem UML, IHC e projeto de dados, agora preparados para a execução.

## 1. Escopo revisado

**Problema:** a loja de cupcakes gourmet precisa de uma loja virtual para vender, receber pedidos, organizar entregas e se relacionar com os clientes. Na versão anterior do software, o cliente não foi ouvido e o sistema não resolveu a dor da loja.

**Solução:** uma aplicação web *mobile-first* (abre no navegador do celular como um app), com três perfis:

| Perfil | O que faz |
|---|---|
| Cliente | Vê a vitrine, filtra, favorita, monta o carrinho, aplica cupom, escolhe entrega/retirada, paga (cartão ou PIX), acompanha o pedido e avalia |
| Administrador | Gerencia catálogo e estoque, cupons, painel de pedidos, atribui entregadores, vê relatórios e avaliações |
| Entregador | Vê as entregas atribuídas, abre o endereço no GPS, liga/manda WhatsApp e marca como entregue |

### O que mudou em relação ao PIT I

| Item do PIT I | Decisão no PIT II | Motivo |
|---|---|---|
| "Aplicação mobile" | Aplicação **web responsiva** (mobile-first) | Um único código atende celular e computador, sem publicar em loja de apps. Mantém o layout do wireframe (barra inferior, cabeçalho fixo). |
| Classes `Cliente`, `Administrador`, `Entregador` separadas | Uma tabela `usuarios` com o campo `papel` | Os três tinham os mesmos atributos (nome, e-mail); separar criaria três logins e duplicação. |
| Classe `Promocao` (nome, desconto) | `Cupom` com código, percentual, validade e limite de usos | O US06 exige validade e limite de usos (RN#1), que não estavam no diagrama. |
| `Pedido` só com data, status e total | Subtotal, desconto, frete, total, método de entrega e de pagamento | Necessário para os critérios de aceitação de US06, US07 e US08. |
| — | Novas classes `Categoria`, `ZonaEntrega`, `Favorito`, `Avaliacao`, `Notificacao`, `RegistroContato` | Exigidas por US02, US07, US05, US10, US09 e US18, e não estavam no diagrama. |
| Notificação **push** (US09) | Notificações **dentro do app** (🔔), respeitando a preferência do cliente | Push nativo depende de app instalado; fica para a versão mobile nativa. |
| Pagamento com gateway certificado (US08) | **Gateway simulado** com as mesmas regras (cartão aprovado/recusado, PIX) | Gateway real exige conta comercial e chaves de produção. A troca afeta só `app/pagamento.py`. |
| Mapa com o entregador em tempo real | Link "Abrir no GPS" (Google Maps) para o entregador | Rastreamento em tempo real exige app nativo com localização em segundo plano. |
| Regra "remover produto" | Produto sai do cardápio (desativado), não é apagado | Preserva o histórico de pedidos e relatórios. |
| Estoque | Baixa ao registrar o pedido e devolução ao cancelar | Evita vender o mesmo cupcake duas vezes enquanto o PIX não é pago. |

### Fora do escopo desta entrega
Chat em tempo real entre entregador e cliente (US18 CA#2 — substituído por WhatsApp), assinatura do cliente na entrega (US17 CA#2, opcional), exportação do relatório em PDF (o CSV está implementado), upload de fotos (os produtos usam ilustrações vetoriais geradas pelo sistema).

## 2. Modelagem UML revisada

### 2.1 Diagrama de casos de uso

```mermaid
flowchart LR
  C([Cliente]) --- UC1[Ver vitrine e filtrar]
  C --- UC2[Ver nutricional e alérgenos]
  C --- UC3[Gerir carrinho]
  C --- UC4[Aplicar cupom]
  C --- UC5[Realizar pedido – CU01]
  C --- UC6[Acompanhar pedido]
  C --- UC7[Favoritar]
  C --- UC8[Avaliar]
  A([Administrador]) --- UA1[Gerir catálogo – CU02]
  A --- UA2[Controlar estoque]
  A --- UA3[Painel de pedidos]
  A --- UA4[Atribuir entregador]
  A --- UA5[Relatórios]
  A --- UA6[Gerir cupons]
  E([Entregador]) --- UE1[Ver entregas]
  E --- UE2[Contatar cliente]
  E --- UE3[Marcar como entregue]
  UC5 -. include .-> UP[Processar pagamento]
```

### 2.2 Diagrama de classes (persistência)

```mermaid
classDiagram
  class Usuario { +int id; +String nome; +String email; +String telefone; +String papel; +bool notificacoes_ativas; +definir_senha(); +ja_comprou() }
  class Endereco { +String rua; +String numero; +String bairro; +String cep }
  class Categoria { +String nome; +String slug }
  class Cupcake { +String nome; +Decimal preco; +int estoque; +int estoque_minimo; +int calorias; +String alergenos; +bool ativo; +vitrine(); +estoque_baixo(); +ajustar_estoque() }
  class Cupom { +String codigo; +int percentual; +Date validade; +int limite_usos; +int usos; +buscar_valido(); +desconto_sobre() }
  class ZonaEntrega { +String nome; +Decimal taxa; +int prazo_min }
  class Pedido { +String codigo; +String status; +String metodo_entrega; +String metodo_pagamento; +Decimal subtotal; +Decimal desconto; +Decimal frete; +Decimal total; +criar(); +mudar_status(); +atribuir_entregador(); +relatorio() }
  class ItemPedido { +int quantidade; +Decimal preco_unitario }
  class Favorito
  class Avaliacao { +int nota; +int nota_entrega; +String comentario }
  class Notificacao { +String mensagem; +bool lida }
  class RegistroContato { +String meio }
  Usuario "1" --> "*" Endereco
  Usuario "1" --> "*" Pedido : cliente
  Usuario "1" --> "*" Pedido : entregador
  Usuario "1" --> "*" Favorito
  Favorito "*" --> "1" Cupcake
  Categoria "1" --> "*" Cupcake
  Pedido "1" *-- "*" ItemPedido
  ItemPedido "*" --> "1" Cupcake
  Pedido "*" --> "0..1" Cupom
  Pedido "*" --> "0..1" ZonaEntrega
  Avaliacao "*" --> "1" Cupcake
  Avaliacao "*" --> "1" Pedido
  Notificacao "*" --> "1" Usuario
  RegistroContato "*" --> "1" Pedido
```

### 2.3 Diagrama de sequência – Realizar pedido (CU01)

```mermaid
sequenceDiagram
  actor Cliente
  participant V as View (checkout.html)
  participant C as Controller (pedidos.py)
  participant M as Model (Pedido)
  participant G as GatewaySimulado
  participant DB as PostgreSQL
  Cliente->>V: preenche entrega e pagamento
  V->>C: POST /checkout
  C->>M: Pedido.criar(carrinho, entrega, pagamento, cupom)
  M->>DB: confere estoque, cupom e zona
  alt cartão
    M->>G: cobrar_cartao()
    G-->>M: aprovado / recusado (CU01-B)
  else PIX
    M->>G: gerar_pix()
  end
  M->>DB: grava pedido, baixa estoque, notifica admin
  M-->>C: pedido
  C-->>V: redireciona para a confirmação
```

### 2.4 Diagrama de atividades – ciclo de vida do pedido

```mermaid
stateDiagram-v2
  [*] --> AguardandoPagamento: PIX
  [*] --> Pendente: cartão aprovado
  AguardandoPagamento --> Pendente: PIX confirmado
  AguardandoPagamento --> Cancelado
  Pendente --> EmPreparacao
  Pendente --> Cancelado
  EmPreparacao --> SaiuParaEntrega: entrega + entregador atribuído
  EmPreparacao --> ProntoRetirada: retirada
  EmPreparacao --> Cancelado
  SaiuParaEntrega --> Entregue: entregador confirma
  ProntoRetirada --> Entregue
  Cancelado --> [*]: estoque devolvido
  Entregue --> [*]: cliente pode avaliar
```

## 3. IHC – telas, mensagens e protótipo

As telas seguem o wireframe do PIT I: cabeçalho fixo com logotipo e sacola, busca, filtros de categoria em círculo, grade de produtos com coração, e barra de navegação inferior (Início, Favoritos, Carrinho, Pedidos, Perfil) no celular. No computador, a barra inferior vira links no cabeçalho.

Mapa de telas:

```mermaid
flowchart TD
  V[Vitrine] --> D[Detalhe do cupcake]
  V --> F[Favoritos]
  D --> CA[Carrinho]
  CA --> L{Logado?}
  L -- não --> E[Entrar / Cadastro] --> CK
  L -- sim --> CK[Checkout]
  CK --> CF[Confirmação / PIX] --> AC[Acompanhar pedido] --> AV[Avaliar]
  AD[Painel admin] --> PR[Produtos e estoque] --> PF[Formulário do produto]
  AD --> CU[Cupons]
  AD --> RE[Relatórios]
  EN[Entregas] --> ED[Detalhe da entrega]
```

Mensagens de erro (todas em português, perto da ação que as causou):

| Situação | Mensagem |
|---|---|
| Quantidade maior que o estoque | "Só temos 4 unidade(s) de Caramelo Salgado em estoque." |
| Cupom inexistente / vencido / esgotado | "Cupom inválido." / "Este cupom expirou." / "Este cupom atingiu o limite de usos." |
| Cartão recusado (CU01-B) | "Pagamento recusado pela operadora. Tente outro cartão ou pague com PIX." |
| Entrega sem bairro ou endereço | "Escolha o bairro/zona de entrega." / "Informe o endereço de entrega." |
| Produto com dados inválidos (CU02-A) | Lista de campos a corrigir, sem perder o que foi digitado |
| Remoção sem confirmação (CU02-B) | "Remoção cancelada: digite o nome exato do cupcake para confirmar." |
| Entregador sem confirmar com o cliente | "Confirme com o cliente antes de marcar como entregue." |
| Área restrita | Página "Acesso negado" (403) |

Os prints das telas implementadas estão em [`../situacao-3-testes/evidencias/telas/`](../situacao-3-testes/evidencias/telas/).

## 4. Projeto de dados

- **Conceitual:** entidades e relacionamentos do diagrama de classes (seção 2.2).
- **Lógico (normalizado até a 3FN):**
  - Endereços ficam em tabela própria (um cliente tem vários).
  - Itens do pedido ficam separados do pedido (1:N).
  - O preço unitário fica em `itens_pedido`, porque o preço do cupcake pode mudar depois da compra. Por isso não é redundância.
  - `favoritos` usa chave composta (usuário, cupcake) para impedir duplicidade.
  - Categorias e zonas de entrega são tabelas de domínio.
- **Físico:** PostgreSQL 16 (SGBD popular e gratuito), script em [`schema-postgresql.sql`](schema-postgresql.sql). Em desenvolvimento, o mesmo modelo roda em SQLite. Restrições de integridade no banco: chaves estrangeiras, `UNIQUE`, `CHECK (preco > 0)`, `CHECK (estoque >= 0)`, `CHECK (nota BETWEEN 1 AND 5)` e `CHECK (percentual BETWEEN 1 AND 90)`.
- **Dicionário de dados:** [`dicionario-de-dados.md`](dicionario-de-dados.md).
