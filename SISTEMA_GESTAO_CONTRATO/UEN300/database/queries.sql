-- ============================================================
--  UEN300 — Sistema de Gestão de Contratos | Diefra
--  Arquivo: database/queries.sql
--  Descrição: Consultas úteis para o dia a dia do sistema
-- ============================================================


-- ============================================================
--  USUÁRIOS
-- ============================================================

-- Buscar usuário pelo e-mail (usado no login)
SELECT id, nome, email, senha_hash, papel, ativo
FROM usuarios
WHERE email = 'carlos.mendes@diefra.com.br'
  AND ativo = TRUE;

-- Listar todos os usuários ativos
SELECT id, nome, email, papel, ultimo_login, criado_em
FROM usuarios
WHERE ativo = TRUE
ORDER BY nome;

-- Atualizar último login
-- UPDATE usuarios SET ultimo_login = NOW() WHERE id = '<uuid>';

-- Desativar usuário (soft delete)
-- UPDATE usuarios SET ativo = FALSE WHERE id = '<uuid>';


-- ============================================================
--  CONTRATOS
-- ============================================================

-- Listar todos os contratos com fornecedor e responsável
SELECT
    c.numero,
    c.titulo,
    c.status,
    c.valor_total,
    c.data_inicio,
    c.data_fim,
    f.razao_social      AS fornecedor,
    u.nome              AS responsavel
FROM contratos c
JOIN fornecedores f ON f.id = c.fornecedor_id
JOIN usuarios    u ON u.id = c.responsavel_id
ORDER BY c.criado_em DESC;

-- Contratos prestes a vencer (próximos 30 dias)
SELECT
    c.numero,
    c.titulo,
    c.status,
    c.data_fim,
    (c.data_fim - CURRENT_DATE) AS dias_restantes,
    f.razao_social AS fornecedor,
    u.nome         AS responsavel
FROM contratos c
JOIN fornecedores f ON f.id = c.fornecedor_id
JOIN usuarios    u ON u.id = c.responsavel_id
WHERE c.status = 'ativo'
  AND c.data_fim BETWEEN CURRENT_DATE AND (CURRENT_DATE + INTERVAL '30 days')
ORDER BY c.data_fim;

-- Contratos por status (resumo geral)
SELECT
    status,
    COUNT(*)                        AS total,
    SUM(valor_total)                AS valor_total,
    AVG(valor_total)                AS ticket_medio
FROM contratos
GROUP BY status
ORDER BY total DESC;

-- Contratos de um fornecedor específico
SELECT c.numero, c.titulo, c.status, c.valor_total, c.data_inicio, c.data_fim
FROM contratos c
JOIN fornecedores f ON f.id = c.fornecedor_id
WHERE f.cnpj_cpf = '12.345.678/0001-90'
ORDER BY c.criado_em DESC;

-- Buscar contrato pelo número
SELECT
    c.*,
    f.razao_social  AS fornecedor_nome,
    f.cnpj_cpf      AS fornecedor_cnpj,
    u.nome          AS responsavel_nome,
    u.email         AS responsavel_email
FROM contratos c
JOIN fornecedores f ON f.id = c.fornecedor_id
JOIN usuarios    u ON u.id = c.responsavel_id
WHERE c.numero = 'UEN300-2025-001';

-- Valor total de contratos ativos
SELECT
    SUM(valor_total)   AS total_carteira,
    SUM(valor_mensal)  AS recorrencia_mensal,
    COUNT(*)           AS qtd_contratos
FROM contratos
WHERE status = 'ativo';


-- ============================================================
--  ADITIVOS
-- ============================================================

-- Aditivos de um contrato
SELECT
    a.numero_aditivo,
    a.descricao,
    a.valor_acrescimo,
    a.nova_data_fim,
    u.nome AS aprovado_por,
    a.criado_em
FROM aditivos a
LEFT JOIN usuarios u ON u.id = a.aprovado_por
WHERE a.contrato_id = (SELECT id FROM contratos WHERE numero = 'UEN300-2025-001')
ORDER BY a.numero_aditivo;


-- ============================================================
--  HISTÓRICO
-- ============================================================

-- Histórico completo de um contrato
SELECT
    h.status_anterior,
    h.status_novo,
    h.observacao,
    u.nome    AS alterado_por,
    h.alterado_em
FROM historico_status h
LEFT JOIN usuarios u ON u.id = h.alterado_por
WHERE h.contrato_id = (SELECT id FROM contratos WHERE numero = 'UEN300-2025-001')
ORDER BY h.alterado_em;


-- ============================================================
--  DASHBOARD — Métricas gerais
-- ============================================================

SELECT
    (SELECT COUNT(*) FROM contratos WHERE status = 'ativo')      AS contratos_ativos,
    (SELECT COUNT(*) FROM contratos WHERE status = 'rascunho')   AS contratos_rascunho,
    (SELECT COUNT(*) FROM contratos WHERE status = 'encerrado')  AS contratos_encerrados,
    (SELECT COUNT(*) FROM fornecedores WHERE ativo = TRUE)       AS fornecedores_ativos,
    (SELECT COUNT(*) FROM usuarios WHERE ativo = TRUE)           AS usuarios_ativos,
    (SELECT SUM(valor_total) FROM contratos WHERE status='ativo') AS valor_carteira_ativa,
    (
        SELECT COUNT(*) FROM contratos
        WHERE status = 'ativo'
          AND data_fim <= CURRENT_DATE + INTERVAL '30 days'
    ) AS contratos_vencendo_30d;
