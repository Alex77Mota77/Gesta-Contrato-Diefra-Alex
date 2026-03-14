// ============================================================
//  UEN300 — backend/routes/usuarios.js
// ============================================================

const express = require('express');
const router  = express.Router();
const ctrl    = require('../controllers/usuariosController');
const { autenticar } = require('../middleware/auth');

router.use(autenticar);

router.get('/',     ctrl.listar);        // GET  /api/usuarios
router.get('/:id',  ctrl.buscarPorId);   // GET  /api/usuarios/:id
router.put('/:id',  ctrl.atualizar);     // PUT  /api/usuarios/:id
router.delete('/:id', ctrl.desativar);   // DEL  /api/usuarios/:id

module.exports = router;
