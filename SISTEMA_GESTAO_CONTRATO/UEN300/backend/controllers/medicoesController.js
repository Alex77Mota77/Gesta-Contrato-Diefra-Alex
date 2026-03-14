const Medicao = require('../models/Medicao');

module.exports = {
  async listar(req, res) {
    try { res.json(await Medicao.listar(req.query)); }
    catch (e) { res.status(500).json({ erro: e.message }); }
  },
  async buscarPorId(req, res) {
    try {
      const item = await Medicao.buscarPorId(req.params.id);
      if (!item) return res.status(404).json({ erro: 'Medição não encontrada.' });
      res.json(item);
    } catch (e) { res.status(500).json({ erro: e.message }); }
  },
  async criar(req, res) {
    try {
      const { contrato_id, num_obra, centro_custo, nome_contrato,
              periodo_medicao, num_medicao, medicao_prevista, valor_medido } = req.body;
      if (!contrato_id || !num_obra || !centro_custo || !nome_contrato ||
          !periodo_medicao || !num_medicao || medicao_prevista == null || valor_medido == null)
        return res.status(400).json({ erro: 'Todos os campos obrigatórios devem ser preenchidos.' });
      const item = await Medicao.criar({ ...req.body, criado_por: req.usuario?.id });
      res.status(201).json(item);
    } catch (e) {
      if (e.code === '23503') return res.status(400).json({ erro: 'Contrato não encontrado.' });
      res.status(500).json({ erro: e.message });
    }
  },
  async atualizar(req, res) {
    try {
      const item = await Medicao.atualizar(req.params.id, req.body);
      if (!item) return res.status(404).json({ erro: 'Medição não encontrada.' });
      res.json(item);
    } catch (e) { res.status(500).json({ erro: e.message }); }
  },
  async excluir(req, res) {
    try {
      await Medicao.excluir(req.params.id);
      res.json({ mensagem: 'Medição excluída.' });
    } catch (e) { res.status(500).json({ erro: e.message }); }
  },
  async estatisticas(req, res) {
    try { res.json(await Medicao.estatisticas()); }
    catch (e) { res.status(500).json({ erro: e.message }); }
  },
  async periodos(req, res) {
    try { res.json(await Medicao.periodos()); }
    catch (e) { res.status(500).json({ erro: e.message }); }
  }
};
