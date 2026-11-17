# Testes simulados com personas (agentes)

Antes da validação com os colegas, o sistema foi percorrido por **5 agentes simulados**, cada um no papel de um tipo de usuário (persona). **Não são colegas reais**: são testes exploratórios simulados, usados para levantar pontos de melhoria. A validação com 5 colegas de verdade é registrada à parte (seção 3 do [laudo](README.md#3-validação-com-5-colegas)).

O relato de cada agente está como foi registrado no documento da atividade. A coluna **Análise** diz o que o sistema faz hoje em relação a cada ponto.

## Agente 1 – persona "Ana Clara" (cliente)

| Campo | Relato |
|---|---|
| O que testou e funcionou | Acessou a página inicial, consultou os cupcakes, abriu os detalhes dos produtos, adicionou itens ao carrinho e alterou as quantidades. O fluxo de navegação e a atualização do subtotal funcionaram corretamente. |
| O que não funcionou / o que corrigir | Ao reduzir a quantidade de um item até zero, a atualização do carrinho não ficou clara. Melhorar o aviso de remoção e confirmar visualmente quando o item for excluído. |
| Não testado | Pagamento com cartão em produção e gateway real (o projeto usa gateway simulado). |
| **Análise** | Procede em parte: ao chegar a zero o item é removido (`Cart#set`), mas sem uma mensagem própria. **Melhoria a fazer:** aviso "Item removido do carrinho". |

## Agente 2 – persona "Bruno Martins" (cliente)

| Campo | Relato |
|---|---|
| O que testou e funcionou | Cadastro e login, favoritos e área de pedidos. As páginas protegidas pediram autenticação e, após entrar, a navegação continuou. |
| O que não funcionou / o que corrigir | Ao favoritar sem estar autenticado, apresentar uma mensagem explicando que é preciso entrar na conta e manter o redirecionamento para a página pretendida após o login. |
| Não testado | Notificações push no celular (as notificações são exibidas dentro do app). |
| **Análise** | **Já atendido:** o sistema mostra "Entre na sua conta para continuar." e volta para a página de origem depois do login (correção R2 e teste `visitante precisa entrar para favoritar`). |

## Agente 3 – persona "Camila Souza" (administradora)

| Campo | Relato |
|---|---|
| O que testou e funcionou | Painel administrativo, cadastro e consulta de cupcakes, categorias, estoque e pedidos. As alterações foram salvas. |
| O que não funcionou / o que corrigir | Com campos obrigatórios vazios, algumas mensagens poderiam ser mais específicas. Revisar os textos de validação de cada campo. |
| Não testado | Pagamento externo e relatório em PDF (não implementado; o relatório é em CSV). |
| **Análise** | **Já atendido no cadastro de cupcake:** cada campo tem mensagem própria ("Informe o nome do cupcake.", "Escolha uma categoria.", "O preço precisa ser maior que zero." etc.; correção R6). **Melhoria a fazer:** revisar os demais formulários do admin (cupons) com o mesmo critério. |

## Agente 4 – persona "Diego Ferreira" (entregador)

| Campo | Relato |
|---|---|
| O que testou e funcionou | Área de entregas, pedidos atribuídos e etapas do pedido até a conclusão, com os dados do cliente e do endereço. |
| O que não funcionou / o que corrigir | Destacar com mais evidência o endereço e o tipo de recebimento (entrega ou retirada) na tela do pedido. |
| Não testado | Notificações por aplicativo instalado e localização por GPS. |
| **Análise** | O relato tem um engano: o **GPS existe** (botão "Abrir no GPS", US16) e aparece no vídeo. O tipo de recebimento é sempre **entrega** na área do entregador, porque pedidos de retirada não são atribuídos a entregadores. **Melhoria a fazer:** endereço em destaque na tela do pedido. |

## Agente 5 – persona "Fernanda Lima" (cliente no celular)

| Campo | Relato |
|---|---|
| O que testou e funcionou | Catálogo, carrinho, finalização e acompanhamento pelo navegador do celular. As telas se adaptaram à largura do aparelho. |
| O que não funcionou / o que corrigir | Em telas menores, textos e botões de formulários poderiam ter mais espaçamento para o toque. Revisar a responsividade dos formulários em diferentes tamanhos de tela. |
| Não testado | Exportação em PDF (o sistema exporta CSV) e compra com cobrança real. |
| **Análise** | **Melhoria a fazer:** conferir os formulários em 360 px e 390 px e aumentar a área de toque onde estiver abaixo de 44 px. |

## Resumo

| Ponto | Situação |
|---|---|
| Aviso ao favoritar sem login (Agente 2) | ✅ já existia (R2) |
| Mensagens por campo no cadastro de cupcake (Agente 3) | ✅ já existia (R6) |
| GPS do entregador (Agente 4) | ✅ já existia (US16); relato equivocado |
| Aviso ao remover item zerando a quantidade (Agente 1) | ⏳ melhoria a fazer |
| Mensagens dos outros formulários do admin (Agente 3) | ⏳ melhoria a fazer |
| Endereço em destaque para o entregador (Agente 4) | ⏳ melhoria a fazer |
| Espaçamento de toque nos formulários no celular (Agente 5) | ⏳ melhoria a fazer |
