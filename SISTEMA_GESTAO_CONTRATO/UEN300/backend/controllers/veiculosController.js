const Veiculo = require('../models/Veiculo');

module.exports = {
  async listar(req, res) {
    try { res.json(await Veiculo.listar(req.query)); }
    catch (e) { res.status(500).json({ erro: e.message }); }
  },
  async buscarPorId(req, res) {
    try {
      const item = await Veiculo.buscarPorId(req.params.id);
      if (!item) return res.status(404).json({ erro: 'Veículo não encontrado.' });
      res.json(item);
    } catch (e) { res.status(500).json({ erro: e.message }); }
  },
  async criar(req, res) {
    try {
      const { placa, modelo } = req.body;
      if (!placa || !modelo) return res.status(400).json({ erro: 'Placa e modelo são obrigatórios.' });
      res.status(201).json(await Veiculo.criar(req.body));
    } catch (e) {
      if (e.code === '23505') return res.status(409).json({ erro: 'Placa já cadastrada.' });
      res.status(500).json({ erro: e.message });
    }
  },
  async atualizar(req, res) {
    try {
      const item = await Veiculo.atualizar(req.params.id, req.body);
      if (!item) return res.status(404).json({ erro: 'Veículo não encontrado.' });
      res.json(item);
    } catch (e) { res.status(500).json({ erro: e.message }); }
  },
  async desativar(req, res) {
    try {
      await Veiculo.desativar(req.params.id);
      res.json({ mensagem: 'Veículo desativado.' });
    } catch (e) { res.status(500).json({ erro: e.message }); }
  },
  async estatisticas(req, res) {
    try { res.json(await Veiculo.estatisticas()); }
    catch (e) { res.status(500).json({ erro: e.message }); }
  }
};
