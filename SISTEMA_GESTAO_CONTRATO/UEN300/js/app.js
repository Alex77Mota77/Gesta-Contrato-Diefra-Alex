/* ============================================================
   UEN300 — App JS compartilhado
   Arquivo: js/app.js
   ============================================================ */

const APP = (() => {

  const API = 'http://localhost:3000/api';

  /* ── AUTH ─────────────────────────────────────────────────── */
  function getToken()   { return localStorage.getItem('uen300_token'); }
  function getUsuario() { return JSON.parse(localStorage.getItem('uen300_usuario') || '{}'); }

  function verificarAuth() {
    if (!getToken()) { window.location.href = '../index.html'; return false; }
    return true;
  }

  function logout() {
    localStorage.removeItem('uen300_token');
    localStorage.removeItem('uen300_usuario');
    window.location.href = '../index.html';
  }

  function headers() {
    return {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${getToken()}`
    };
  }

  /* ── FETCH ─────────────────────────────────────────────────── */
  async function api(method, endpoint, body = null) {
    const opts = { method, headers: headers() };
    if (body) opts.body = JSON.stringify(body);
    const res  = await fetch(`${API}${endpoint}`, opts);
    const data = await res.json();
    if (res.status === 401 || res.status === 403) { logout(); return; }
    if (!res.ok) throw new Error(data.erro || 'Erro na requisição.');
    return data;
  }

  /* ── TOAST ─────────────────────────────────────────────────── */
  function toast(msg, tipo = 'success') {
    let container = document.getElementById('toast-container');
    if (!container) {
      container = document.createElement('div');
      container.id = 'toast-container';
      document.body.appendChild(container);
    }
    const el = document.createElement('div');
    el.className = `toast ${tipo}`;
    el.innerHTML = `<span class="toast-icon">${tipo === 'success' ? '✓' : '✕'}</span><span>${msg}</span>`;
    container.appendChild(el);
    setTimeout(() => { el.style.opacity = '0'; el.style.transition = 'opacity 0.3s'; setTimeout(() => el.remove(), 300); }, 3000);
  }

  /* ── SIDEBAR ─────────────────────────────────────────────────── */
  function initSidebar(paginaAtiva) {
    if (!verificarAuth()) return;

    const u = getUsuario();

    // Preenche usuário
    const avatarEl = document.getElementById('sidebarAvatar');
    const nomeEl   = document.getElementById('sidebarNome');
    if (avatarEl) avatarEl.textContent = (u.nome || 'U')[0].toUpperCase();
    if (nomeEl)   nomeEl.textContent   = u.nome || 'Usuário';

    // Marca item ativo
    document.querySelectorAll('.nav-item[data-page]').forEach(item => {
      if (item.dataset.page === paginaAtiva) item.classList.add('active');
    });

    // Logout
    const btnLogout = document.getElementById('btnLogout');
    if (btnLogout) btnLogout.addEventListener('click', logout);
  }

  /* ── MODAL ─────────────────────────────────────────────────── */
  function abrirModal(id) {
    const el = document.getElementById(id);
    if (el) el.style.display = 'flex';
  }

  function fecharModal(id) {
    const el = document.getElementById(id);
    if (el) el.style.display = 'none';
  }

  function initModal(modalId, fecharIds = []) {
    const overlay = document.getElementById(modalId);
    if (!overlay) return;
    overlay.addEventListener('click', e => { if (e.target === overlay) fecharModal(modalId); });
    fecharIds.forEach(id => {
      const btn = document.getElementById(id);
      if (btn) btn.addEventListener('click', () => fecharModal(modalId));
    });
  }

  /* ── FORMATO DATA ────────────────────────────────────────────── */
  function formatarData(d) {
    if (!d) return '—';
    return new Date(d).toLocaleDateString('pt-BR');
  }

  function formatarMoeda(v) {
    if (v == null) return '—';
    return Number(v).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
  }

  return { API, getToken, getUsuario, verificarAuth, logout, headers, api, toast, initSidebar, abrirModal, fecharModal, initModal, formatarData, formatarMoeda };

})();
