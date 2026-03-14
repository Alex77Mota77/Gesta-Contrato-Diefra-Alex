const Fornecedor = require('../models/Fornecedor');

module.exports = {
  async listar(req, res) {
    try { res.json(await Fornecedor.listar(req.query)); }
    catch (e) { res.status(500).json({ erro: e.message }); }
  },
  async buscarPorId(req, res) {
    try {
      const item = await Fornecedor.buscarPorId(req.params.id);
      if (!item) return res.status(404).json({ erro: 'Fornecedor não encontrado.' });
      res.json(item);
    } catch (e) { res.status(500).json({ erro: e.message }); }
  },
  async criar(req, res) {
    try {
      if (!req.body.razao_social)
        return res.status(400).json({ erro: 'Razão social é obrigatória.' });
      res.status(201).json(await Fornecedor.criar(req.body));
    } catch (e) {
      if (e.code === '23505') return res.status(409).json({ erro: 'CNPJ/CPF já cadastrado.' });
      res.status(500).json({ erro: e.message });
    }
  },
  async atualizar(req, res) {
    try {
      const item = await Fornecedor.atualizar(req.params.id, req.body);
      if (!item) return res.status(404).json({ erro: 'Fornecedor não encontrado.' });
      res.json(item);
    } catch (e) { res.status(500).json({ erro: e.message }); }
  },
  async desativar(req, res) {
    try {
      await Fornecedor.desativar(req.params.id);
      res.json({ mensagem: 'Fornecedor desativado.' });
    } catch (e) {
      if (e.code === '23503') return res.status(400).json({ erro: 'Não é possível remover: existem contratos vinculados.' });
      res.status(500).json({ erro: e.message });
    }
  }
};
