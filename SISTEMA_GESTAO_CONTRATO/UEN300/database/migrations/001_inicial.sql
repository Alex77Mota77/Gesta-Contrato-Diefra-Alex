-- ============================================================
--  UEN300 — Sistema de Gestão de Contratos | Diefra
--  Arquivo: database/migrations/001_inicial.sql
--  Versão:  1.0.0
--  Data:    2025-01-01
--  Descrição: Criação inicial do banco de dados
-- ============================================================
--
--  Como executar:
--  psql -U seu_usuario -d uen300 -f database/migrations/001_inicial.sql
--
-- ============================================================

-- Tabela de controle de migrações (sempre a primeira!)
CREATE TABLE IF NOT EXISTS migrations (
    id          SERIAL        PRIMARY KEY,
    arquivo     VARCHAR(255)  NOT NULL UNIQUE,
    executado_em TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- Executa apenas se esta migração ainda não foi rodada
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM migrations WHERE arquivo = '001_inicial.sql'
    ) THEN

        -- Extensão UUID
        CREATE EXTENSION IF NOT EXISTS "pgcrypto";

        -- ENUMs
        CREATE TYPE papel_usuario   AS ENUM ('admin', 'gestor', 'usuario');
        CREATE TYPE status_contrato AS ENUM ('rascunho', 'ativo', 'encerrado', 'cancelado', 'renovacao');
        CREATE TYPE tipo_contrato   AS ENUM ('prestacao_servico', 'fornecimento', 'parceria', 'manutencao', 'outros');

        -- Tabelas (mesmas do schema.sql)
        CREATE TABLE usuarios (
            id            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
            nome          VARCHAR(100) NOT NULL,
            email         VARCHAR(255) NOT NULL UNIQUE,
            senha_hash    TEXT         NOT NULL,
            papel         papel_usuario NOT NULL DEFAULT 'usuario',
            ativo         BOOLEAN      NOT NULL DEFAULT TRUE,
            avatar_url    TEXT,
            ultimo_login  TIMESTAMPTZ,
            criado_em     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
            atualizado_em TIMESTAMPTZ  NOT NULL DEFAULT NOW()
        );

        CREATE TABLE fornecedores (
            id            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
            razao_social  VARCHAR(200) NOT NULL,
            nome_fantasia VARCHAR(200),
            cnpj_cpf      VARCHAR(18)  NOT NULL UNIQUE,
            email         VARCHAR(255),
            telefone      VARCHAR(20),
            endereco      TEXT,
            cidade        VARCHAR(100),
            estado        CHAR(2),
            cep           VARCHAR(9),
            ativo         BOOLEAN      NOT NULL DEFAULT TRUE,
            criado_em     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
            atualizado_em TIMESTAMPTZ  NOT NULL DEFAULT NOW()
        );

        CREATE TABLE contratos (
            id                UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
            numero            VARCHAR(50)    NOT NULL UNIQUE,
            titulo            VARCHAR(300)   NOT NULL,
            descricao         TEXT,
            tipo              tipo_contrato  NOT NULL DEFAULT 'prestacao_servico',
            status            status_contrato NOT NULL DEFAULT 'rascunho',
            fornecedor_id     UUID           NOT NULL REFERENCES fornecedores(id),
            responsavel_id    UUID           NOT NULL REFERENCES usuarios(id),
            valor_total       NUMERIC(15,2)  NOT NULL DEFAULT 0,
            valor_mensal      NUMERIC(15,2),
            data_inicio       DATE           NOT NULL,
            data_fim          DATE           NOT NULL,
            data_assinatura   DATE,
            data_cancelamento DATE,
            arquivo_url       TEXT,
            observacoes       TEXT,
            criado_por        UUID           REFERENCES usuarios(id),
            criado_em         TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
            atualizado_em     TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
            CONSTRAINT chk_datas CHECK (data_fim > data_inicio),
            CONSTRAINT chk_valor  CHECK (valor_total >= 0)
        );

        CREATE TABLE aditivos (
            id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
            contrato_id     UUID         NOT NULL REFERENCES contratos(id) ON DELETE CASCADE,
            numero_aditivo  SMALLINT     NOT NULL,
            descricao       TEXT         NOT NULL,
            valor_acrescimo NUMERIC(15,2) DEFAULT 0,
            nova_data_fim   DATE,
            aprovado_por    UUID         REFERENCES usuarios(id),
            criado_em       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
            UNIQUE (contrato_id, numero_aditivo)
        );

        CREATE TABLE documentos (
            id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
            contrato_id   UUID        NOT NULL REFERENCES contratos(id) ON DELETE CASCADE,
            nome          VARCHAR(200) NOT NULL,
            tipo_arquivo  VARCHAR(50),
            url           TEXT        NOT NULL,
            tamanho_bytes INTEGER,
            enviado_por   UUID        REFERENCES usuarios(id),
            criado_em     TIMESTAMPTZ NOT NULL DEFAULT NOW()
        );

        CREATE TABLE historico_status (
            id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
            contrato_id     UUID            NOT NULL REFERENCES contratos(id) ON DELETE CASCADE,
            status_anterior status_contrato,
            status_novo     status_contrato NOT NULL,
            observacao      TEXT,
            alterado_por    UUID            REFERENCES usuarios(id),
            alterado_em     TIMESTAMPTZ     NOT NULL DEFAULT NOW()
        );

        -- Índices
        CREATE INDEX idx_usuarios_email        ON usuarios     (email);
        CREATE INDEX idx_contratos_status      ON contratos    (status);
        CREATE INDEX idx_contratos_fornecedor  ON contratos    (fornecedor_id);
        CREATE INDEX idx_contratos_data_fim    ON contratos    (data_fim);

        -- Registra migração como concluída
        INSERT INTO migrations (arquivo) VALUES ('001_inicial.sql');

        RAISE NOTICE 'Migração 001_inicial.sql executada com sucesso!';
    ELSE
        RAISE NOTICE 'Migração 001_inicial.sql já foi executada. Pulando...';
    END IF;
END $$;
