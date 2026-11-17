# Situação 3 – Testes, laudo de qualidade e validação com usuários

## 1. Plano de testes

| Nível | Ferramenta | O que cobre |
|---|---|---|
| Unitário (verificação) | Minitest – `test/models/` | Regras de negócio: vitrine, estoque, cupom (válido, inválido, expirado, esgotado), carrinho, cálculo de totais, pagamento (Luhn, recusado, vencido), PIX, transições de status, notificações, limite de entregas, avaliações, relatório e fuso horário |
| Integração (verificação) | Minitest + `ActionDispatch::IntegrationTest` – `test/controllers/` | Front-end + back-end + banco: vitrine e filtros, detalhe, cadastro/login, perfil, favoritos, carrinho e cupom, checkout, cartão recusado, PIX, acompanhamento, avaliação, painel do admin, produtos, estoque, cupons, CSV, área do entregador e permissões por papel |
| Qualidade e segurança | RuboCop (estilo Rails Omakase) e Brakeman (análise de segurança) | Padrão de código e vulnerabilidades conhecidas (SQL injection, XSS, CSRF, redirecionamentos…) |
| Sistema / aceitação (validação) | Navegador real (Chromium) usado como cliente, admin e entregador, no celular (390 px) e no computador (1366 px) | Os critérios de aceitação das histórias, com print de cada passo. Em cada tela também conferi se a página não passava da largura da tela e se havia erro de JavaScript |
| Validação com usuários | 5 colegas de curso, com o [formulário de teste](formulario-teste-colegas.md) | Uso livre, como um cliente de verdade |

Os testes foram escritos junto com cada tarefa, na mesma branch, e cada Pull Request só foi aberto com todos os testes passando.

Como rodar: `bin/rails test` (testes), `bin/rubocop` (estilo) e `bin/brakeman` (segurança).

**Resultado atual: 101 testes, 408 verificações, 0 falhas** ([saída completa](evidencias/minitest-execucao-final.txt)). RuboCop e Brakeman sem apontamentos ([saída](evidencias/qualidade-rubocop-brakeman.txt)).

## 2. Laudo de qualidade

Defeitos encontrados durante a verificação da versão Rails, com causa, correção e evidência. Cada correção tem um commit próprio na branch indicada.

