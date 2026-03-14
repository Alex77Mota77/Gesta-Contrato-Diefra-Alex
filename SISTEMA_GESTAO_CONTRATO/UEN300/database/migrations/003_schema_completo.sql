-- ============================================================
--  UEN300 - Sistema de Gestao de Contratos | Diefra
--  Arquivo : database/migrations/003_schema_completo.sql
--  Versao  : 3.0
--  Descricao: Schema completo com todos os modulos e
--             relacionamentos entre tabelas
--
--  Como executar:
--  psql -U postgres -d uen300 -f database/migrations/003_schema_completo.sql
-- ============================================================


-- ============================================================
--  PASSO 0 - Limpa o schema anterior com seguranca
--  CASCADE garante que FKs dependentes tambem sao removidas
-- ============================================================

DROP TABLE IF EXISTS movimentacoes_estoque CASCADE;
DROP TABLE IF EXISTS suprimentos           CASCADE;
DROP TABLE IF EXISTS medicoes              CASCADE;
DROP TABLE IF EXISTS contratos             CASCADE;
DROP TABLE IF EXISTS fornecedores          CASCADE;
DROP TABLE IF EXISTS veiculos              CASCADE;
DROP TABLE IF EXISTS usuarios              CASCADE;

DROP FUNCTION IF EXISTS fn_atualizar_timestamp CASCADE;
DROP FUNCTION IF EXISTS fn_calcular_diferenca  CASCADE;


-- ============================================================
--  FUNCAO UTILITARIA - atualiza atualizado_em automaticamente
--  Usada como TRIGGER em TODAS as tabelas
-- ============================================================

CREATE OR REPLACE FUNCTION fn_atualizar_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.atualizado_em = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- ============================================================
--  TABELA 1: usuarios
--  Proposito: Autenticacao e controle de acesso ao sistema.
--
--  Relacionamentos:
--    <- contratos.criado_por   (quem criou o contrato)
--    <- medicoes.criado_por    (quem registrou a medicao)
--    <- veiculos.responsavel_id (responsavel pelo veiculo)
--    <- movimentacoes_estoque.usuario_id
-- ============================================================

CREATE TABLE usuarios (
    id            SERIAL        PRIMARY KEY,
    nome          VARCHAR(100)  NOT NULL,
    usuario       VARCHAR(50)   NOT NULL,
    senha         TEXT          NOT NULL,
    email         VARCHAR(255)  NOT NULL,
    ativo         BOOLEAN       NOT NULL DEFAULT TRUE,
    criado_em     TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ   NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_usuarios_usuario UNIQUE (usuario),
    CONSTRAINT uq_usuarios_email   UNIQUE (email),
    CONSTRAINT ck_usuarios_nome    CHECK  (LENGTH(TRIM(nome))    > 0),
    CONSTRAINT ck_usuarios_usuario CHECK  (LENGTH(TRIM(usuario)) > 0)
);

CREATE INDEX idx_usuarios_usuario ON usuarios (usuario);
CREATE INDEX idx_usuarios_email   ON usuarios (email);
CREATE INDEX idx_usuarios_ativo   ON usuarios (ativo);

CREATE TRIGGER trg_usuarios_ts
    BEFORE UPDATE ON usuarios
    FOR EACH ROW EXECUTE FUNCTION fn_atualizar_timestamp();


-- ============================================================
--  TABELA 2: fornecedores
--  Proposito: Cadastro de empresas e pessoas que fornecem
--             servicos ou produtos para os contratos.
--
--  Relacionamentos:
--    -> contratos.fornecedor_id   (1 fornecedor -> N contratos)
--    -> suprimentos.fornecedor_id (1 fornecedor -> N suprimentos)
-- ============================================================

CREATE TABLE fornecedores (
    id             SERIAL        PRIMARY KEY,
    razao_social   VARCHAR(200)  NOT NULL,
    nome_fantasia  VARCHAR(200),
    cnpj_cpf       VARCHAR(20),
    email          VARCHAR(255),
    telefone       VARCHAR(30),
    endereco       TEXT,
    cidade         VARCHAR(100),
    uf             CHAR(2),
    contato        VARCHAR(100),
    ativo          BOOLEAN       NOT NULL DEFAULT TRUE,
    observacoes    TEXT,
    criado_em      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    atualizado_em  TIMESTAMPTZ   NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_fornecedores_cnpj UNIQUE (cnpj_cpf),
    CONSTRAINT ck_fornecedores_uf   CHECK  (uf IS NULL OR LENGTH(uf) = 2)
);

