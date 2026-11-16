-- Projeto físico do banco (PostgreSQL), gerado a partir dos models SQLAlchemy

CREATE TABLE categorias (
	id SERIAL NOT NULL, 
	nome VARCHAR(60) NOT NULL, 
	slug VARCHAR(60) NOT NULL, 
	PRIMARY KEY (id), 
	UNIQUE (nome), 
	UNIQUE (slug)
);

CREATE TABLE cupons (
	id SERIAL NOT NULL, 
	codigo VARCHAR(30) NOT NULL, 
	descricao VARCHAR(120) NOT NULL, 
	percentual INTEGER NOT NULL, 
	validade DATE NOT NULL, 
	limite_usos INTEGER, 
	usos INTEGER NOT NULL, 
	ativo BOOLEAN NOT NULL, 
	PRIMARY KEY (id), 
	CONSTRAINT ck_cupom_percentual CHECK (percentual BETWEEN 1 AND 90), 
	UNIQUE (codigo)
);

CREATE TABLE usuarios (
	id SERIAL NOT NULL, 
	nome VARCHAR(120) NOT NULL, 
	email VARCHAR(160) NOT NULL, 
	telefone VARCHAR(20), 
	senha_hash VARCHAR(255) NOT NULL, 
	papel VARCHAR(20) NOT NULL, 
	notificacoes_ativas BOOLEAN NOT NULL, 
	criado_em TIMESTAMP WITHOUT TIME ZONE NOT NULL, 
	PRIMARY KEY (id)
);

CREATE UNIQUE INDEX ix_usuarios_email ON usuarios (email);

CREATE TABLE zonas_entrega (
	id SERIAL NOT NULL, 
	nome VARCHAR(80) NOT NULL, 
	taxa NUMERIC(6, 2) NOT NULL, 
	prazo_min INTEGER NOT NULL, 
	PRIMARY KEY (id), 
	UNIQUE (nome)
);

CREATE TABLE cupcakes (
	id SERIAL NOT NULL, 
	categoria_id INTEGER NOT NULL, 
	nome VARCHAR(80) NOT NULL, 
	descricao TEXT NOT NULL, 
	ingredientes TEXT NOT NULL, 
	preco NUMERIC(8, 2) NOT NULL, 
	estoque INTEGER NOT NULL, 
	estoque_minimo INTEGER NOT NULL, 
	calorias INTEGER, 
	gorduras_g NUMERIC(5, 1), 
	acucares_g NUMERIC(5, 1), 
	alergenos VARCHAR(200) NOT NULL, 
	cor VARCHAR(7) NOT NULL, 
	ativo BOOLEAN NOT NULL, 
	criado_em TIMESTAMP WITHOUT TIME ZONE NOT NULL, 
	PRIMARY KEY (id), 
	CONSTRAINT ck_cupcake_preco_positivo CHECK (preco > 0), 
	CONSTRAINT ck_cupcake_estoque_nao_negativo CHECK (estoque >= 0), 
	FOREIGN KEY(categoria_id) REFERENCES categorias (id)
);

CREATE TABLE enderecos (
	id SERIAL NOT NULL, 
	usuario_id INTEGER NOT NULL, 
	rua VARCHAR(160) NOT NULL, 
	numero VARCHAR(10) NOT NULL, 
	bairro VARCHAR(80) NOT NULL, 
	cep VARCHAR(9) NOT NULL, 
	PRIMARY KEY (id), 
	FOREIGN KEY(usuario_id) REFERENCES usuarios (id)
);

