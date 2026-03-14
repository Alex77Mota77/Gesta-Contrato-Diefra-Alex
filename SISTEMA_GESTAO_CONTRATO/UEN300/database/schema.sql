-- ============================================================
--  UEN300 — Sistema de Gestão de Contratos | Diefra
--  Arquivo: database/schema.sql
--  Banco:   PostgreSQL 15+
--  Descrição: Criação de todas as tabelas do sistema
-- ============================================================

-- Habilita extensão para UUIDs
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
--  TIPOS ENUM
-- ============================================================

CREATE TYPE papel_usuario     AS ENUM ('admin', 'gestor', 'usuario');
CREATE TYPE status_contrato   AS ENUM ('rascunho', 'ativo', 'encerrado', 'cancelado', 'renovacao');
CREATE TYPE tipo_contrato     AS ENUM ('prestacao_servico', 'fornecimento', 'parceria', 'manutencao', 'outros');

-- ============================================================
--  TABELA: usuarios
--  Armazena todos os usuários com acesso ao sistema
-- ============================================================

CREATE TABLE IF NOT EXISTS usuarios (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    nome            VARCHAR(100)    NOT NULL,
    email           VARCHAR(255)    NOT NULL UNIQUE,
    senha_hash      TEXT            NOT NULL,
    papel           papel_usuario   NOT NULL DEFAULT 'usuario',
    ativo           BOOLEAN         NOT NULL DEFAULT TRUE,
    avatar_url      TEXT,
    ultimo_login    TIMESTAMPTZ,
    criado_em       TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    atualizado_em   TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

-- ============================================================
--  TABELA: fornecedores
--  Empresas ou pessoas físicas vinculadas aos contratos
-- ============================================================

CREATE TABLE IF NOT EXISTS fornecedores (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    razao_social    VARCHAR(200)    NOT NULL,
    nome_fantasia   VARCHAR(200),
    cnpj_cpf        VARCHAR(18)     NOT NULL UNIQUE,
    email           VARCHAR(255),
    telefone        VARCHAR(20),
    endereco        TEXT,
    cidade          VARCHAR(100),
    estado          CHAR(2),
    cep             VARCHAR(9),
    ativo           BOOLEAN         NOT NULL DEFAULT TRUE,
    criado_em       TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    atualizado_em   TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

-- ============================================================
--  TABELA: contratos
--  Núcleo do sistema — registra todos os contratos
-- ============================================================

CREATE TABLE IF NOT EXISTS contratos (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    numero              VARCHAR(50)     NOT NULL UNIQUE,   -- ex: UEN300-2025-001
    titulo              VARCHAR(300)    NOT NULL,
    descricao           TEXT,
    tipo                tipo_contrato   NOT NULL DEFAULT 'prestacao_servico',
    status              status_contrato NOT NULL DEFAULT 'rascunho',

    -- Partes envolvidas
    fornecedor_id       UUID            NOT NULL REFERENCES fornecedores(id),
    responsavel_id      UUID            NOT NULL REFERENCES usuarios(id),

    -- Valores
    valor_total         NUMERIC(15,2)   NOT NULL DEFAULT 0,
    valor_mensal        NUMERIC(15,2),

    -- Datas
    data_inicio         DATE            NOT NULL,
    data_fim            DATE            NOT NULL,
    data_assinatura     DATE,
    data_cancelamento   DATE,

    -- Arquivos e observações
    arquivo_url         TEXT,           -- URL do contrato digitalizado
    observacoes         TEXT,

    -- Controle
    criado_por          UUID            REFERENCES usuarios(id),
    criado_em           TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    atualizado_em       TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    -- Regra: data_fim deve ser posterior à data_inicio
    CONSTRAINT chk_datas CHECK (data_fim > data_inicio),
    CONSTRAINT chk_valor  CHECK (valor_total >= 0)
);

-- ============================================================
--  TABELA: aditivos
--  Registra aditivos/alterações de contratos existentes
-- ============================================================

CREATE TABLE IF NOT EXISTS aditivos (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    contrato_id     UUID            NOT NULL REFERENCES contratos(id) ON DELETE CASCADE,
    numero_aditivo  SMALLINT        NOT NULL,
    descricao       TEXT            NOT NULL,
    valor_acrescimo NUMERIC(15,2)   DEFAULT 0,
    nova_data_fim   DATE,
    aprovado_por    UUID            REFERENCES usuarios(id),
    criado_em       TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    UNIQUE (contrato_id, numero_aditivo)
);

-- ============================================================
--  TABELA: documentos
--  Arquivos anexados a um contrato
-- ============================================================

CREATE TABLE IF NOT EXISTS documentos (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    contrato_id     UUID            NOT NULL REFERENCES contratos(id) ON DELETE CASCADE,
    nome            VARCHAR(200)    NOT NULL,
    tipo_arquivo    VARCHAR(50),    -- pdf, docx, xlsx, etc.
    url             TEXT            NOT NULL,
    tamanho_bytes   INTEGER,
    enviado_por     UUID            REFERENCES usuarios(id),
    criado_em       TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

-- ============================================================
--  TABELA: historico_status
--  Rastreia cada mudança de status de um contrato
-- ============================================================

CREATE TABLE IF NOT EXISTS historico_status (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    contrato_id     UUID            NOT NULL REFERENCES contratos(id) ON DELETE CASCADE,
    status_anterior status_contrato,
    status_novo     status_contrato NOT NULL,
    observacao      TEXT,
    alterado_por    UUID            REFERENCES usuarios(id),
    alterado_em     TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

-- ============================================================
--  ÍNDICES — melhoram performance nas buscas mais comuns
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_usuarios_email         ON usuarios      (email);
CREATE INDEX IF NOT EXISTS idx_usuarios_ativo         ON usuarios      (ativo);
CREATE INDEX IF NOT EXISTS idx_fornecedores_cnpj      ON fornecedores  (cnpj_cpf);
CREATE INDEX IF NOT EXISTS idx_contratos_numero       ON contratos     (numero);
CREATE INDEX IF NOT EXISTS idx_contratos_status       ON contratos     (status);
CREATE INDEX IF NOT EXISTS idx_contratos_fornecedor   ON contratos     (fornecedor_id);
CREATE INDEX IF NOT EXISTS idx_contratos_responsavel  ON contratos     (responsavel_id);
CREATE INDEX IF NOT EXISTS idx_contratos_data_fim     ON contratos     (data_fim);
CREATE INDEX IF NOT EXISTS idx_aditivos_contrato      ON aditivos      (contrato_id);
CREATE INDEX IF NOT EXISTS idx_documentos_contrato    ON documentos    (contrato_id);
CREATE INDEX IF NOT EXISTS idx_historico_contrato     ON historico_status (contrato_id);

-- ============================================================
--  TRIGGERS — atualizam "atualizado_em" automaticamente
-- ============================================================

CREATE OR REPLACE FUNCTION fn_atualizar_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.atualizado_em = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_usuarios_ts
    BEFORE UPDATE ON usuarios
    FOR EACH ROW EXECUTE FUNCTION fn_atualizar_timestamp();

CREATE TRIGGER trg_fornecedores_ts
    BEFORE UPDATE ON fornecedores
    FOR EACH ROW EXECUTE FUNCTION fn_atualizar_timestamp();

CREATE TRIGGER trg_contratos_ts
    BEFORE UPDATE ON contratos
    FOR EACH ROW EXECUTE FUNCTION fn_atualizar_timestamp();

-- ============================================================
--  TRIGGER — registra histórico automático de status
-- ============================================================

CREATE OR REPLACE FUNCTION fn_registrar_historico_status()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO historico_status (contrato_id, status_anterior, status_novo)
        VALUES (NEW.id, OLD.status, NEW.status);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_contratos_historico
    AFTER UPDATE ON contratos
    FOR EACH ROW EXECUTE FUNCTION fn_registrar_historico_status();
