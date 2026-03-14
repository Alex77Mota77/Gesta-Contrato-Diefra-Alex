-- ============================================================
--  UEN300 — Sistema de Gestão de Contratos | Diefra
--  Arquivo: database/migrations/002_recrear_usuarios.sql
--  Descrição: Recria a tabela usuarios com as colunas:
--             nome, usuario, senha, email
--
--  Como executar:
--  psql -U postgres -d uen300 -f database/migrations/002_recrear_usuarios.sql
-- ============================================================

-- Remove a tabela antiga se existir
DROP TABLE IF EXISTS historico_status CASCADE;
DROP TABLE IF EXISTS documentos      CASCADE;
DROP TABLE IF EXISTS aditivos        CASCADE;
DROP TABLE IF EXISTS contratos       CASCADE;
DROP TABLE IF EXISTS usuarios        CASCADE;

-- Remove tipo antigo se existir
DROP TYPE IF EXISTS papel_usuario CASCADE;

-- ============================================================
--  TABELA: usuarios
--  Colunas: nome, usuario, senha, email
-- ============================================================

CREATE TABLE usuarios (
    id            SERIAL        PRIMARY KEY,
    nome          VARCHAR(100)  NOT NULL,
    usuario       VARCHAR(50)   NOT NULL UNIQUE,
    senha         TEXT          NOT NULL,
    email         VARCHAR(255)  NOT NULL UNIQUE,
    ativo         BOOLEAN       NOT NULL DEFAULT TRUE,
    criado_em     TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

-- ============================================================
--  ÍNDICES
-- ============================================================

CREATE INDEX idx_usuarios_usuario ON usuarios (usuario);
CREATE INDEX idx_usuarios_email   ON usuarios (email);

-- ============================================================
--  TRIGGER — atualiza atualizado_em automaticamente
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

-- ============================================================
--  CONFIRMA
-- ============================================================

DO $$
BEGIN
    RAISE NOTICE '✅ Tabela usuarios criada com sucesso!';
    RAISE NOTICE '   Colunas: id, nome, usuario, senha, email, ativo, criado_em, atualizado_em';
END $$;
