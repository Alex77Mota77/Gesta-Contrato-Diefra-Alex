# UEN300 — Documentação do Banco de Dados
## Arquitetura, Tabelas e Relacionamentos

---

## Como executar a migração

```bash
psql -U postgres -d uen300 -f database/migrations/003_schema_completo.sql
```

---

## Diagrama de Relacionamentos (ER simplificado)

```
┌──────────────┐       ┌──────────────────┐       ┌─────────────┐
│  fornecedores│──1:N──│     contratos    │──1:N──│   medicoes  │
└──────────────┘       └──────────────────┘       └─────────────┘
       │                        │                         │
       │ 0:N (forn. preferencial)│ criado_por             │ criado_por
       ▼                        ▼                         ▼
┌──────────────┐       ┌──────────────────┐       ┌─────────────┐
│  suprimentos │       │    usuarios      │       │   usuarios  │
└──────────────┘       └──────────────────┘       └─────────────┘
       │                        │
       │ 1:N                    │ responsavel_id (0:N)
       ▼                        ▼
┌──────────────────────┐  ┌─────────────┐
│ movimentacoes_estoque│  │   veiculos  │
└──────────────────────┘  └─────────────┘
```

---

## TABELA 1 — `usuarios`

**Propósito:** Autenticação e identificação dos usuários do sistema.

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | SERIAL PK | Identificador único auto-incrementado |
| nome | VARCHAR(100) | Nome completo do usuário |
| usuario | VARCHAR(50) UNIQUE | Login de acesso |
| senha | TEXT | Hash bcrypt da senha (nunca texto puro) |
| email | VARCHAR(255) UNIQUE | E-mail de contato |
| ativo | BOOLEAN | TRUE = pode acessar / FALSE = bloqueado |
| criado_em | TIMESTAMPTZ | Data/hora de criação |
| atualizado_em | TIMESTAMPTZ | Atualizado automaticamente por TRIGGER |

**Por que não apagamos usuários?**
Usamos `ativo = FALSE` (soft delete). Se apagássemos, perderíamos o histórico de quem criou contratos e medições.

**Relacionamentos de saída (outras tabelas apontam para cá):**
- `contratos.criado_por` → preserva quem criou o contrato
- `medicoes.criado_por` → preserva quem registrou a medição
- `veiculos.responsavel_id` → responsável pelo veículo
- `movimentacoes_estoque.usuario_id` → quem movimentou o estoque

---

## TABELA 2 — `fornecedores`

**Propósito:** Cadastro de empresas que prestam serviços ou fornecem materiais.

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | SERIAL PK | Identificador único |
| razao_social | VARCHAR(200) | Nome jurídico obrigatório |
| nome_fantasia | VARCHAR(200) | Nome comercial (opcional) |
| cnpj_cpf | VARCHAR(20) UNIQUE | Documento fiscal único |
| email / telefone | VARCHAR | Contato |
| cidade / uf | VARCHAR | Localização |
| ativo | BOOLEAN | Soft delete |

**Relacionamentos de saída:**
- `contratos.fornecedor_id` → Um fornecedor pode ter vários contratos
- `suprimentos.fornecedor_id` → Fornecedor preferencial do item

**Regra de integridade:**
- `ON DELETE RESTRICT` nos contratos: **não é possível apagar um fornecedor que tem contratos ativos**. O sistema retorna erro amigável.

---

## TABELA 3 — `contratos`

**Propósito:** Registro completo de cada contrato firmado com fornecedores.

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | SERIAL PK | |
| numero | VARCHAR(50) UNIQUE | Número oficial do contrato |
| titulo | VARCHAR(300) | Descrição do objeto |
| fornecedor_id | INTEGER FK | Empresa contratada (obrigatório) |
| valor_total | NUMERIC(15,2) | Valor total do contrato |
| valor_mensal | NUMERIC(15,2) | Parcela mensal (opcional) |
| data_inicio | DATE | |
| data_fim | DATE | |
| status | ENUM | `ativo`, `pendente`, `encerrado` |
| criado_por | INTEGER FK | Usuário que cadastrou |

**Constraints importantes:**
- `CHECK (data_fim >= data_inicio)` → O banco rejeita contratos com data inválida
- `UNIQUE (numero)` → Número de contrato nunca se repete

**Relacionamentos:**
- ← `fornecedores` (obrigatório — JOIN direto)
- ← `usuarios` (nullable — SET NULL se usuário for desativado)
- → `medicoes` (um contrato pode ter N medições)

---

## TABELA 4 — `medicoes`

**Propósito:** Controle financeiro de cada medição de um contrato.
É o coração do módulo financeiro: registra o que foi previsto, o que foi realizado e o que foi faturado.

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | SERIAL PK | |
| contrato_id | INTEGER FK | Contrato ao qual pertence |
| num_obra | VARCHAR(50) | Número da obra |
| centro_custo | VARCHAR(50) | Centro de custo |
| nome_contrato | VARCHAR(300) | Descrição (desnormalizado para agilidade) |
| periodo_medicao | VARCHAR(20) | Ex: "Maio/2025" |
| num_medicao | VARCHAR(20) | Número sequencial da medição |
| medicao_prevista | NUMERIC(15,2) | Valor que estava planejado |
| valor_medido | NUMERIC(15,2) | Valor efetivamente medido |
| **diferenca** | **NUMERIC GENERATED** | **Calculado SEMPRE pelo banco** |
| data_envio_medicao | DATE | Quando foi enviada ao cliente |
| data_ordem_fatura | DATE | Quando foi emitida a ordem |
| data_envio_fatura | DATE | Quando a fatura foi entregue |
| observacao | TEXT | Notas livres |

