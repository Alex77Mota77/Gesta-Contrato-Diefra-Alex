-- ============================================================
--  UEN300 — Sistema de Gestão de Contratos | Diefra
--  Arquivo: database/seeds_usuarios.sql
--  Descrição: Dados de teste para a tabela usuarios
--
--  Como executar:
--  psql -U postgres -d uen300 -f database/seeds_usuarios.sql
--
--  ATENÇÃO: As senhas abaixo estão em texto puro apenas para
--  facilitar o teste. O sistema fará o hash via bcrypt.
--  Senha de todos os usuários: Diefra@2025
-- ============================================================

-- Limpa dados anteriores
DELETE FROM usuarios;

-- Reinicia o contador de ID
ALTER SEQUENCE usuarios_id_seq RESTART WITH 1;

-- Insere usuários de teste
-- (o hash abaixo corresponde à senha: Diefra@2025)
INSERT INTO usuarios (nome, usuario, senha, email) VALUES
(
    'Administrador Diefra',
    'admin',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TiGzmArfGX5S5Ml9Z3D1XCpYvGqS',
    'admin@diefra.com.br'
),
(
    'Carlos Mendes',
    'carlos.mendes',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TiGzmArfGX5S5Ml9Z3D1XCpYvGqS',
    'carlos.mendes@diefra.com.br'
),
(
    'Ana Paula Souza',
    'ana.souza',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TiGzmArfGX5S5Ml9Z3D1XCpYvGqS',
    'ana.souza@diefra.com.br'
);

-- Confirma
SELECT id, nome, usuario, email, ativo, criado_em
FROM usuarios
ORDER BY id;
