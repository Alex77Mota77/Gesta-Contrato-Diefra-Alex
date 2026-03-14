// ============================================================
//  UEN300 — Sistema de Gestão de Contratos | Diefra
//  Arquivo: backend/routes/auth.js
// ============================================================

const express = require('express');
const router  = express.Router();
const { login, registro } = require('../controllers/authController');

// POST /api/auth/login
router.post('/login', login);

// POST /api/auth/registro
router.post('/registro', registro);

module.exports = router;
