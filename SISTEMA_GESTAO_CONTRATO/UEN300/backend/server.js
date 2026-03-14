// ============================================================
//  UEN300 — backend/server.js
// ============================================================

require('dotenv').config();
const express = require('express');
const cors    = require('cors');
const path    = require('path');
const db      = require('./config/db');

const app  = express();
const PORT = process.env.APP_PORT || 3000;

// ── MIDDLEWARE ────────────────────────────────────────────────
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// ── ARQUIVOS ESTÁTICOS (frontend) ────────────────────────────
app.use(express.static(path.join(__dirname, '..')));

// ── ROTAS DA API ─────────────────────────────────────────────
app.use('/api/auth',         require('./routes/auth'));
app.use('/api/usuarios',     require('./routes/usuarios'));
app.use('/api/contratos',    require('./routes/contratos'));
app.use('/api/medicoes',     require('./routes/medicoes'));
app.use('/api/fornecedores', require('./routes/fornecedores'));
app.use('/api/veiculos',     require('./routes/veiculos'));
app.use('/api/suprimentos',  require('./routes/suprimentos'));

// ── HEALTH CHECK ─────────────────────────────────────────────
app.get('/api/health', async (req, res) => {
  try {
    await db.query('SELECT 1');
    res.json({ status: 'ok', db: 'conectado', hora: new Date().toISOString() });
  } catch {
    res.status(500).json({ status: 'erro', db: 'desconectado' });
  }
});

// ── SPA FALLBACK ─────────────────────────────────────────────
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, '..', 'index.html'));
});

// ── INICIA ────────────────────────────────────────────────────
app.listen(PORT, async () => {
  try {
    await db.query('SELECT 1');
    console.log(`\n✅ PostgreSQL conectado com sucesso!`);
  } catch (e) {
    console.error(`\n❌ Erro ao conectar ao PostgreSQL: ${e.message}`);
    console.error('   Verifique o arquivo .env\n');
  }
  console.log(`🚀 Servidor rodando em http://localhost:${PORT}`);
  console.log(`   Endpoints disponíveis:`);
  console.log(`   POST /api/auth/login`);
  console.log(`   GET  /api/contratos`);
  console.log(`   GET  /api/medicoes`);
  console.log(`   GET  /api/fornecedores`);
  console.log(`   GET  /api/veiculos`);
  console.log(`   GET  /api/suprimentos\n`);
});
