// ============================================================
//  UEN300 — usuariosController.js
// ============================================================

const Usuario = require('../models/Usuario');

async function listar(req, res) {
  try {
    const usuarios = await Usuario.listarTodos();
    res.json(usuarios);
  } catch (err) {
    res.status(500).json({ erro: 'Erro ao listar usuários.' });
  }
}

async function buscarPorId(req, res) {
  try {
    const usuario = await Usuario.buscarPorId(req.params.id);
    if (!usuario) return res.status(404).json({ erro: 'Usuário não encontrado.' });
    res.json(usuario);
  } catch (err) {
    res.status(500).json({ erro: 'Erro ao buscar usuário.' });
  }
}

async function atualizar(req, res) {
  try {
    const { nome, usuario, email } = req.body;
    const atualizado = await Usuario.atualizar(req.params.id, { nome, usuario, email });
    if (!atualizado) return res.status(404).json({ erro: 'Usuário não encontrado.' });
    res.json({ mensagem: 'Usuário atualizado!', usuario: atualizado });
  } catch (err) {
    res.status(500).json({ erro: 'Erro ao atualizar usuário.' });
  }
}

async function desativar(req, res) {
  try {
    await Usuario.desativar(req.params.id);
    res.json({ mensagem: 'Usuário removido com sucesso.' });
  } catch (err) {
    res.status(500).json({ erro: 'Erro ao remover usuário.' });
  }
}

module.exports = { listar, buscarPorId, atualizar, desativar };
