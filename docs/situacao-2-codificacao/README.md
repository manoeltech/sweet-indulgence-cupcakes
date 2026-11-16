# Situação 2 – Codificação

## Tecnologias

| Camada | Escolha |
|---|---|
| Front-end | HTML5, CSS3 e JavaScript puro (templates Jinja2 renderizados no servidor) |
| Back-end | Python 3.10+ com Flask 3 |
| Padrão de projeto | **MVC** |
| Banco de dados | PostgreSQL em produção; SQLite em desenvolvimento e testes (via SQLAlchemy) |
| Testes | pytest (testes unitários e de integração) |
| Servidor de produção | Gunicorn |
| Modo de codificação | Tradicional |

## Arquitetura MVC

```
app/
├── models/          ← MODEL: entidades + regras de negócio (estoque, cupom, frete, status)
│   ├── usuario.py       Usuario, Endereco
│   ├── catalogo.py      Categoria, Cupcake, Favorito, Avaliacao
│   └── pedido.py        Cupom, ZonaEntrega, Pedido, ItemPedido, Notificacao, RegistroContato
├── controllers/     ← CONTROLLER: recebe a requisição, chama o model, escolhe a view
│   ├── loja.py          vitrine, detalhe, favoritos
│   ├── carrinho.py      carrinho e cupom
│   ├── pedidos.py       checkout, confirmação, acompanhamento, avaliação
│   ├── auth.py          cadastro, login, perfil, notificações
│   ├── admin.py         painel, produtos, estoque, cupons, relatórios
│   └── entregador.py    entregas, contato, marcar entregue
├── templates/       ← VIEW: páginas HTML (Jinja2)
├── static/css/      ← estilos (mobile-first)
├── pagamento.py     ← gateway de pagamento simulado (isolado para troca futura)
├── fuso.py          ← conversão UTC ↔ horário de Brasília
└── seed.py          ← dados de demonstração
tests/               ← pytest
```

Regras de negócio ficam **no model**, não no controller. Exemplos:
- `Pedido.criar()` confere o estoque, o cupom e a zona, cobra, baixa o estoque e notifica.
- `Pedido.mudar_status()` só aceita transições válidas e devolve o estoque ao cancelar.

Com isso, os testes de regra rodam sem navegador.

### Segurança e tratamento de erros
- Senhas com hash (`werkzeug.security`, PBKDF2). Nunca são gravadas em texto.
- Token CSRF em todos os formulários `POST`.
- Cookie de sessão `HttpOnly` e `SameSite=Lax`.
- Acesso por papel: cliente, admin e entregador. Um cliente só vê os próprios pedidos; um entregador só vê os pedidos atribuídos a ele.
- O número do cartão nunca é gravado; só os 4 últimos dígitos.
- Os redirecionamentos depois do login só aceitam caminhos internos, o que evita *open redirect*.
- Erros de regra viram mensagens amigáveis (`RegraNegocioErro`).
- Páginas próprias para 400, 403, 404 e 500.

### Rastreabilidade: histórias de usuário → código

| História | Onde está |
|---|---|
| US01 Vitrine | `Cupcake.vitrine()`, `loja.vitrine`, `loja/vitrine.html` |
| US02 Filtro por categoria | `Cupcake.vitrine(categoria_slug)`, filtros em círculo |
| US03 Nutricional e alérgenos | `loja/detalhe.html` |
| US04 Carrinho | `controllers/carrinho.py` (limite = estoque) |
| US05 Favoritos | `Favorito`, `loja.alternar_favorito`, `/favoritos` |
| US06 Cupons | `Cupom.buscar_valido()`, `/carrinho/cupom`, `/admin/cupons` |
| US07 Entrega/retirada | `ZonaEntrega`, `loja/checkout.html` |
| US08 Pagamento | `pagamento.GatewaySimulado` (crédito, débito, PIX) |
| US09 Notificações | `Notificacao`, 🔔 no cabeçalho, preferência no perfil |
| US10 Avaliação | `Avaliacao`, `pedidos.avaliar` (só pedido entregue) |
| US11 Catálogo | `admin.produto`, `admin.remover_produto` |
| US12 Estoque | `Cupcake.ajustar_estoque()`, `Cupcake.estoque_baixo()`, alerta no painel |
| US13 Painel de pedidos | `admin.dashboard` (filtros por status) |
| US14 Atribuir entregador | `Pedido.atribuir_entregador()` (máx. 3 simultâneas) |
| US15 Relatórios | `Pedido.relatorio()`, `/admin/relatorios` (+ CSV) |
| US16 Detalhes da entrega | `entregador.detalhe` (abrir no GPS) |
| US17 Marcar entregue | `entregador.marcar_entregue` (exige confirmação) |
| US18 Contatar cliente | `entregador.contato` (ligação/WhatsApp, registrado para auditoria) |

## Manual de uso

### Rodar no computador
```bash
git clone https://github.com/manoeltech/sweet-indulgence-cupcakes.git
cd sweet-indulgence-cupcakes
python -m venv .venv && source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
flask --app wsgi popular        # cria as tabelas e os dados de demonstração
flask --app wsgi run            # abre em http://127.0.0.1:5000
pytest                          # roda os testes
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
| PIX | Gera "copia e cola"; o botão "Já paguei" simula a confirmação do banco |

Cupons: `BEMVINDO10` (10%, válido) e `VERAO2025` (expirado, para testar o erro).

### Passo a passo
1. **Cliente:**
   1. Escolha cupcakes na vitrine. Dá para filtrar por categoria e buscar pelo nome.
   2. Adicione ao carrinho e aplique um cupom.
   3. Clique em **Continuar para o pagamento**.
   4. Escolha entre entrega (com o bairro) ou retirada, depois a forma de pagamento, e finalize.
   5. Acompanhe o pedido em **Pedidos** e as notificações no 🔔.
   6. Depois da entrega, avalie o pedido.
2. **Administrador:**
   1. No **Painel**, mova o pedido para **Em preparação** e atribua um entregador.
   2. Clique em **Saiu para entrega**.
   3. Em **Produtos e estoque**, cadastre, edite, reponha o estoque ou remova cupcakes.
   4. Em **Relatórios**, veja as vendas e exporte o CSV.
3. **Entregador:**
   1. Em **Minhas entregas**, abra o pedido.
   2. Use **Abrir no GPS**, **Ligar** ou **WhatsApp**.
   3. Confirme com o cliente e clique em **Marcar como entregue**.

## Publicação (Render + PostgreSQL)
O arquivo [`render.yaml`](../../render.yaml) descreve a aplicação web e o banco PostgreSQL gratuitos. No Render: **New → Blueprint →** escolha este repositório. Na primeira subida, o comando de build cria as tabelas e popula os dados de demonstração.
