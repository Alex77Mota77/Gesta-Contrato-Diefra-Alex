-- ============================================================
--  UEN300 — Sistema de Gestão de Contratos | Diefra
--  Arquivo: database/seeds.sql
--  Descrição: Dados iniciais para desenvolvimento e testes
--  ATENÇÃO: NÃO executar em produção!
-- ============================================================

-- ============================================================
--  USUÁRIOS (senhas geradas via bcrypt — NÃO são texto puro)
--  Senha de teste para todos: Diefra@2025
-- ============================================================

INSERT INTO usuarios (id, nome, email, senha_hash, papel) VALUES
(
    gen_random_uuid(),
    'Administrador Diefra',
    'admin@diefra.com.br',
    '$2b$12$exemplo_hash_admin_aqui_substituir_pelo_real',
    'admin'
),
(
    gen_random_uuid(),
    'Carlos Mendes',
    'carlos.mendes@diefra.com.br',
    '$2b$12$exemplo_hash_carlos_aqui_substituir_pelo_real',
    'gestor'
),
(
    gen_random_uuid(),
    'Ana Paula Souza',
    'ana.souza@diefra.com.br',
    '$2b$12$exemplo_hash_ana_aqui_substituir_pelo_real',
    'usuario'
);

-- ============================================================
--  FORNECEDORES
-- ============================================================

INSERT INTO fornecedores (razao_social, nome_fantasia, cnpj_cpf, email, telefone, cidade, estado) VALUES
(
    'Equipamentos Mineração Brasil Ltda',
    'MineraBrasil',
    '12.345.678/0001-90',
    'contato@minerabrasil.com.br',
    '(31) 3000-1234',
    'Belo Horizonte',
    'MG'
),
(
    'Serviços Técnicos Geológicos S.A.',
    'GeoTec',
    '98.765.432/0001-10',
    'comercial@geotec.com.br',
    '(11) 4000-5678',
    'São Paulo',
    'SP'
),
(
    'Transportadora Vale Verde Ltda',
    'Vale Verde',
    '55.444.333/0001-22',
    'logistica@valeverde.com.br',
    '(31) 3100-9999',
    'Contagem',
    'MG'
);

-- ============================================================
--  CONTRATOS (usando subqueries para pegar IDs dinâmicos)
-- ============================================================

INSERT INTO contratos (
    numero, titulo, tipo, status,
    fornecedor_id, responsavel_id,
    valor_total, valor_mensal,
    data_inicio, data_fim, data_assinatura,
    descricao
)
SELECT
    'UEN300-2025-001',
    'Fornecimento de Equipamentos de Perfuração',
    'fornecimento',
    'ativo',
    f.id,
    u.id,
    850000.00,
    NULL,
    '2025-01-15',
    '2026-01-14',
    '2025-01-10',
    'Contrato para fornecimento de equipamentos pesados de perfuração para operações em Minas Gerais.'
FROM fornecedores f, usuarios u
WHERE f.cnpj_cpf = '12.345.678/0001-90'
  AND u.email    = 'carlos.mendes@diefra.com.br'
LIMIT 1;

INSERT INTO contratos (
    numero, titulo, tipo, status,
    fornecedor_id, responsavel_id,
    valor_total, valor_mensal,
    data_inicio, data_fim, data_assinatura,
    descricao
)
SELECT
    'UEN300-2025-002',
    'Serviços de Consultoria Geológica',
    'prestacao_servico',
    'ativo',
    f.id,
    u.id,
    240000.00,
    20000.00,
    '2025-03-01',
    '2026-02-28',
    '2025-02-20',
    'Prestação de serviços de consultoria e análise geológica para novos projetos de mineração.'
FROM fornecedores f, usuarios u
WHERE f.cnpj_cpf = '98.765.432/0001-10'
  AND u.email    = 'carlos.mendes@diefra.com.br'
LIMIT 1;

INSERT INTO contratos (
    numero, titulo, tipo, status,
    fornecedor_id, responsavel_id,
    valor_total, valor_mensal,
    data_inicio, data_fim,
    descricao
)
SELECT
    'UEN300-2025-003',
    'Transporte de Materiais — Rota BH/Contagem',
    'prestacao_servico',
    'rascunho',
    f.id,
    u.id,
    96000.00,
    8000.00,
    '2025-06-01',
    '2026-05-31',
    'Contrato de transporte mensal de materiais entre as unidades de Belo Horizonte e Contagem.'
FROM fornecedores f, usuarios u
WHERE f.cnpj_cpf = '55.444.333/0001-22'
  AND u.email    = 'ana.souza@diefra.com.br'
LIMIT 1;