CREATE TABLE pedidos (
	id SERIAL NOT NULL, 
	codigo VARCHAR(12) NOT NULL, 
	cliente_id INTEGER NOT NULL, 
	entregador_id INTEGER, 
	cupom_id INTEGER, 
	zona_id INTEGER, 
	status VARCHAR(30) NOT NULL, 
	metodo_entrega VARCHAR(10) NOT NULL, 
	endereco_entrega VARCHAR(255), 
	metodo_pagamento VARCHAR(10) NOT NULL, 
	cartao_final VARCHAR(4), 
	pix_copia_cola VARCHAR(255), 
	subtotal NUMERIC(10, 2) NOT NULL, 
	desconto NUMERIC(10, 2) NOT NULL, 
	frete NUMERIC(10, 2) NOT NULL, 
	total NUMERIC(10, 2) NOT NULL, 
	criado_em TIMESTAMP WITHOUT TIME ZONE NOT NULL, 
	atualizado_em TIMESTAMP WITHOUT TIME ZONE NOT NULL, 
	PRIMARY KEY (id), 
	UNIQUE (codigo), 
	FOREIGN KEY(cliente_id) REFERENCES usuarios (id), 
	FOREIGN KEY(entregador_id) REFERENCES usuarios (id), 
	FOREIGN KEY(cupom_id) REFERENCES cupons (id), 
	FOREIGN KEY(zona_id) REFERENCES zonas_entrega (id)
);

CREATE INDEX ix_pedidos_criado_em ON pedidos (criado_em);

CREATE INDEX ix_pedidos_status ON pedidos (status);

CREATE TABLE avaliacoes (
	id SERIAL NOT NULL, 
	usuario_id INTEGER NOT NULL, 
	cupcake_id INTEGER NOT NULL, 
	pedido_id INTEGER NOT NULL, 
	nota INTEGER NOT NULL, 
	nota_entrega INTEGER NOT NULL, 
	comentario TEXT NOT NULL, 
	criado_em TIMESTAMP WITHOUT TIME ZONE NOT NULL, 
	PRIMARY KEY (id), 
	CONSTRAINT uq_avaliacao_por_item UNIQUE (usuario_id, pedido_id, cupcake_id), 
	CONSTRAINT ck_avaliacao_nota CHECK (nota BETWEEN 1 AND 5), 
	CONSTRAINT ck_avaliacao_nota_entrega CHECK (nota_entrega BETWEEN 1 AND 5), 
	FOREIGN KEY(usuario_id) REFERENCES usuarios (id), 
	FOREIGN KEY(cupcake_id) REFERENCES cupcakes (id), 
	FOREIGN KEY(pedido_id) REFERENCES pedidos (id)
);

CREATE TABLE favoritos (
	usuario_id INTEGER NOT NULL, 
	cupcake_id INTEGER NOT NULL, 
	criado_em TIMESTAMP WITHOUT TIME ZONE NOT NULL, 
	PRIMARY KEY (usuario_id, cupcake_id), 
	FOREIGN KEY(usuario_id) REFERENCES usuarios (id), 
	FOREIGN KEY(cupcake_id) REFERENCES cupcakes (id)
);

CREATE TABLE itens_pedido (
	id SERIAL NOT NULL, 
	pedido_id INTEGER NOT NULL, 
	cupcake_id INTEGER NOT NULL, 
	quantidade INTEGER NOT NULL, 
	preco_unitario NUMERIC(8, 2) NOT NULL, 
	PRIMARY KEY (id), 
	CONSTRAINT ck_item_quantidade CHECK (quantidade > 0), 
	FOREIGN KEY(pedido_id) REFERENCES pedidos (id), 
	FOREIGN KEY(cupcake_id) REFERENCES cupcakes (id)
);

CREATE TABLE notificacoes (
	id SERIAL NOT NULL, 
	usuario_id INTEGER NOT NULL, 
	pedido_id INTEGER, 
	mensagem VARCHAR(255) NOT NULL, 
	lida BOOLEAN NOT NULL, 
	criado_em TIMESTAMP WITHOUT TIME ZONE NOT NULL, 
	PRIMARY KEY (id), 
	FOREIGN KEY(usuario_id) REFERENCES usuarios (id), 
	FOREIGN KEY(pedido_id) REFERENCES pedidos (id)
);

CREATE INDEX ix_notificacoes_usuario_id ON notificacoes (usuario_id);

CREATE TABLE registros_contato (
	id SERIAL NOT NULL, 
	pedido_id INTEGER NOT NULL, 
	entregador_id INTEGER NOT NULL, 
	meio VARCHAR(10) NOT NULL, 
	criado_em TIMESTAMP WITHOUT TIME ZONE NOT NULL, 
	PRIMARY KEY (id), 
	FOREIGN KEY(pedido_id) REFERENCES pedidos (id), 
	FOREIGN KEY(entregador_id) REFERENCES usuarios (id)
);
