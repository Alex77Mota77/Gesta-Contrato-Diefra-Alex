const express = require('express');
const router  = express.Router();
const ctrl    = require('../controllers/suprimentosController');
const { autenticar } = require('../middleware/auth');

router.use(autenticar);
router.get('/estatisticas',            ctrl.estatisticas);
router.get('/',                        ctrl.listar);
router.get('/:id',                     ctrl.buscarPorId);
router.get('/:id/historico',           ctrl.historico);
router.post('/',                       ctrl.criar);
router.post('/:id/movimentar',         ctrl.movimentar);
router.put('/:id',                     ctrl.atualizar);
router.delete('/:id',                  ctrl.desativar);
module.exports = router;