| # | Onde apareceu | Defeito | Causa | Correção | Evidência | Branch |
|---|---|---|---|---|---|---|
| R1 | 1ª execução dos testes de modelo (17 falhas) | Toda cobrança com cartão dava `NoMethodError` | Ruby não compara Arrays com < (`[ano, mês] < [ano, mês]`) | Compara o último dia do mês da validade | [`minitest-execucao-1.txt`](evidencias/minitest-execucao-1.txt) (17 falhas) | `feature/modelos-e-banco` |
| R2 | Teste de integração dos favoritos | Visitante que tentava favoritar voltava, depois do login, para a URL do formulário (só POST) e caía em 404 | O login guardava a URL de qualquer requisição como página de volta | Só guarda a volta de páginas GET | teste `visitante precisa entrar para favoritar` | `feature/favoritos` |
| R3 | Teste manual no navegador (celular, 390 px) | A linha do item no carrinho passava da largura da tela (página com 471 px) e o botão Remover do cupom ficava fora do lugar | Os botões do Rails (`button_to`) ficam dentro de um `<form>`, que quebrava o layout em flex | Forms dos botões com `display: contents` e linha do item com quebra no celular | largura da página 471 → 390 px; print [`05`](evidencias/telas/05-carrinho-com-cupom.png) | `feature/tela-carrinho` |
| R4 | Teste manual no navegador (admin) | O painel mostrava "Saiu para entrega" para pedido de retirada (e "Pronto para retirada" para entrega); o clique só dava erro | A lista de próximos passos não levava em conta entrega/retirada | `next_statuses` filtra pelo tipo de recebimento; teste novo | teste `próximos passos dependem de entrega ou retirada`; print [`10`](evidencias/telas/10-admin-pedido-saiu-para-entrega.png) | `feature/painel-admin` |
| R5 | Teste manual no navegador (admin, celular) | Menu de atalhos do admin aparecia no celular, duplicando a barra inferior | Regra `.admin-nav` declarada depois de `.so-desktop` vencia pela ordem no CSS | Regra específica no media query do celular | conferido no celular (390 px) | `feature/painel-admin` |
| R6 | Teste manual no navegador (admin, cadastro de cupcake) | Sem categoria, o formulário mostrava só "é obrigatório(a)", sem dizer o quê | Mensagem padrão do `belongs_to`, exibida sem o nome do campo | Validação própria "Escolha uma categoria."; teste atualizado | teste `dados inválidos mostram os erros…`; print [`12`](evidencias/telas/12-admin-produto-dados-invalidos.png) | `feature/admin-produtos-e-estoque` |
| R7 | Teste manual no navegador (tela de cupons e pedidos) | "Entregue" aparecia rosa em vez de verde e "Cancelado"/"Aguardando pagamento" sem a cor de alerta | O CSS veio da versão Flask com os status em português (`.status.entregue`); no Rails os status são `delivered`, `canceled` e `awaiting_payment` | Classes do CSS renomeadas; classe `.ok` para o cupom aplicado | print [`17`](evidencias/telas/17-entregador-entregue.png) e [`18`](evidencias/telas/18-avaliacao-enviada.png) | `feature/admin-cupons-e-relatorios` |
| R8 | Teste manual no navegador (relatório no celular) | Relatório com 597 px numa tela de 390 px; login, cadastro e formulários do admin sem a largura máxima planejada | O `form_with` do Rails ignora a opção `style:` (precisa ir dentro de `html: {}`), em 10 formulários | Estilos movidos para `html: { style: }`; teste de regressão no login | largura 597 → 390 px; teste `formulário de login mantém a largura máxima`; print [`22`](evidencias/telas/22-admin-relatorio.png) | `feature/admin-cupons-e-relatorios` |
| R9 | Análise de segurança (Brakeman) | Aviso "HTTP verb confusion": requisição HEAD é roteada como GET, mas `request.get?` é falso | A correção do R2 usava só `request.get?` | Considera GET e HEAD | [`qualidade-rubocop-brakeman.txt`](evidencias/qualidade-rubocop-brakeman.txt) (antes e depois) | `docs/documentacao-rails` |
| R10 | Teste manual no site publicado (Render), como entregador | O entregador recebia a notificação "Você recebeu o pedido para entregar", mas "Minhas entregas" aparecia vazia | A lista só mostrava pedidos que já tinham saído para entrega; a notificação chega antes, quando o admin atribui o entregador | A lista mostra também os pedidos atribuídos ainda na loja, como "Em preparação", sem abrir para entregar; só os que saíram abrem; teste novo | teste `pedido atribuído e ainda em preparação aparece na lista, mas só abre depois de sair` | `feature/entregador-ve-pedidos-em-preparacao` |

Observação de ambiente (não é defeito do sistema): o navegador de testes do servidor Linux não tinha fonte de emoji, e os ícones apareciam como quadrados. Celulares, Windows e macOS têm a fonte; para os prints foi usada a fonte livre Noto Color Emoji. As datas nos campos de data aparecem no formato do idioma do navegador.

### Histórico: protótipo em Flask

