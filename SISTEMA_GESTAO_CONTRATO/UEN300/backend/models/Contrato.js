// ============================================================
//  UEN300 — backend/models/Contrato.js
// ============================================================

const db = require('../config/db');

const Contrato = {

  async listar({ status, busca } = {}) {
    let where = [];
    let params = [];
    let i = 1;

    if (status) { where.push(`c.status = $${i++}`); params.push(status); }
    if (busca)  {
      where.push(`(c.numero ILIKE $${i} OR c.titulo ILIKE $${i} OR f.razao_social ILIKE $${i})`);
      params.push(`%${busca}%`); i++;
    }

    const sql = `
      SELECT * FROM vw_contratos_completo c
      ${where.length ? 'WHERE ' + where.join(' AND ') : ''}
      ORDER BY criado_em DESC`;

    const r = await db.query(sql, params);
    return r.rows;
  },

  async buscarPorId(id) {
    const r = await db.query(
      'SELECT * FROM vw_contratos_completo WHERE id = $1', [id]
    );
    return r.rows[0];
  },

  async criar({ numero, titulo, fornecedor_id, valor_total, valor_mensal,
                data_inicio, data_fim, status, observacoes, criado_por }) {
    const r = await db.query(`
      INSERT INTO contratos
        (numero, titulo, fornecedor_id, valor_total, valor_mensal,
         data_inicio, data_fim, status, observacoes, criado_por)
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
      RETURNING *`,
      [numero, titulo, fornecedor_id, valor_total || 0, valor_mensal || null,
       data_inicio, data_fim, status || 'ativo', observacoes || null, criado_por || null]
    );
    return this.buscarPorId(r.rows[0].id);
  },

  async atualizar(id, campos) {
    const { numero, titulo, fornecedor_id, valor_total, valor_mensal,
            data_inicio, data_fim, status, observacoes } = campos;
    const r = await db.query(`
      UPDATE contratos SET
        numero        = COALESCE($1, numero),
        titulo        = COALESCE($2, titulo),
        fornecedor_id = COALESCE($3, fornecedor_id),
        valor_total   = COALESCE($4, valor_total),
        valor_mensal  = COALESCE($5, valor_mensal),
        data_inicio   = COALESCE($6, data_inicio),
        data_fim      = COALESCE($7, data_fim),
        status        = COALESCE($8, status),
        observacoes   = COALESCE($9, observacoes)
      WHERE id = $10 RETURNING id`,
      [numero, titulo, fornecedor_id, valor_total, valor_mensal,
       data_inicio, data_fim, status, observacoes, id]
    );
    return r.rows[0] ? this.buscarPorId(id) : null;
  },

  async excluir(id) {
    await db.query('DELETE FROM contratos WHERE id = $1', [id]);
  },

  async estatisticas() {
    const r = await db.query(`
      SELECT
        COUNT(*)                          AS total,
        COUNT(*) FILTER (WHERE status='ativo')     AS ativos,
        COUNT(*) FILTER (WHERE status='pendente')  AS pendentes,
        COUNT(*) FILTER (WHERE status='encerrado') AS encerrados,
        COUNT(*) FILTER (WHERE data_fim < CURRENT_DATE AND status='ativo') AS vencidos,
        COUNT(*) FILTER (WHERE data_fim BETWEEN CURRENT_DATE AND CURRENT_DATE+30
                         AND status='ativo') AS vencendo_30dias,
        COALESCE(SUM(valor_total),0) AS valor_total_geral
      FROM contratos`);
    return r.rows[0];
  }
};

module.exports = Contrato;
