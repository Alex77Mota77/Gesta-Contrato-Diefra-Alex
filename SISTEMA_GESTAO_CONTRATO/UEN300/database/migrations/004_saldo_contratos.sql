-- ============================================================
--  UEN300 - Migration 004: Saldo em Contratos
--  Arquivo: database/migrations/004_saldo_contratos.sql
--
--  O que faz:
--    1. Adiciona coluna "saldo" em contratos
--    2. Adiciona coluna "total_medido" em contratos (calculado)
--    3. Cria trigger que atualiza saldo automaticamente
--       toda vez que uma medicao e inserida, editada ou removida
--    4. Recalcula saldo de todos os contratos existentes
--
--  Como executar:
--  psql -U postgres -d uen300 -f database/migrations/004_saldo_contratos.sql
-- ============================================================


-- ============================================================
--  PASSO 1 - Adiciona colunas em contratos
-- ============================================================

ALTER TABLE contratos
  ADD COLUMN IF NOT EXISTS total_medido NUMERIC(15,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS saldo        NUMERIC(15,2) NOT NULL DEFAULT 0;


-- ============================================================
--  PASSO 2 - Funcao que recalcula saldo de um contrato
--  Chamada pelo trigger apos qualquer mudanca em medicoes
-- ============================================================

CREATE OR REPLACE FUNCTION fn_recalcular_saldo(p_contrato_id INTEGER)
RETURNS VOID AS $$
DECLARE
  v_total_medido NUMERIC(15,2);
  v_valor_total  NUMERIC(15,2);
BEGIN
  -- Soma todos os valores medidos deste contrato
  SELECT COALESCE(SUM(valor_medido), 0)
    INTO v_total_medido
    FROM medicoes
   WHERE contrato_id = p_contrato_id;

  -- Busca o valor total do contrato
  SELECT valor_total
    INTO v_valor_total
    FROM contratos
   WHERE id = p_contrato_id;

  -- Atualiza total_medido e saldo
  UPDATE contratos
     SET total_medido = v_total_medido,
         saldo        = v_valor_total - v_total_medido
   WHERE id = p_contrato_id;
END;
$$ LANGUAGE plpgsql;


-- ============================================================
--  PASSO 3 - Trigger que dispara apos INSERT, UPDATE, DELETE
--            em medicoes e recalcula o saldo do contrato
-- ============================================================

DROP TRIGGER IF EXISTS trg_saldo_medicoes ON medicoes;

CREATE OR REPLACE FUNCTION fn_trigger_saldo_medicoes()
RETURNS TRIGGER AS $$
BEGIN
  -- INSERT ou UPDATE: recalcula o contrato do novo registro
  IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
    PERFORM fn_recalcular_saldo(NEW.contrato_id);
  END IF;

  -- DELETE: recalcula o contrato do registro removido
  IF (TG_OP = 'DELETE') THEN
    PERFORM fn_recalcular_saldo(OLD.contrato_id);
  END IF;

  -- UPDATE trocando de contrato: recalcula os dois contratos
  IF (TG_OP = 'UPDATE' AND OLD.contrato_id <> NEW.contrato_id) THEN
    PERFORM fn_recalcular_saldo(OLD.contrato_id);
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_saldo_medicoes
  AFTER INSERT OR UPDATE OR DELETE ON medicoes
  FOR EACH ROW EXECUTE FUNCTION fn_trigger_saldo_medicoes();


-- ============================================================
--  PASSO 4 - Recalcula saldo de todos os contratos existentes
-- ============================================================

DO $$
DECLARE
  rec RECORD;
BEGIN
  FOR rec IN SELECT id FROM contratos LOOP
    PERFORM fn_recalcular_saldo(rec.id);
  END LOOP;
  RAISE NOTICE 'Saldos recalculados para todos os contratos.';
END $$;


-- ============================================================
--  PASSO 5 - Atualiza a view vw_contratos_completo com saldo
-- ============================================================

CREATE OR REPLACE VIEW vw_contratos_completo AS
SELECT
  c.id,
  c.numero,
  c.titulo,
  c.valor_total,
  c.valor_mensal,
  c.total_medido,
  c.saldo,
  c.data_inicio,
  c.data_fim,
  c.status,
  c.observacoes,
  c.criado_em,
  c.atualizado_em,
  f.id           AS fornecedor_id,
  f.razao_social AS fornecedor_nome,
  f.cnpj_cpf     AS fornecedor_cnpj,
  u.nome         AS criado_por_nome,
  (c.data_fim - CURRENT_DATE) AS dias_para_vencer,
  -- Percentual consumido do contrato
  CASE
    WHEN c.valor_total > 0
    THEN ROUND((c.total_medido / c.valor_total * 100), 1)
    ELSE 0
  END AS percentual_consumido
FROM contratos c
JOIN fornecedores f ON f.id = c.fornecedor_id
LEFT JOIN usuarios u ON u.id = c.criado_por;


-- ============================================================
--  CONFIRMACAO
-- ============================================================

DO $$
BEGIN
  RAISE NOTICE '==============================================';
  RAISE NOTICE 'Migration 004 aplicada com sucesso!';
  RAISE NOTICE '  + coluna total_medido em contratos';
  RAISE NOTICE '  + coluna saldo em contratos';
  RAISE NOTICE '  + trigger trg_saldo_medicoes';
  RAISE NOTICE '  + funcao fn_recalcular_saldo';
  RAISE NOTICE '  + view vw_contratos_completo atualizada';
  RAISE NOTICE '==============================================';
END $$;
