/* ============================================================
   UEN300 — Sistema de Gestão de Contratos | Diefra
   Arquivo: js/main.js
   ============================================================ */

const API_URL = 'http://localhost:3000/api';

document.addEventListener('DOMContentLoaded', () => {

  if (localStorage.getItem('uen300_token')) {
    window.location.href = 'pages/dashboard.html';
    return;
  }

  const mainBtn      = document.getElementById('mainBtn');
  const googleBtn    = document.getElementById('googleBtn');
  const usuarioInput = document.getElementById('email');   // campo login
  const senhaInput   = document.getElementById('senha');

  /* ------ RIPPLE ------ */
  function createRipple(e) {
    const btn      = e.currentTarget;
    const circle   = document.createElement('span');
    const diameter = Math.max(btn.clientWidth, btn.clientHeight);
    const radius   = diameter / 2;
    const rect     = btn.getBoundingClientRect();
    circle.style.cssText = `width:${diameter}px;height:${diameter}px;left:${e.clientX-rect.left-radius}px;top:${e.clientY-rect.top-radius}px;`;
    circle.classList.add('ripple');
    btn.querySelector('.ripple')?.remove();
    btn.appendChild(circle);
  }

  /* ------ LOGIN ------ */
  mainBtn.addEventListener('click', async (e) => {
    createRipple(e);

    const login = usuarioInput.value.trim();
    const senha = senhaInput.value.trim();

    if (!login || !senha) {
      shakeField(!login ? usuarioInput : senhaInput);
      mostrarErro(!login ? 'Informe seu usuário ou e-mail.' : 'Informe sua senha.');
      return;
    }

    mainBtn.textContent = 'Entrando...';
    mainBtn.disabled    = true;
    limparErro();

    try {
      // Detecta se digitou e-mail ou nome de usuário
      const body = login.includes('@')
        ? { email: login, senha }
        : { usuario: login, senha };

      const response = await fetch(`${API_URL}/auth/login`, {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify(body)
      });

      const data = await response.json();

      if (!response.ok) throw new Error(data.erro || 'Erro ao fazer login.');

      localStorage.setItem('uen300_token',   data.token);
      localStorage.setItem('uen300_usuario', JSON.stringify(data.usuario));

      mainBtn.textContent = '✓ Bem-vindo!';
      mainBtn.classList.add('success');

      setTimeout(() => {
        window.location.href = 'pages/inicio.html';
      }, 800);

    } catch (err) {
      mainBtn.textContent = 'Entrar agora';
      mainBtn.disabled    = false;
      mainBtn.classList.remove('success');
      mostrarErro(err.message);
      shakeField(usuarioInput);
    }
  });

  googleBtn.addEventListener('click', (e) => {
    createRipple(e);
    mostrarErro('Login com Google em breve.');
  });

  [usuarioInput, senhaInput].forEach(input => {
    input.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') mainBtn.click();
    });
  });

  function shakeField(input) {
    const shakes = [6, -6, 4, -4, 2, -2, 0];
    let i = 0;
    const interval = setInterval(() => {
      input.style.transform = `translateX(${shakes[i]}px)`;
      i++;
      if (i >= shakes.length) {
        clearInterval(interval);
        input.style.transform = '';
        input.focus();
      }
    }, 50);
  }

  function mostrarErro(msg) {
    let el = document.getElementById('msg-erro');
    if (!el) {
      el = document.createElement('p');
      el.id = 'msg-erro';
      el.style.cssText = 'color:#ff6b6b;font-size:12px;text-align:center;margin-top:10px;animation:fadeUp 0.3s ease;';
      mainBtn.parentNode.insertBefore(el, mainBtn.nextSibling);
    }
    el.textContent = msg;
  }

  function limparErro() {
    const el = document.getElementById('msg-erro');
    if (el) el.textContent = '';
  }

});
