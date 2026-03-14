// ============================================================
//  UEN300 — backend/models/Suprimento.js
// ============================================================

const db = require('../config/db');

const Suprimento = {

  async listar({ categoria, busca, status_estoque } = {}) {
    let where = ['s.ativo = TRUE'];
    let params = [];
    let i = 1;

    if (categoria) { where.push(`s.categoria = $${i++}`); params.push(categoria); }
    if (busca) {
      where.push(`(s.codigo ILIKE $${i} OR s.nome ILIKE $${i})`);
      params.push(`%${busca}%`); i++;
    }
    if (status_estoque === 'sem_estoque')  where.push('s.qtd_estoque <= 0');
    if (status_estoque === 'estoque_baixo') where.push('s.qtd_estoque > 0 AND s.qtd_estoque <= s.qtd_minima');

    const r = await db.query(`
      SELECT * FROM vw_estoque_status s
      WHERE ${where.join(' AND ')}
      ORDER BY s.nome`, params);
    return r.rows;
  },

  async buscarPorId(id) {
    const r = await db.query(
      'SELECT * FROM vw_estoque_status WHERE id = $1', [id]
    );
    return r.rows[0];
  },

  async criar(dados) {
    const { codigo, nome, categoria, unidade, qtd_estoque, qtd_minima,
            valor_unitario, fornecedor_id, localizacao, observacoes } = dados;
    const r = await db.query(`
      INSERT INTO suprimentos
        (codigo, nome, categoria, unidade, qtd_estoque, qtd_minima,
         valor_unitario, fornecedor_id, localizacao, observacoes)
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) RETURNING id`,
      [codigo, nome, categoria||'material', unidade||'un',
       qtd_estoque||0, qtd_minima||0, valor_unitario||null,
       fornecedor_id||null, localizacao||null, observacoes||null]
    );
    return this.buscarPorId(r.rows[0].id);
  },

  async atualizar(id, dados) {
    const { codigo, nome, categoria, unidade, qtd_minima,
            valor_unitario, fornecedor_id, localizacao, observacoes } = dados;
    const r = await db.query(`
      UPDATE suprimentos SET
        codigo         = COALESCE($1, codigo),
        nome           = COALESCE($2, nome),
        categoria      = COALESCE($3, categoria),
        unidade        = COALESCE($4, unidade),
        qtd_minima     = COALESCE($5, qtd_minima),
        valor_unitario = COALESCE($6, valor_unitario),
        fornecedor_id  = $7,
        localizacao    = $8,
        observacoes    = $9
      WHERE id = $10 RETURNING id`,
      [codigo, nome, categoria, unidade, qtd_minima,
       valor_unitario, fornecedor_id||null, localizacao||null, observacoes||null, id]
    );
    return r.rows[0] ? this.buscarPorId(id) : null;
  },

  async movimentar({ suprimento_id, tipo, quantidade, valor_unitario, motivo, documento_ref, usuario_id }) {
    const r = await db.query(`
      INSERT INTO movimentacoes_estoque
        (suprimento_id, tipo, quantidade, valor_unitario, motivo, documento_ref, usuario_id)
      VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *`,
      [suprimento_id, tipo, quantidade, valor_unitario||null,
       motivo||null, documento_ref||null, usuario_id||null]
    );
    return r.rows[0];
  },

  async historico(suprimento_id) {
    const r = await db.query(`
      SELECT m.*, u.nome AS usuario_nome
      FROM movimentacoes_estoque m
      LEFT JOIN usuarios u ON u.id = m.usuario_id
      WHERE m.suprimento_id = $1
      ORDER BY m.criado_em DESC`, [suprimento_id]);
    return r.rows;
  },

  async desativar(id) {
    await db.query('UPDATE suprimentos SET ativo = FALSE WHERE id = $1', [id]);
  },

  async estatisticas() {
    const r = await db.query(`
      SELECT
        COUNT(*)                                         AS total,
        COUNT(*) FILTER (WHERE qtd_estoque <= 0)         AS sem_estoque,
        COUNT(*) FILTER (WHERE qtd_estoque > 0 AND qtd_estoque <= qtd_minima) AS estoque_baixo,
        COALESCE(SUM(qtd_estoque * COALESCE(valor_unitario,0)), 0) AS valor_total_estoque
      FROM suprimentos WHERE ativo = TRUE`);
    return r.rows[0];
  }
};

module.exports = Suprimento;
