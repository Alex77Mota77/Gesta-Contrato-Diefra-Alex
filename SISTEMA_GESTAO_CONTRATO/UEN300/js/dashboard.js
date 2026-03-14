/* ============================================================
   UEN300 — Dashboard JS
   Arquivo: js/dashboard.js
   ============================================================ */

const API_URL = 'http://localhost:3000/api';

const token          = localStorage.getItem('uen300_token');
const usuarioLogado  = JSON.parse(localStorage.getItem('uen300_usuario') || '{}');

if (!token) window.location.href = '../index.html';

const headers = {
  'Content-Type': 'application/json',
  'Authorization': `Bearer ${token}`
};

// Nome do usuário logado no topbar
document.getElementById('userName').textContent   = usuarioLogado.nome || 'Usuário';
document.getElementById('userAvatar').textContent = (usuarioLogado.nome || 'U')[0].toUpperCase();

// Logout
document.getElementById('btnLogout').addEventListener('click', () => {
  localStorage.removeItem('uen300_token');
  localStorage.removeItem('uen300_usuario');
  window.location.href = '../index.html';
});

// ═══════════════════════════════════════════════════════════════
//  TABELA DE USUÁRIOS
// ═══════════════════════════════════════════════════════════════
let todosUsuarios = [];

async function carregarUsuarios() {
  const corpo = document.getElementById('corpoTabela');
  corpo.innerHTML = `<tr><td colspan="6" class="loading-row">Carregando...</td></tr>`;

  try {
    const res = await fetch(`${API_URL}/usuarios`, { headers });
    if (!res.ok) throw new Error('Erro ao carregar.');

    todosUsuarios = await res.json();
    renderizarTabela(todosUsuarios);
    document.getElementById('metUsuarios').textContent = todosUsuarios.length;

  } catch (err) {
    corpo.innerHTML = `<tr><td colspan="6" class="loading-row" style="color:#ff6b6b">
      ⚠ Erro ao carregar. Verifique se o servidor está rodando (npm run dev).
    </td></tr>`;
  }
}

function renderizarTabela(lista) {
  const corpo = document.getElementById('corpoTabela');

  if (!lista.length) {
    corpo.innerHTML = `<tr><td colspan="6" class="loading-row">Nenhum usuário encontrado.</td></tr>`;
    return;
  }

  corpo.innerHTML = lista.map(u => `
    <tr>
      <td>
        <div style="display:flex;align-items:center;gap:10px">
          <div style="width:32px;height:32px;border-radius:50%;background:var(--accent);
               display:flex;align-items:center;justify-content:center;
               font-weight:700;font-size:13px;color:#fff;flex-shrink:0">
            ${u.nome[0].toUpperCase()}
          </div>
          <span style="font-weight:500">${u.nome}</span>
        </div>
      </td>
      <td style="color:var(--accent);font-weight:600">@${u.usuario}</td>
      <td style="color:var(--muted)">${u.email}</td>
      <td style="color:var(--muted);font-size:12px">
        ${u.criado_em ? new Date(u.criado_em).toLocaleDateString('pt-BR') : '—'}
      </td>
      <td><span class="badge badge-ativo">Ativo</span></td>
      <td>
        <button class="btn-acao" onclick="abrirEdicao(${u.id})">✏ Editar</button>
        <button class="btn-acao btn-excluir" onclick="confirmarDesativar(${u.id}, '${u.nome}')">🗑 Remover</button>
      </td>
    </tr>
  `).join('');
}

// Busca em tempo real
document.getElementById('buscaUsuario').addEventListener('input', (e) => {
  const termo = e.target.value.toLowerCase();
  const filtrado = todosUsuarios.filter(u =>
    u.nome.toLowerCase().includes(termo)     ||
    u.usuario.toLowerCase().includes(termo)  ||
    u.email.toLowerCase().includes(termo)
  );
  renderizarTabela(filtrado);
});

// ═══════════════════════════════════════════════════════════════
//  MODAL — CRIAR / EDITAR
// ═══════════════════════════════════════════════════════════════
const modal       = document.getElementById('modalUsuario');
const modalTitulo = document.getElementById('modalTitulo');
const modalId     = document.getElementById('modalId');
const modalNome   = document.getElementById('modalNome');
const modalUser   = document.getElementById('modalUsuario_campo');
const modalEmail  = document.getElementById('modalEmail');
const modalSenha  = document.getElementById('modalSenha');
const modalErro   = document.getElementById('modalErro');
const grupoSenha  = document.getElementById('grupoSenha');

function abrirModal() {
  modal.style.display  = 'flex';
  modalErro.textContent = '';
}

function fecharModal() {
  modal.style.display   = 'none';
  modalId.value         = '';
  modalNome.value       = '';
  modalUser.value       = '';
  modalEmail.value      = '';
  modalSenha.value      = '';
  modalErro.textContent = '';
}

document.getElementById('btnNovoUsuario').addEventListener('click', () => {
  modalTitulo.textContent  = 'Novo Usuário';
  grupoSenha.style.display = 'flex';
  fecharModal();
  abrirModal();
});

function abrirEdicao(id) {
  const u = todosUsuarios.find(x => x.id === id);
  if (!u) return;
  modalTitulo.textContent  = 'Editar Usuário';
  modalId.value            = u.id;
  modalNome.value          = u.nome;
  modalUser.value          = u.usuario;
  modalEmail.value         = u.email;
  grupoSenha.style.display = 'none';
  abrirModal();
}

document.getElementById('btnFecharModal').addEventListener('click', fecharModal);
document.getElementById('btnCancelar').addEventListener('click', fecharModal);
modal.addEventListener('click', (e) => { if (e.target === modal) fecharModal(); });

// Salvar
document.getElementById('btnSalvar').addEventListener('click', async () => {
  const id      = modalId.value;
  const nome    = modalNome.value.trim();
  const usuario = modalUser.value.trim();
  const email   = modalEmail.value.trim();
  const senha   = modalSenha.value.trim();

  if (!nome || !usuario || !email) {
    modalErro.textContent = 'Nome, usuário e e-mail são obrigatórios.';
    return;
  }
  if (!id && !senha) {
    modalErro.textContent = 'Informe uma senha para o novo usuário.';
    return;
  }

  try {
    let res;
    if (id) {
      res = await fetch(`${API_URL}/usuarios/${id}`, {
        method:  'PUT',
        headers,
        body:    JSON.stringify({ nome, usuario, email })
      });
    } else {
      res = await fetch(`${API_URL}/auth/registro`, {
        method:  'POST',
        headers,
        body:    JSON.stringify({ nome, usuario, senha, email })
      });
    }

    const data = await res.json();
    if (!res.ok) throw new Error(data.erro || 'Erro ao salvar.');

    fecharModal();
    carregarUsuarios();

  } catch (err) {
    modalErro.textContent = err.message;
  }
});

// ═══════════════════════════════════════════════════════════════
//  DESATIVAR
// ═══════════════════════════════════════════════════════════════
async function confirmarDesativar(id, nome) {
  if (!confirm(`Deseja remover o usuário "${nome}"?`)) return;
  try {
    const res = await fetch(`${API_URL}/usuarios/${id}`, { method: 'DELETE', headers });
    if (!res.ok) throw new Error('Erro ao remover.');
    carregarUsuarios();
  } catch (err) {
    alert(err.message);
  }
}

// ── INIT
carregarUsuarios();
document.getElementById('metContratosAtivos').textContent = '—';
document.getElementById('metVencendo').textContent        = '—';
document.getElementById('metFornecedores').textContent    = '—';