Antes do Rails, o sistema foi prototipado em Python/Flask (tag [`v1-flask`](https://github.com/manoeltech/sweet-indulgence-cupcakes/tree/v1-flask)). Os defeitos encontrados naquela versão orientaram a versão Rails: o D5 (cupom perdido no login) e o D6 (fuso horário) já foram cobertos por testes desde o início.

| # | Onde apareceu | Defeito | Causa | Correção | Evidência |
|---|---|---|---|---|---|
| D1 | 1ª execução do pytest (18 falhas, 24 aprovados) | Pedidos sem cupom ou sem frete davam erro (`TypeError: conversion from NoneType to Decimal`) e não eram gravados | O valor padrão das colunas `desconto` e `frete` só é aplicado quando o registro vai ao banco; antes disso o valor era `None` | `Pedido` passou a nascer com `desconto` e `frete` iguais a zero | [`pytest-execucao-1.txt`](evidencias/historico-flask/pytest-execucao-1.txt); testes `test_retirada_sem_frete`, `test_pix_aguarda_e_confirma` |
| D2 | 1ª execução do pytest (aviso `SAWarning`) | Um pedido ainda incompleto entrava na sessão do banco ao ser ligado ao cliente; se a validação falhasse depois, poderia ser gravado pela metade | *Autoflush* do SQLAlchemy | Pedido montado dentro de `no_autoflush` e ligado ao cliente só depois de todas as validações | `test_pagamento_recusado_nao_grava_pedido_nem_mexe_no_estoque` |
| D3 | 1ª execução do pytest (testes sem contexto) | 5 testes de model rodavam sem a aplicação carregada | Erro no próprio teste (*fixture* não aplicada) | *Fixture* `app` passou a valer para todos os testes | `pytest-execucao-1.txt` (erros "Working outside of application context") |
| D4 | 2ª execução do pytest (2 falhas) | Depois de trocar de conta no mesmo navegador, o sistema ainda reconhecia o usuário anterior em algumas telas | O usuário logado ficava em cache sem conferir quem estava na sessão | O cache passou a guardar o id da sessão e é refeito quando ele muda | `test_cliente_nao_ve_pedido_de_outro`, `test_fluxo_admin_entregador_avaliacao` |
| D5 | Teste manual no navegador (cliente no celular) | O cupom aplicado no carrinho **sumia** depois que o cliente entrava na conta para finalizar a compra | O login limpava a sessão e só guardava o carrinho | O login passou a manter carrinho **e** cupom; teste novo criado | `test_cupom_aplicado_antes_do_login_continua_depois`; print no Rails, coberto desde o início pelo teste `carrinho do visitante continua depois do login` |
| D6 | Teste manual no navegador (admin) | Horários dos pedidos apareciam 3 horas adiantados (21:34 em vez de 18:34) e "Vendas de hoje" e relatórios cortavam o dia no horário errado | O banco guarda UTC e as telas mostravam UTC | Conversão para o horário de Brasília (`app/fuso.py`) nas telas, no painel e no relatório | `test_horario_e_limites_no_fuso_de_brasilia`; no Rails, `config.time_zone = "Brasilia"` e o teste `relatório usa o dia no horário de Brasília` |
| D7 | Teste manual no navegador | Conteúdo das páginas colado no cabeçalho, sem margem | Regra CSS `main` perdia para a classe `.wrap` (especificidade) | Regra trocada para `main.wrap` | Prints da pasta `telas/` |

### Situação de cada história de usuário

| História | Situação | Observação |
|---|---|---|
| US01–US07, US10–US17 | ✅ Implementada e testada | — |
| US08 Pagamento | ✅ com gateway **simulado** | Gateway real exige conta comercial; a troca fica isolada em `app/models/simulated_gateway.rb` |
| US09 Notificações | ✅ dentro do app | Push nativo fica para a versão mobile |
| US15 Relatórios | ✅ CSV | Exportação em PDF não implementada |
| US18 Contatar cliente | ✅ ligação e WhatsApp, com registro | Chat próprio não implementado |

## 3. Validação com 5 colegas

Cada colega recebe o link da aplicação e o [formulário de teste](formulario-teste-colegas.md) e testa como um cliente de verdade. As respostas e os prints de erro vão para a pasta `validacao-colegas/`. Cada correção sugerida entra neste laudo no mesmo formato acima, numa branch própria.

Antes disso, o sistema foi percorrido por 5 agentes simulados com personas (cliente, cliente no celular, administradora e entregador). **Não são colegas reais**; os relatos e a análise de cada ponto estão em [`testes-com-personas.md`](testes-com-personas.md).

## 4. Evidências

- [`evidencias/telas/`](evidencias/telas/): 24 prints do passo a passo como cliente (celular), administrador (computador) e entregador (celular), tirados da versão Rails.
- [`evidencias/minitest-execucao-1.txt`](evidencias/minitest-execucao-1.txt): primeira execução dos testes de modelo, com as 17 falhas do defeito R1.
- [`evidencias/minitest-execucao-final.txt`](evidencias/minitest-execucao-final.txt): execução final, com o nome de cada teste.
- [`evidencias/qualidade-rubocop-brakeman.txt`](evidencias/qualidade-rubocop-brakeman.txt): RuboCop e Brakeman, antes e depois do R9.
- [`evidencias/historico-flask/`](evidencias/historico-flask/): saídas do pytest do protótipo em Flask.
