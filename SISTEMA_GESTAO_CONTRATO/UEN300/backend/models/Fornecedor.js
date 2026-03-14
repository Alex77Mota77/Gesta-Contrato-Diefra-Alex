// ============================================================
//  UEN300 — backend/models/Fornecedor.js
// ============================================================

const db = require('../config/db');

const Fornecedor = {

  async listar({ busca } = {}) {
    let where = "WHERE ativo = TRUE";
    let params = [];
    if (busca) {
      where += ` AND (razao_social ILIKE $1 OR cnpj_cpf ILIKE $1 OR nome_fantasia ILIKE $1)`;
      params.push(`%${busca}%`);
    }
    const r = await db.query(
      `SELECT * FROM fornecedores ${where} ORDER BY razao_social`, params
    );
    return r.rows;
  },

  async buscarPorId(id) {
    const r = await db.query('SELECT * FROM fornecedores WHERE id = $1', [id]);
    return r.rows[0];
  },

  async criar(dados) {
    const { razao_social, nome_fantasia, cnpj_cpf, email, telefone,
            endereco, cidade, uf, contato, observacoes } = dados;
    const r = await db.query(`
      INSERT INTO fornecedores
        (razao_social, nome_fantasia, cnpj_cpf, email, telefone,
         endereco, cidade, uf, contato, observacoes)
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) RETURNING *`,
      [razao_social, nome_fantasia||null, cnpj_cpf||null, email||null,
       telefone||null, endereco||null, cidade||null, uf||null,
       contato||null, observacoes||null]
    );
    return r.rows[0];
  },

  async atualizar(id, dados) {
    const { razao_social, nome_fantasia, cnpj_cpf, email, telefone,
            endereco, cidade, uf, contato, observacoes } = dados;
    const r = await db.query(`
      UPDATE fornecedores SET
        razao_social  = COALESCE($1, razao_social),
        nome_fantasia = COALESCE($2, nome_fantasia),
        cnpj_cpf      = COALESCE($3, cnpj_cpf),
        email         = COALESCE($4, email),
        telefone      = COALESCE($5, telefone),
        endereco      = COALESCE($6, endereco),
        cidade        = COALESCE($7, cidade),
        uf            = COALESCE($8, uf),
        contato       = COALESCE($9, contato),
        observacoes   = COALESCE($10, observacoes)
      WHERE id = $11 RETURNING *`,
      [razao_social, nome_fantasia, cnpj_cpf, email, telefone,
       endereco, cidade, uf, contato, observacoes, id]
    );
    return r.rows[0];
  },

  async desativar(id) {
    await db.query('UPDATE fornecedores SET ativo = FALSE WHERE id = $1', [id]);
  }
};

module.exports = Fornecedor;
