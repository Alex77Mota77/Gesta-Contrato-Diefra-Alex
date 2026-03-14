// ============================================================
//  UEN300 — Sistema de Gestão de Contratos | Diefra
//  Arquivo: backend/controllers/authController.js
//  Descrição: Login aceita "usuario" ou "email" + senha
// ============================================================

const jwt     = require('jsonwebtoken');
const Usuario = require('../models/Usuario');

// POST /api/auth/login
async function login(req, res) {
  try {
    const { usuario, email, senha } = req.body;

    if ((!usuario && !email) || !senha) {
      return res.status(400).json({ erro: 'Informe usuário (ou e-mail) e senha.' });
    }

    // Busca pelo campo usuário OU email
    let user = null;
    if (usuario) {
      user = await Usuario.buscarPorUsuario(usuario);
    } else {
      user = await Usuario.buscarPorEmail(email);
    }

    if (!user) {
      return res.status(401).json({ erro: 'Usuário ou senha inválidos.' });
    }

    const senhaCorreta = await Usuario.verificarSenha(senha, user.senha);
    if (!senhaCorreta) {
      return res.status(401).json({ erro: 'Usuário ou senha inválidos.' });
    }

    const token = jwt.sign(
      { id: user.id, nome: user.nome, usuario: user.usuario, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '8h' }
    );

    return res.json({
      token,
      usuario: { id: user.id, nome: user.nome, usuario: user.usuario, email: user.email }
    });

  } catch (err) {
    console.error('Erro no login:', err);
    return res.status(500).json({ erro: 'Erro interno do servidor.' });
  }
}

// POST /api/auth/registro
async function registro(req, res) {
  try {
    const { nome, usuario, senha, email } = req.body;

    if (!nome || !usuario || !senha || !email) {
      return res.status(400).json({ erro: 'Todos os campos são obrigatórios: nome, usuario, senha, email.' });
    }

    // Verifica duplicatas
    const usuarioExiste = await Usuario.buscarPorUsuario(usuario);
    if (usuarioExiste) {
      return res.status(409).json({ erro: 'Este nome de usuário já está em uso.' });
    }

    const emailExiste = await Usuario.buscarPorEmail(email);
    if (emailExiste) {
      return res.status(409).json({ erro: 'Este e-mail já está cadastrado.' });
    }

    const novo = await Usuario.criar({ nome, usuario, senha, email });

    return res.status(201).json({
      mensagem: 'Usuário criado com sucesso!',
      usuario: novo
    });

  } catch (err) {
    console.error('Erro no registro:', err);
    return res.status(500).json({ erro: 'Erro interno do servidor.' });
  }
}

module.exports = { login, registro };
