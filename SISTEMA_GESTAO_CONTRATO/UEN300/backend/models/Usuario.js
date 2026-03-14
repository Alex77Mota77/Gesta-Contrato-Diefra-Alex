// ============================================================
//  UEN300 — Sistema de Gestão de Contratos | Diefra
//  Arquivo: backend/models/Usuario.js
//  Descrição: Operações de banco — tabela usuarios
//  Colunas:   id, nome, usuario, senha, email
// ============================================================

const db      = require('../config/db');
const bcrypt  = require('bcryptjs');

const Usuario = {

  // Listar todos os usuários ativos
  async listarTodos() {
    const result = await db.query(
      `SELECT id, nome, usuario, email, ativo, criado_em, atualizado_em
       FROM usuarios
       WHERE ativo = TRUE
       ORDER BY nome`
    );
    return result.rows;
  },

  // Buscar por ID
  async buscarPorId(id) {
    const result = await db.query(
      `SELECT id, nome, usuario, email, ativo, criado_em
       FROM usuarios WHERE id = $1`,
      [id]
    );
    return result.rows[0];
  },

  // Buscar por usuário (login)
  async buscarPorUsuario(usuario) {
    const result = await db.query(
      `SELECT * FROM usuarios WHERE usuario = $1 AND ativo = TRUE`,
      [usuario]
    );
    return result.rows[0];
  },

  // Buscar por e-mail
  async buscarPorEmail(email) {
    const result = await db.query(
      `SELECT * FROM usuarios WHERE email = $1 AND ativo = TRUE`,
      [email]
    );
    return result.rows[0];
  },

  // Criar novo usuário
  async criar({ nome, usuario, senha, email }) {
    const rounds    = parseInt(process.env.BCRYPT_ROUNDS) || 12;
    const senhaHash = await bcrypt.hash(senha, rounds);

    const result = await db.query(
      `INSERT INTO usuarios (nome, usuario, senha, email)
       VALUES ($1, $2, $3, $4)
       RETURNING id, nome, usuario, email, criado_em`,
      [nome, usuario, senhaHash, email]
    );
    return result.rows[0];
  },

  // Atualizar usuário
  async atualizar(id, { nome, usuario, email }) {
    const result = await db.query(
      `UPDATE usuarios
       SET nome    = COALESCE($1, nome),
           usuario = COALESCE($2, usuario),
           email   = COALESCE($3, email)
       WHERE id = $4
       RETURNING id, nome, usuario, email`,
      [nome, usuario, email, id]
    );
    return result.rows[0];
  },

  // Alterar senha
  async alterarSenha(id, novaSenha) {
    const rounds    = parseInt(process.env.BCRYPT_ROUNDS) || 12;
    const senhaHash = await bcrypt.hash(novaSenha, rounds);
    await db.query(
      `UPDATE usuarios SET senha = $1 WHERE id = $2`,
      [senhaHash, id]
    );
  },

  // Desativar (soft delete)
  async desativar(id) {
    await db.query(
      `UPDATE usuarios SET ativo = FALSE WHERE id = $1`, [id]
    );
  },

  // Verificar senha
  async verificarSenha(senhaDigitada, senhaHash) {
    return bcrypt.compare(senhaDigitada, senhaHash);
  }

};

module.exports = Usuario;
