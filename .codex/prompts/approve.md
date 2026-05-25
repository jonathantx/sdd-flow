
# Aprovar Documentos de uma Feature

> ⚠️ Este comando aprova **documentos** (PRD, SPEC, FIX). A transição de estado depende do tipo:
> - **PRD** → `status: draft` vira `status: approved`
> - **SPEC** → `status: draft` vira `status: validated` (é o estado que o `/tasks` exige)
> - **FIX** → `status: draft` vira `status: approved`
>
> Para aprovar uma **TASK** (mergeia branch, marca `done`, limpa worktree), use **`/approve-task TASK-NNN`** — é outro comando.

Siga **exatamente** estes passos em ordem, sem pular nenhum.

---

## Passo 1 — Pedir o slug da feature

Pergunte ao usuário:

> 🏷️ **Qual é o slug da feature?** (ex: `busca-cpf-rg`)

Aguarde a resposta. Monte o caminho da pasta:

```
docs/changes/feat-<ANO>-<MÊS-2-DÍGITOS>-<slug informado>
```

Exemplo: slug `busca-cpf-rg` com data atual `2026-05` → pasta `docs/changes/feat-2026-05-busca-cpf-rg`

---

## Passo 2 — Listar arquivos com status: draft

Dentro da pasta montada, leia todos os arquivos `.md` e filtre os que possuem `status: draft` no frontmatter.

**Se a pasta não existir:**
```
❌ Pasta não encontrada: docs/changes/feat-2026-05-<slug>
```
Pare.

**Se nenhum arquivo tiver status: draft:**
```
✅ Nenhum documento com status: draft encontrado nesta feature.
```
Pare.

**Se encontrar arquivos com draft**, exiba um menu numerado:

```
📂 docs/changes/feat-2026-05-busca-cpf-rg

Documentos com status: draft:

  [1] 01-PRD.md        — <valor do campo title do frontmatter, se existir>
  [2] 02-SPEC.md       — <valor do campo title do frontmatter, se existir>
  [3] Todos acima

Qual deseja aprovar?
```

Aguarde a escolha antes de continuar.

---

## Passo 3 — Pedir o nome do aprovador

Pergunte ao usuário:

> 👤 **Qual é o seu nome completo para o campo `approved_by`?**

Aguarde a resposta antes de continuar.

---

## Passo 4 — Determinar o estado-alvo de cada arquivo

Antes do preview, identifique o **estado-alvo** de cada arquivo selecionado, lendo o campo `type` do frontmatter:

| `type` no frontmatter | Estado-alvo |
|---|---|
| `prd` | `approved` |
| `spec` | `validated` |
| `change` com `kind: fix` (FIX.md) | `approved` |

Se o arquivo não tem `type` reconhecido, default para `approved` e avise no preview.

---

## Passo 5 — Exibir preview e pedir confirmação

Mostre o preview de **cada arquivo** que será alterado, **sem modificar nada ainda**, usando o estado-alvo correto:

```
📋 Preview das alterações:

── 01-PRD.md ──────────────────────────────
  status: draft  →  status: approved
  approved_by:      "Filipe Souza"
  approved_at:      2026-05-20

── 02-SPEC.md ─────────────────────────────
  status: draft  →  status: validated
  approved_by:      "Filipe Souza"
  approved_at:      2026-05-20

Confirmar aprovação? (s/n)
```

Aguarde a confirmação antes de continuar.

---

## Passo 6 — Aplicar as alterações (somente se confirmado)

Se o usuário confirmar com "s" ou "sim":

Para **cada arquivo** selecionado:
1. Substitua `status: draft` por `status: <estado-alvo>` conforme a tabela do Passo 4.
2. Adicione ou atualize os campos (logo abaixo de `status`):
   ```yaml
   approved_by: "<nome informado>"
   approved_at: <data de hoje YYYY-MM-DD>
   ```
3. **Não altere nenhuma outra parte do arquivo.**
4. Exiba confirmação por arquivo:
   ```
   ✅ 01-PRD.md aprovado (status: approved)
   ✅ 02-SPEC.md validado (status: validated)
   ```

Se o usuário responder "n" ou "não":
```
🚫 Operação cancelada. Nenhuma alteração foi feita.
```