### Campo `diferenca` — GENERATED ALWAYS

```sql
diferenca NUMERIC(15,2)
    GENERATED ALWAYS AS (valor_medido - medicao_prevista) STORED
```

Este é um **campo calculado pelo próprio banco de dados**. Significa:
1. Você nunca precisa calcular no código
2. É **impossível** ter uma diferença errada — o banco garante
3. O valor é persistido fisicamente (STORED), então consultas são rápidas

---

## TABELA 5 — `veiculos`

**Propósito:** Controle da frota da UEN300.

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| placa | VARCHAR(10) UNIQUE | Identificador único do veículo |
| modelo / marca / ano / cor | | Dados do veículo |
| renavam | VARCHAR(20) | Documento |
| km_atual | INTEGER | Quilometragem atual |
| proxima_revisao | DATE | Alerta de manutenção |
| status | ENUM | `disponivel`, `em_uso`, `manutencao`, `inativo` |
| responsavel_id | FK → usuarios | Quem está com o veículo |

**Regra:** Se o responsável sair do sistema (`ativo = FALSE`), o veículo continua existindo — apenas `responsavel_id` vira NULL (`ON DELETE SET NULL`).

---

## TABELA 6 — `suprimentos`

**Propósito:** Catálogo do almoxarifado. Cada linha representa um **tipo** de item.

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| codigo | VARCHAR(30) UNIQUE | Código interno do item |
| nome | VARCHAR(200) | Descrição do item |
| categoria | ENUM | `material`, `equipamento`, `epi`, `escritorio`, `outros` |
| unidade | VARCHAR(10) | un, kg, lt, mt, cx, pc |
| qtd_estoque | NUMERIC | Saldo atual |
| qtd_minima | NUMERIC | Abaixo disso → alerta de estoque baixo |
| valor_unitario | NUMERIC | Preço de referência |
| fornecedor_id | FK → fornecedores | Fornecedor preferencial |

---

## TABELA 7 — `movimentacoes_estoque`

**Propósito:** Rastreia toda entrada e saída de itens. **Nunca altere o estoque diretamente** — sempre use esta tabela.

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| suprimento_id | FK | Qual item |
| tipo | ENUM | `entrada`, `saida`, `ajuste` |
| quantidade | NUMERIC | Quantidade movimentada |
| valor_unitario | NUMERIC | Preço na data da movimentação |
| motivo | VARCHAR | Ex: "Compra NF 1234" |
| documento_ref | VARCHAR | Número de NF, pedido, etc. |
| usuario_id | FK | Quem registrou |

### TRIGGER — atualização automática do estoque

```sql
entrada → qtd_estoque = qtd_estoque + quantidade
saida   → qtd_estoque = qtd_estoque - quantidade
ajuste  → qtd_estoque = quantidade (substitui o saldo)
```

O TRIGGER executa após cada INSERT e atualiza `suprimentos.qtd_estoque` automaticamente. O frontend nunca precisa fazer duas chamadas.

---

## VIEWS (consultas pré-montadas)

### `vw_contratos_completo`
Junta contratos + nome do fornecedor + nome de quem criou + dias para vencer.
O frontend consulta esta view diretamente — não precisa fazer JOIN.

### `vw_medicoes_completo`
Junta medições + dados do contrato + fornecedor + criador.

### `vw_estoque_status`
Mostra todos os itens com status calculado:
- `ok` → estoque normal
- `estoque_baixo` → abaixo do mínimo
- `sem_estoque` → zerado

---

## Políticas de integridade (ON DELETE)

| Situação | Comportamento |
|----------|---------------|
| Apagar fornecedor com contratos | ❌ BLOQUEADO (`RESTRICT`) |
| Apagar contrato com medições | ❌ BLOQUEADO (`RESTRICT`) |
| Desativar usuário | ✅ FK vira NULL (`SET NULL`) — histórico preservado |
| Atualizar ID do fornecedor | ✅ Propaga para contratos (`CASCADE`) |

---

## APIs disponíveis após executar a migração

```
POST   /api/auth/login
POST   /api/auth/registro

GET    /api/contratos
POST   /api/contratos
GET    /api/contratos/:id
PUT    /api/contratos/:id
DELETE /api/contratos/:id
GET    /api/contratos/estatisticas

GET    /api/medicoes
POST   /api/medicoes
GET    /api/medicoes/:id
PUT    /api/medicoes/:id
DELETE /api/medicoes/:id
GET    /api/medicoes/estatisticas
GET    /api/medicoes/periodos

GET    /api/fornecedores
POST   /api/fornecedores
...

GET    /api/veiculos
POST   /api/veiculos
...

GET    /api/suprimentos
POST   /api/suprimentos
POST   /api/suprimentos/:id/movimentar
GET    /api/suprimentos/:id/historico
...
```
