# Situação 3 – Testes, laudo de qualidade e validação com usuários

## 1. Plano de testes

| Nível | Ferramenta | O que cobre |
|---|---|---|
| Unitário (verificação) | pytest – `tests/test_models.py` | Regras de negócio: vitrine, cupom (válido, inválido, expirado, esgotado), cálculo de totais, estoque, pagamento (Luhn, recusado, vencido), PIX, transições de status, notificações, limite de entregas, relatório, fuso horário |
| Integração (verificação) | pytest + cliente de teste Flask – `tests/test_rotas.py` | Front-end + back-end + banco: vitrine e filtros, detalhe, cadastro/login, carrinho, cupom, checkout, cartão recusado, favoritos, CRUD de produtos, fluxo admin → entregador → avaliação, permissões, CSV, CSRF |
| Sistema / aceitação (validação) | Navegador real (Chromium) usado como cliente, admin e entregador, no celular (390 px) e no computador (1366 px) | Os critérios de aceitação das histórias, com print de cada passo |
| Validação com usuários | 5 colegas de curso, com o [formulário de teste](formulario-teste-colegas.md) | Uso livre, como um cliente de verdade |

Como rodar os testes automatizados: `pytest` na raiz do projeto.

**Resultado atual: 44 testes, 44 aprovados** ([saída completa](evidencias/pytest-execucao-final.txt)).

## 2. Laudo de qualidade

Defeitos encontrados durante a verificação, com causa, correção e evidência. Nenhum foi escondido: eles fazem parte do aprendizado pedido no desafio.

| # | Onde apareceu | Defeito | Causa | Correção | Evidência |
|---|---|---|---|---|---|
| D1 | 1ª execução do pytest (18 falhas, 24 aprovados) | Pedidos sem cupom ou sem frete davam erro (`TypeError: conversion from NoneType to Decimal`) e não eram gravados | O valor padrão das colunas `desconto` e `frete` só é aplicado quando o registro vai ao banco; antes disso o valor era `None` | `Pedido` passou a nascer com `desconto` e `frete` iguais a zero | [`pytest-execucao-1.txt`](evidencias/pytest-execucao-1.txt); testes `test_retirada_sem_frete`, `test_pix_aguarda_e_confirma` |
| D2 | 1ª execução do pytest (aviso `SAWarning`) | Um pedido ainda incompleto entrava na sessão do banco ao ser ligado ao cliente; se a validação falhasse depois, poderia ser gravado pela metade | *Autoflush* do SQLAlchemy | Pedido montado dentro de `no_autoflush` e ligado ao cliente só depois de todas as validações | `test_pagamento_recusado_nao_grava_pedido_nem_mexe_no_estoque` |
| D3 | 1ª execução do pytest (testes sem contexto) | 5 testes de model rodavam sem a aplicação carregada | Erro no próprio teste (*fixture* não aplicada) | *Fixture* `app` passou a valer para todos os testes | `pytest-execucao-1.txt` (erros "Working outside of application context") |
| D4 | 2ª execução do pytest (2 falhas) | Depois de trocar de conta no mesmo navegador, o sistema ainda reconhecia o usuário anterior em algumas telas | O usuário logado ficava em cache sem conferir quem estava na sessão | O cache passou a guardar o id da sessão e é refeito quando ele muda | `test_cliente_nao_ve_pedido_de_outro`, `test_fluxo_admin_entregador_avaliacao` |
| D5 | Teste manual no navegador (cliente no celular) | O cupom aplicado no carrinho **sumia** depois que o cliente entrava na conta para finalizar a compra | O login limpava a sessão e só guardava o carrinho | O login passou a manter carrinho **e** cupom; teste novo criado | `test_cupom_aplicado_antes_do_login_continua_depois`; print [`07-pagamento-recusado.png`](evidencias/telas/07-pagamento-recusado.png) mostra o cupom no resumo após o login |
| D6 | Teste manual no navegador (admin) | Horários dos pedidos apareciam 3 horas adiantados (21:34 em vez de 18:34) e "Vendas de hoje" e relatórios cortavam o dia no horário errado | O banco guarda UTC e as telas mostravam UTC | Conversão para o horário de Brasília (`app/fuso.py`) nas telas, no painel e no relatório | `test_horario_e_limites_no_fuso_de_brasilia`; print [`13-acompanhar-saiu-para-entrega.png`](evidencias/telas/13-acompanhar-saiu-para-entrega.png) |
| D7 | Teste manual no navegador | Conteúdo das páginas colado no cabeçalho, sem margem | Regra CSS `main` perdia para a classe `.wrap` (especificidade) | Regra trocada para `main.wrap` | Prints da pasta `telas/` |

Observação de ambiente (não é defeito do sistema): o navegador de testes do servidor Linux não tinha fonte de emoji, e os ícones apareciam como quadrados. Celulares, Windows e macOS têm a fonte; para os prints foi usada a fonte livre Noto Color Emoji.

### Situação de cada história de usuário

| História | Situação | Observação |
|---|---|---|
| US01–US07, US10–US17 | ✅ Implementada e testada | — |
| US08 Pagamento | ✅ com gateway **simulado** | Gateway real exige conta comercial; troca isolada em `app/pagamento.py` |
| US09 Notificações | ✅ dentro do app | Push nativo fica para a versão mobile |
| US15 Relatórios | ✅ CSV | Exportação em PDF não implementada |
| US18 Contatar cliente | ✅ ligação e WhatsApp, com registro | Chat próprio não implementado |

## 3. Validação com 5 colegas

Cada colega recebe o link da aplicação e o [formulário de teste](formulario-teste-colegas.md) e testa como um cliente de verdade. As respostas e prints de erro vão para a pasta `validacao-colegas/` e as correções entram neste laudo, seguindo o mesmo formato acima.

## 4. Evidências

- [`evidencias/telas/`](evidencias/telas/) – 24 prints do passo a passo como cliente (celular), administrador (computador) e entregador (celular).
- [`evidencias/pytest-execucao-1.txt`](evidencias/pytest-execucao-1.txt) – primeira execução dos testes, com as falhas D1–D3.
- [`evidencias/pytest-execucao-final.txt`](evidencias/pytest-execucao-final.txt) – execução final, todos aprovados.