CREATE INDEX idx_fornecedores_razao  ON fornecedores (razao_social);
CREATE INDEX idx_fornecedores_cnpj   ON fornecedores (cnpj_cpf);
CREATE INDEX idx_fornecedores_ativo  ON fornecedores (ativo);

CREATE TRIGGER trg_fornecedores_ts
    BEFORE UPDATE ON fornecedores
    FOR EACH ROW EXECUTE FUNCTION fn_atualizar_timestamp();


-- ============================================================
--  TABELA 3: contratos
--  Proposito: Registro e acompanhamento de todos os contratos
--             firmados com fornecedores.
--
--  Relacionamentos:
--    <- fornecedores (OBRIGATORIO: todo contrato tem 1 fornecedor)
--    <- usuarios (quem criou o registro)
--    -> medicoes (1 contrato -> N medicoes)
-- ============================================================

DROP TYPE IF EXISTS status_contrato CASCADE;
CREATE TYPE status_contrato AS ENUM ('ativo', 'pendente', 'encerrado');

CREATE TABLE contratos (
    id              SERIAL           PRIMARY KEY,
    numero          VARCHAR(50)      NOT NULL,
    titulo          VARCHAR(300)     NOT NULL,
    fornecedor_id   INTEGER          NOT NULL,
    valor_total     NUMERIC(15, 2)   NOT NULL DEFAULT 0,
    valor_mensal    NUMERIC(15, 2),
    data_inicio     DATE             NOT NULL,
    data_fim        DATE             NOT NULL,
    status          status_contrato  NOT NULL DEFAULT 'ativo',
    observacoes     TEXT,
    criado_por      INTEGER,
    criado_em       TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    atualizado_em   TIMESTAMPTZ      NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_contratos_numero  UNIQUE (numero),
    CONSTRAINT ck_contratos_datas   CHECK  (data_fim >= data_inicio),
    CONSTRAINT ck_contratos_valor   CHECK  (valor_total >= 0),

    -- FK: contrato pertence a 1 fornecedor
    CONSTRAINT fk_contratos_fornecedor
        FOREIGN KEY (fornecedor_id)
        REFERENCES fornecedores (id)
        ON DELETE RESTRICT   -- nao deixa apagar fornecedor com contrato
        ON UPDATE CASCADE,

    -- FK: quem criou (nullable - preserva registro se usuario for desativado)
    CONSTRAINT fk_contratos_usuario
        FOREIGN KEY (criado_por)
        REFERENCES usuarios (id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

CREATE INDEX idx_contratos_numero       ON contratos (numero);
CREATE INDEX idx_contratos_fornecedor   ON contratos (fornecedor_id);
CREATE INDEX idx_contratos_status       ON contratos (status);
CREATE INDEX idx_contratos_data_fim     ON contratos (data_fim);  -- alertas de vencimento

CREATE TRIGGER trg_contratos_ts
    BEFORE UPDATE ON contratos
    FOR EACH ROW EXECUTE FUNCTION fn_atualizar_timestamp();


-- ============================================================
--  TABELA 4: medicoes
--  Proposito: Registro de cada medicao de um contrato.
--             Controla valores previstos x realizados e
--             o fluxo das faturas.
--
--  Relacionamentos:
--    <- contratos (OBRIGATORIO: medicao pertence a 1 contrato)
--    <- usuarios  (quem registrou)
--
--  Campo calculado:
--    diferenca = valor_medido - medicao_prevista
--    (mantido como coluna GENERATED para consistencia)
-- ============================================================

CREATE TABLE medicoes (
    id                  SERIAL         PRIMARY KEY,
    contrato_id         INTEGER        NOT NULL,
    num_obra            VARCHAR(50)    NOT NULL,
    centro_custo        VARCHAR(50)    NOT NULL,
    nome_contrato       VARCHAR(300)   NOT NULL,
    periodo_medicao     VARCHAR(20)    NOT NULL,   -- Ex: "Maio/2025"
    num_medicao         VARCHAR(20)    NOT NULL,
    medicao_prevista    NUMERIC(15,2)  NOT NULL DEFAULT 0,
    valor_medido        NUMERIC(15,2)  NOT NULL DEFAULT 0,

    -- COLUNA CALCULADA AUTOMATICAMENTE pelo banco
    -- diferenca = valor_medido - medicao_prevista
    diferenca           NUMERIC(15,2)
        GENERATED ALWAYS AS (valor_medido - medicao_prevista) STORED,

    data_envio_medicao  DATE,
    data_ordem_fatura   DATE,
    data_envio_fatura   DATE,
    observacao          TEXT,
    criado_por          INTEGER,
    criado_em           TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    atualizado_em       TIMESTAMPTZ    NOT NULL DEFAULT NOW(),

    CONSTRAINT ck_medicoes_prevista CHECK (medicao_prevista >= 0),
    CONSTRAINT ck_medicoes_medido   CHECK (valor_medido     >= 0),

    -- FK principal: medicao pertence a 1 contrato
    CONSTRAINT fk_medicoes_contrato
        FOREIGN KEY (contrato_id)
        REFERENCES contratos (id)
        ON DELETE RESTRICT   -- nao apaga contrato com medicoes
        ON UPDATE CASCADE,

    -- FK usuario (nullable)
    CONSTRAINT fk_medicoes_usuario
        FOREIGN KEY (criado_por)
        REFERENCES usuarios (id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

CREATE INDEX idx_medicoes_contrato ON medicoes (contrato_id);
CREATE INDEX idx_medicoes_periodo  ON medicoes (periodo_medicao);
CREATE INDEX idx_medicoes_num_obra ON medicoes (num_obra);
CREATE INDEX idx_medicoes_criado   ON medicoes (criado_em DESC);

CREATE TRIGGER trg_medicoes_ts
    BEFORE UPDATE ON medicoes
    FOR EACH ROW EXECUTE FUNCTION fn_atualizar_timestamp();


-- ============================================================
--  TABELA 5: veiculos
--  Proposito: Controle da frota - registro, manutencao
--             e responsaveis por cada veiculo.
--
--  Relacionamentos:
--    <- usuarios (responsavel pelo veiculo - nullable)
-- ============================================================

DROP TYPE IF EXISTS status_veiculo CASCADE;
CREATE TYPE status_veiculo AS ENUM ('disponivel', 'em_uso', 'manutencao', 'inativo');

CREATE TABLE veiculos (
    id                SERIAL          PRIMARY KEY,
    placa             VARCHAR(10)     NOT NULL,
    modelo            VARCHAR(100)    NOT NULL,
    marca             VARCHAR(80),
    ano               SMALLINT,
    cor               VARCHAR(40),
    renavam           VARCHAR(20),
    km_atual          INTEGER         NOT NULL DEFAULT 0,
    proxima_revisao   DATE,
    status            status_veiculo  NOT NULL DEFAULT 'disponivel',
    responsavel_id    INTEGER,
    observacoes       TEXT,
    ativo             BOOLEAN         NOT NULL DEFAULT TRUE,
    criado_em         TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    atualizado_em     TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_veiculos_placa   UNIQUE (placa),
    CONSTRAINT ck_veiculos_km      CHECK  (km_atual >= 0),
    CONSTRAINT ck_veiculos_ano     CHECK  (ano IS NULL OR (ano >= 1950 AND ano <= 2100)),

    -- FK: responsavel e um usuario do sistema
    CONSTRAINT fk_veiculos_responsavel
        FOREIGN KEY (responsavel_id)
        REFERENCES usuarios (id)
        ON DELETE SET NULL   -- se usuario sair, veiculo fica sem responsavel
        ON UPDATE CASCADE
);

CREATE INDEX idx_veiculos_placa        ON veiculos (placa);
CREATE INDEX idx_veiculos_status       ON veiculos (status);
CREATE INDEX idx_veiculos_responsavel  ON veiculos (responsavel_id);
CREATE INDEX idx_veiculos_revisao      ON veiculos (proxima_revisao); -- alertas

CREATE TRIGGER trg_veiculos_ts
    BEFORE UPDATE ON veiculos
    FOR EACH ROW EXECUTE FUNCTION fn_atualizar_timestamp();


-- ============================================================
--  TABELA 6: suprimentos
--  Proposito: Catalogo de itens do almoxarifado -
--             cada linha e um TIPO de item com seu estoque.
--
--  Relacionamentos:
--    <- fornecedores (fornecedor preferencial - nullable)
--    -> movimentacoes_estoque (historico de entradas/saidas)
-- ============================================================

DROP TYPE IF EXISTS categoria_suprimento CASCADE;
CREATE TYPE categoria_suprimento AS ENUM
    ('material','equipamento','epi','escritorio','outros');

CREATE TABLE suprimentos (
    id                SERIAL                PRIMARY KEY,
    codigo            VARCHAR(30)           NOT NULL,
    nome              VARCHAR(200)          NOT NULL,
    categoria         categoria_suprimento  NOT NULL DEFAULT 'material',
    unidade           VARCHAR(10)           NOT NULL DEFAULT 'un',
    qtd_estoque       NUMERIC(12,3)         NOT NULL DEFAULT 0,
    qtd_minima        NUMERIC(12,3)         NOT NULL DEFAULT 0,
    valor_unitario    NUMERIC(12,2),
    fornecedor_id     INTEGER,
    localizacao       VARCHAR(100),
    ativo             BOOLEAN               NOT NULL DEFAULT TRUE,
    observacoes       TEXT,
    criado_em         TIMESTAMPTZ           NOT NULL DEFAULT NOW(),
    atualizado_em     TIMESTAMPTZ           NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_suprimentos_codigo UNIQUE (codigo),
    CONSTRAINT ck_suprimentos_qtd    CHECK  (qtd_estoque >= 0),
    CONSTRAINT ck_suprimentos_min    CHECK  (qtd_minima  >= 0),

    -- FK: fornecedor preferencial (nullable)
    CONSTRAINT fk_suprimentos_fornecedor
        FOREIGN KEY (fornecedor_id)
        REFERENCES fornecedores (id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

CREATE INDEX idx_suprimentos_codigo     ON suprimentos (codigo);
CREATE INDEX idx_suprimentos_categoria  ON suprimentos (categoria);
CREATE INDEX idx_suprimentos_fornecedor ON suprimentos (fornecedor_id);
CREATE INDEX idx_suprimentos_estoque    ON suprimentos (qtd_estoque);

CREATE TRIGGER trg_suprimentos_ts
    BEFORE UPDATE ON suprimentos
    FOR EACH ROW EXECUTE FUNCTION fn_atualizar_timestamp();


-- ============================================================
--  TABELA 7: movimentacoes_estoque
--  Proposito: Historico de ENTRADAS e SAIDAS de cada item
--             do estoque. Garante rastreabilidade completa.
--
--  Relacionamentos:
--    <- suprimentos (OBRIGATORIO: qual item movimentou)
--    <- usuarios    (quem registrou a movimentacao)
--
--  Trigger:
--    Apos INSERT, atualiza qtd_estoque em suprimentos
--    automaticamente (ENTRADA soma, SAIDA subtrai)
-- ============================================================

DROP TYPE IF EXISTS tipo_movimentacao CASCADE;
CREATE TYPE tipo_movimentacao AS ENUM ('entrada', 'saida', 'ajuste');

CREATE TABLE movimentacoes_estoque (
    id               SERIAL              PRIMARY KEY,
    suprimento_id    INTEGER             NOT NULL,
    tipo             tipo_movimentacao   NOT NULL,
    quantidade       NUMERIC(12,3)       NOT NULL,
    valor_unitario   NUMERIC(12,2),
    motivo           VARCHAR(200),
    documento_ref    VARCHAR(100),        -- num NF, pedido, etc.
    usuario_id       INTEGER,
    criado_em        TIMESTAMPTZ         NOT NULL DEFAULT NOW(),

    CONSTRAINT ck_movimentacoes_qtd CHECK (quantidade > 0),

    CONSTRAINT fk_movimentacoes_suprimento
        FOREIGN KEY (suprimento_id)
        REFERENCES suprimentos (id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_movimentacoes_usuario
        FOREIGN KEY (usuario_id)
        REFERENCES usuarios (id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

CREATE INDEX idx_movimentacoes_suprimento ON movimentacoes_estoque (suprimento_id);
CREATE INDEX idx_movimentacoes_tipo       ON movimentacoes_estoque (tipo);
CREATE INDEX idx_movimentacoes_criado     ON movimentacoes_estoque (criado_em DESC);


-- ============================================================
--  TRIGGER: atualiza qtd_estoque automaticamente
--  Executa apos qualquer INSERT em movimentacoes_estoque
-- ============================================================

CREATE OR REPLACE FUNCTION fn_atualizar_estoque()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.tipo = 'entrada' THEN
        UPDATE suprimentos
           SET qtd_estoque = qtd_estoque + NEW.quantidade
         WHERE id = NEW.suprimento_id;

    ELSIF NEW.tipo = 'saida' THEN
        UPDATE suprimentos
           SET qtd_estoque = qtd_estoque - NEW.quantidade
         WHERE id = NEW.suprimento_id;

    ELSIF NEW.tipo = 'ajuste' THEN
        -- ajuste: quantidade representa o NOVO SALDO
        UPDATE suprimentos
           SET qtd_estoque = NEW.quantidade
         WHERE id = NEW.suprimento_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_atualizar_estoque
    AFTER INSERT ON movimentacoes_estoque
    FOR EACH ROW EXECUTE FUNCTION fn_atualizar_estoque();


-- ============================================================
--  VIEW: vw_contratos_completo
--  Proposito: Junta contratos + fornecedor + criador em
--             uma consulta pronta para o frontend
-- ============================================================

CREATE OR REPLACE VIEW vw_contratos_completo AS
SELECT
    c.id,
    c.numero,
    c.titulo,
    c.valor_total,
    c.valor_mensal,
    c.data_inicio,
    c.data_fim,
    c.status,
    c.observacoes,
    c.criado_em,
    c.atualizado_em,
    -- Dados do fornecedor
    f.id           AS fornecedor_id,
    f.razao_social AS fornecedor_nome,
    f.cnpj_cpf     AS fornecedor_cnpj,
    -- Quem criou
    u.nome         AS criado_por_nome,
    -- Dias ate vencer (util para alertas)
    (c.data_fim - CURRENT_DATE) AS dias_para_vencer
FROM contratos c
JOIN fornecedores f ON f.id = c.fornecedor_id
LEFT JOIN usuarios u ON u.id = c.criado_por;


-- ============================================================
--  VIEW: vw_medicoes_completo
--  Proposito: Junta medicoes + contrato + fornecedor
-- ============================================================

CREATE OR REPLACE VIEW vw_medicoes_completo AS
SELECT
    m.id,
    m.num_obra,
    m.centro_custo,
    m.nome_contrato,
    m.periodo_medicao,
    m.num_medicao,
    m.medicao_prevista,
    m.valor_medido,
    m.diferenca,
    m.data_envio_medicao,
    m.data_ordem_fatura,
    m.data_envio_fatura,
    m.observacao,
    m.criado_em,
    m.atualizado_em,
    -- Contrato relacionado
    c.numero  AS contrato_numero,
    c.status  AS contrato_status,
    -- Fornecedor (via contrato)
    f.razao_social AS fornecedor_nome,
    -- Quem cadastrou
    u.nome AS criado_por_nome
FROM medicoes m
JOIN contratos    c ON c.id = m.contrato_id
JOIN fornecedores f ON f.id = c.fornecedor_id
LEFT JOIN usuarios u ON u.id = m.criado_por;


-- ============================================================
--  VIEW: vw_estoque_status
--  Proposito: Mostra todos os itens com status do estoque
-- ============================================================

CREATE OR REPLACE VIEW vw_estoque_status AS
SELECT
    s.id,
    s.codigo,
    s.nome,
    s.categoria,
    s.unidade,
    s.qtd_estoque,
    s.qtd_minima,
    s.valor_unitario,
    s.localizacao,
    f.razao_social AS fornecedor_nome,
    CASE
        WHEN s.qtd_estoque <= 0             THEN 'sem_estoque'
        WHEN s.qtd_estoque <= s.qtd_minima  THEN 'estoque_baixo'
        ELSE                                     'ok'
    END AS status_estoque,
    -- Valor total em estoque
    (s.qtd_estoque * COALESCE(s.valor_unitario, 0)) AS valor_total_estoque
FROM suprimentos s
LEFT JOIN fornecedores f ON f.id = s.fornecedor_id
WHERE s.ativo = TRUE;


-- ============================================================
--  DADOS INICIAIS (seed)
-- ============================================================

INSERT INTO usuarios (nome, usuario, senha, email) VALUES
(
  'Administrador',
  'admin',
  '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMqJqhCanfw.A8x2fBCbvO5dKW',
  'admin@diefra.com.br'
);
-- Senha: Diefra@2025

INSERT INTO fornecedores (razao_social, nome_fantasia, cnpj_cpf, email, telefone, cidade, uf) VALUES
('Fornecedor Exemplo Ltda', 'Exemplo', '00.000.000/0001-00', 'contato@exemplo.com.br', '(31) 99999-0000', 'Belo Horizonte', 'MG');


-- ============================================================
--  CONFIRMA
-- ============================================================

DO $$
BEGIN
  RAISE NOTICE '==============================================';
  RAISE NOTICE '  UEN300 - Schema criado com sucesso!';
  RAISE NOTICE '==============================================';
  RAISE NOTICE '  Tabelas: usuarios, fornecedores, contratos,';
  RAISE NOTICE '           medicoes, veiculos, suprimentos,';
  RAISE NOTICE '           movimentacoes_estoque';
  RAISE NOTICE '  Views: vw_contratos_completo,';
  RAISE NOTICE '         vw_medicoes_completo,';
  RAISE NOTICE '         vw_estoque_status';
  RAISE NOTICE '  Login: admin / Diefra@2025';
  RAISE NOTICE '==============================================';
END $$;
