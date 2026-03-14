const Suprimento = require('../models/Suprimento');

module.exports = {
  async listar(req, res) {
    try { res.json(await Suprimento.listar(req.query)); }
    catch (e) { res.status(500).json({ erro: e.message }); }
  },
  async buscarPorId(req, res) {
    try {
      const item = await Suprimento.buscarPorId(req.params.id);
      if (!item) return res.status(404).json({ erro: 'Suprimento não encontrado.' });
      res.json(item);
    } catch (e) { res.status(500).json({ erro: e.message }); }
  },
  async criar(req, res) {
    try {
      const { codigo, nome } = req.body;
      if (!codigo || !nome) return res.status(400).json({ erro: 'Código e nome são obrigatórios.' });
      res.status(201).json(await Suprimento.criar(req.body));
    } catch (e) {
      if (e.code === '23505') return res.status(409).json({ erro: 'Código já cadastrado.' });
      res.status(500).json({ erro: e.message });
    }
  },
  async atualizar(req, res) {
    try {
      const item = await Suprimento.atualizar(req.params.id, req.body);
      if (!item) return res.status(404).json({ erro: 'Suprimento não encontrado.' });
      res.json(item);
    } catch (e) { res.status(500).json({ erro: e.message }); }
  },
  async desativar(req, res) {
    try {
      await Suprimento.desativar(req.params.id);
      res.json({ mensagem: 'Item desativado.' });
    } catch (e) { res.status(500).json({ erro: e.message }); }
  },
  async movimentar(req, res) {
    try {
      const { tipo, quantidade } = req.body;
      if (!tipo || !quantidade) return res.status(400).json({ erro: 'Tipo e quantidade são obrigatórios.' });
      const mov = await Suprimento.movimentar({
        ...req.body,
        suprimento_id: req.params.id,
        usuario_id: req.usuario?.id
      });
      res.status(201).json(mov);
    } catch (e) { res.status(500).json({ erro: e.message }); }
  },
  async historico(req, res) {
    try { res.json(await Suprimento.historico(req.params.id)); }
    catch (e) { res.status(500).json({ erro: e.message }); }
  },
  async estatisticas(req, res) {
    try { res.json(await Suprimento.estatisticas()); }
    catch (e) { res.status(500).json({ erro: e.message }); }
  }
};
