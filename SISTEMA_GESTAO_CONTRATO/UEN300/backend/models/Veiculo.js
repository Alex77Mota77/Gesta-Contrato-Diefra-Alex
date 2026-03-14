// ============================================================
//  UEN300 — backend/models/Veiculo.js
// ============================================================

const db = require('../config/db');

const Veiculo = {

  async listar({ status, busca } = {}) {
    let where = ['v.ativo = TRUE'];
    let params = [];
    let i = 1;
    if (status) { where.push(`v.status = $${i++}`); params.push(status); }
    if (busca)  {
      where.push(`(v.placa ILIKE $${i} OR v.modelo ILIKE $${i} OR u.nome ILIKE $${i})`);
      params.push(`%${busca}%`); i++;
    }
    const r = await db.query(`
      SELECT v.*, u.nome AS responsavel_nome
      FROM veiculos v
      LEFT JOIN usuarios u ON u.id = v.responsavel_id
      WHERE ${where.join(' AND ')}
      ORDER BY v.placa`, params);
    return r.rows;
  },

  async buscarPorId(id) {
    const r = await db.query(`
      SELECT v.*, u.nome AS responsavel_nome
      FROM veiculos v
      LEFT JOIN usuarios u ON u.id = v.responsavel_id
      WHERE v.id = $1`, [id]);
    return r.rows[0];
  },

  async criar(dados) {
    const { placa, modelo, marca, ano, cor, renavam, km_atual,
            proxima_revisao, status, responsavel_id, observacoes } = dados;
    const r = await db.query(`
      INSERT INTO veiculos
        (placa, modelo, marca, ano, cor, renavam, km_atual,
         proxima_revisao, status, responsavel_id, observacoes)
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11) RETURNING id`,
      [placa, modelo, marca||null, ano||null, cor||null, renavam||null,
       km_atual||0, proxima_revisao||null, status||'disponivel',
       responsavel_id||null, observacoes||null]
    );
    return this.buscarPorId(r.rows[0].id);
  },

  async atualizar(id, dados) {
    const { placa, modelo, marca, ano, cor, renavam, km_atual,
            proxima_revisao, status, responsavel_id, observacoes } = dados;
    const r = await db.query(`
      UPDATE veiculos SET
        placa           = COALESCE($1, placa),
        modelo          = COALESCE($2, modelo),
        marca           = COALESCE($3, marca),
        ano             = COALESCE($4, ano),
        cor             = COALESCE($5, cor),
        renavam         = COALESCE($6, renavam),
        km_atual        = COALESCE($7, km_atual),
        proxima_revisao = $8,
        status          = COALESCE($9, status),
        responsavel_id  = $10,
        observacoes     = $11
      WHERE id = $12 RETURNING id`,
      [placa, modelo, marca, ano, cor, renavam, km_atual,
       proxima_revisao||null, status, responsavel_id||null, observacoes||null, id]
    );
    return r.rows[0] ? this.buscarPorId(id) : null;
  },

  async desativar(id) {
    await db.query("UPDATE veiculos SET ativo = FALSE, status = 'inativo' WHERE id = $1", [id]);
  },

  async estatisticas() {
    const r = await db.query(`
      SELECT
        COUNT(*) AS total,
        COUNT(*) FILTER (WHERE status='disponivel') AS disponiveis,
        COUNT(*) FILTER (WHERE status='em_uso')     AS em_uso,
        COUNT(*) FILTER (WHERE status='manutencao') AS manutencao
      FROM veiculos WHERE ativo = TRUE`);
    return r.rows[0];
  }
};

module.exports = Veiculo;
