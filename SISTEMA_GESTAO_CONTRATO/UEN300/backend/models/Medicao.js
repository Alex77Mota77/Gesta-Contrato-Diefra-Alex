// ============================================================
//  UEN300 — backend/models/Medicao.js
// ============================================================

const db = require('../config/db');

const Medicao = {

  async listar({ contrato_id, periodo, busca } = {}) {
    let where = [];
    let params = [];
    let i = 1;

    if (contrato_id) { where.push(`m.contrato_id = $${i++}`); params.push(contrato_id); }
    if (periodo)     { where.push(`m.periodo_medicao ILIKE $${i++}`); params.push(`%${periodo}%`); }
    if (busca)       {
      where.push(`(m.num_obra ILIKE $${i} OR m.nome_contrato ILIKE $${i} OR m.centro_custo ILIKE $${i} OR m.num_medicao ILIKE $${i})`);
      params.push(`%${busca}%`); i++;
    }

    const sql = `
      SELECT * FROM vw_medicoes_completo m
      ${where.length ? 'WHERE ' + where.join(' AND ') : ''}
      ORDER BY criado_em DESC`;

    const r = await db.query(sql, params);
    return r.rows;
  },

  async buscarPorId(id) {
    const r = await db.query(
      'SELECT * FROM vw_medicoes_completo WHERE id = $1', [id]
    );
    return r.rows[0];
  },

  async criar({ contrato_id, num_obra, centro_custo, nome_contrato,
                periodo_medicao, num_medicao, medicao_prevista, valor_medido,
                data_envio_medicao, data_ordem_fatura, data_envio_fatura,
                observacao, criado_por }) {
    const r = await db.query(`
      INSERT INTO medicoes
        (contrato_id, num_obra, centro_custo, nome_contrato,
         periodo_medicao, num_medicao, medicao_prevista, valor_medido,
         data_envio_medicao, data_ordem_fatura, data_envio_fatura,
         observacao, criado_por)
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)
      RETURNING id`,
      [contrato_id, num_obra, centro_custo, nome_contrato,
       periodo_medicao, num_medicao,
       medicao_prevista || 0, valor_medido || 0,
       data_envio_medicao || null, data_ordem_fatura || null, data_envio_fatura || null,
       observacao || null, criado_por || null]
    );
    return this.buscarPorId(r.rows[0].id);
  },

  async atualizar(id, campos) {
    const { num_obra, centro_custo, nome_contrato, periodo_medicao,
            num_medicao, medicao_prevista, valor_medido, data_envio_medicao,
            data_ordem_fatura, data_envio_fatura, observacao } = campos;

    const r = await db.query(`
      UPDATE medicoes SET
        num_obra           = COALESCE($1, num_obra),
        centro_custo       = COALESCE($2, centro_custo),
        nome_contrato      = COALESCE($3, nome_contrato),
        periodo_medicao    = COALESCE($4, periodo_medicao),
        num_medicao        = COALESCE($5, num_medicao),
        medicao_prevista   = COALESCE($6, medicao_prevista),
        valor_medido       = COALESCE($7, valor_medido),
        data_envio_medicao = $8,
        data_ordem_fatura  = $9,
        data_envio_fatura  = $10,
        observacao         = $11
      WHERE id = $12 RETURNING id`,
      [num_obra, centro_custo, nome_contrato, periodo_medicao,
       num_medicao, medicao_prevista, valor_medido,
       data_envio_medicao || null, data_ordem_fatura || null,
       data_envio_fatura || null, observacao || null, id]
    );
    return r.rows[0] ? this.buscarPorId(id) : null;
  },

  async excluir(id) {
    await db.query('DELETE FROM medicoes WHERE id = $1', [id]);
  },

  async estatisticas() {
    const r = await db.query(`
      SELECT
        COUNT(*)                       AS total,
        COALESCE(SUM(medicao_prevista),0) AS total_previsto,
        COALESCE(SUM(valor_medido),0)     AS total_medido,
        COALESCE(SUM(diferenca),0)        AS total_diferenca,
        COUNT(DISTINCT periodo_medicao)   AS periodos_distintos
      FROM medicoes`);
    return r.rows[0];
  },

  async periodos() {
    const r = await db.query(`
      SELECT DISTINCT periodo_medicao
      FROM medicoes
      ORDER BY periodo_medicao`);
    return r.rows.map(r => r.periodo_medicao);
  }
};

module.exports = Medicao;
