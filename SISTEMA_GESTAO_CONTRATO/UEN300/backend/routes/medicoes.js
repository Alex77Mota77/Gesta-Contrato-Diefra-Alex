const express = require('express');
const router  = express.Router();
const ctrl    = require('../controllers/medicoesController');
const { autenticar } = require('../middleware/auth');

router.use(autenticar);
router.get('/estatisticas', ctrl.estatisticas);
router.get('/periodos',     ctrl.periodos);
router.get('/',     ctrl.listar);
router.get('/:id',  ctrl.buscarPorId);
router.post('/',    ctrl.criar);
router.put('/:id',  ctrl.atualizar);
router.delete('/:id', ctrl.excluir);
module.exports = router;
