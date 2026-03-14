# UEN300 — Sistema de Gestão de Contratos
### Diefra Engenharia e Consultoria

---

## 📁 Estrutura do Projeto

```
uen300/
├── index.html                  → Página de login
├── css/
│   └── style.css               → Todos os estilos do sistema
├── js/
│   └── main.js                 → Interações e lógica do frontend
├── assets/
│   └── svg/
│       └── logo-icon.svg       → Ícone da logo (mineração)
├── database/
│   ├── schema.sql              → Criação de todas as tabelas
│   ├── seeds.sql               → Dados iniciais para testes
│   ├── queries.sql             → Consultas úteis do sistema
│   └── migrations/
│       └── 001_inicial.sql     → Migração v1.0.0
├── .env.example                → Modelo de variáveis de ambiente
├── .gitignore                  → Arquivos ignorados pelo Git
└── README.md                   → Este arquivo
```

---

## 🚀 Como abrir no VS Code

1. Extraia o `.zip` e abra o **VS Code**
2. `File > Open Folder` → selecione a pasta `uen300`
3. Instale as extensões recomendadas (ver abaixo)
4. Clique com botão direito em `index.html` → **Open with Live Server**

---

## 🔌 Extensões recomendadas para VS Code

| Extensão | Para que serve |
|----------|----------------|
| **Live Server** | Abre o projeto no navegador com hot reload |
| **SQLTools** | Conecta ao PostgreSQL direto no VS Code |
| **SQLTools PostgreSQL Driver** | Driver necessário para o SQLTools |
| **Prettier** | Formata o código automaticamente |
| **GitLens** | Visualiza o histórico Git |

> Instale pelo atalho `Ctrl+Shift+X` e busque pelo nome.

---

## 🗄️ Configuração do Banco de Dados

### 1. Instale o PostgreSQL
Baixe em: https://www.postgresql.org/download/

### 2. Crie o banco
```sql
CREATE DATABASE uen300;
```

### 3. Configure as variáveis de ambiente
```bash
cp .env.example .env
# Edite o .env com suas credenciais reais
```

### 4. Execute as migrações (ordem obrigatória)
```bash
psql -U seu_usuario -d uen300 -f database/migrations/001_inicial.sql
```

### 5. Popule com dados de teste (opcional)
```bash
psql -U seu_usuario -d uen300 -f database/seeds.sql
```

### 6. Conecte no VS Code via SQLTools
- Abra o SQLTools (`Ctrl+Shift+P` → "SQLTools: Add New Connection")
- Selecione **PostgreSQL** e preencha com as credenciais do `.env`

---

## 🎨 Design System

```css
--bg:      #0c0c10   /* fundo escuro     */
--surface: #16161e   /* card / painel    */
--accent:  #009c3b   /* verde bandeira   */
--text:    #f0f0f5   /* texto principal  */
--muted:   #6b6b80   /* texto secundário */
```

**Fontes:** `Plus Jakarta Sans` (títulos) · `Inter` (corpo)

---

## 🗃️ Modelo de Dados

```
usuarios ─────────────────────────────────────┐
                                              │
fornecedores ─┐                               │
              ▼                               ▼
           contratos ◄── aditivos      historico_status
              │
              └──► documentos
```

| Tabela | Descrição |
|--------|-----------|
| `usuarios` | Usuários com acesso ao sistema |
| `fornecedores` | Empresas vinculadas aos contratos |
| `contratos` | Núcleo — todos os contratos |
| `aditivos` | Aditivos e alterações contratuais |
| `documentos` | Arquivos anexados aos contratos |
| `historico_status` | Rastreio automático de mudanças |

---

## 🔌 Próximos passos — Backend

Substitua o `setTimeout` no `main.js` por uma chamada real à API:

```javascript
const response = await fetch('/api/login', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ email, senha })
});
const data = await response.json();
if (data.token) {
  localStorage.setItem('token', data.token);
  window.location.href = 'dashboard.html';
}
```

**Stack recomendada:**
- **Node.js + Express** ou **Python + FastAPI**
- **bcrypt** para hash de senhas
- **JWT** para autenticação por token

---

*Diefra Engenharia e Consultoria · UEN300 v1.0*
