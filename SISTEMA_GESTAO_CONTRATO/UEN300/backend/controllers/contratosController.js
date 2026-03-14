const Contrato = require('../models/Contrato');

module.exports = {
  async listar(req, res) {
    try {
      const lista = await Contrato.listar(req.query);
      res.json(lista);
    } catch (e) { res.status(500).json({ erro: e.message }); }
  },
  async buscarPorId(req, res) {
    try {
      const item = await Contrato.buscarPorId(req.params.id);
      if (!item) return res.status(404).json({ erro: 'Contrato não encontrado.' });
      res.json(item);
    } catch (e) { res.status(500).json({ erro: e.message }); }
  },
  async criar(req, res) {
    try {
      const { numero, titulo, fornecedor_id, data_inicio, data_fim } = req.body;
      if (!numero || !titulo || !fornecedor_id || !data_inicio || !data_fim)
        return res.status(400).json({ erro: 'Campos obrigatórios: numero, titulo, fornecedor_id, data_inicio, data_fim.' });
      const item = await Contrato.criar({ ...req.body, criado_por: req.usuario?.id });
      res.status(201).json(item);
    } catch (e) {
      if (e.code === '23505') return res.status(409).json({ erro: 'Número de contrato já cadastrado.' });
      if (e.code === '23503') return res.status(400).json({ erro: 'Fornecedor não encontrado.' });
      res.status(500).json({ erro: e.message });
    }
  },
  async atualizar(req, res) {
    try {
      const item = await Contrato.atualizar(req.params.id, req.body);
      if (!item) return res.status(404).json({ erro: 'Contrato não encontrado.' });
      res.json(item);
    } catch (e) { res.status(500).json({ erro: e.message }); }
  },
  async excluir(req, res) {
    try {
      await Contrato.excluir(req.params.id);
      res.json({ mensagem: 'Contrato excluído.' });
    } catch (e) {
      if (e.code === '23503') return res.status(400).json({ erro: 'Não é possível excluir: existem medições vinculadas.' });
      res.status(500).json({ erro: e.message });
    }
  },
  async estatisticas(req, res) {
    try { res.json(await Contrato.estatisticas()); }
    catch (e) { res.status(500).json({ erro: e.message }); }
  }
};
