---
description: Fluxo direto de refatoração — melhora estrutura/legibilidade do código SEM mudar comportamento, provado por testes existentes que continuam passando sem serem alterados
argument-hint: <slug-do-refactor>
allowed-tools: Bash, Read, Grep, Glob, Write, Edit
---

# Comando /refactor

Você executa o **fluxo direto de refatoração** do workflow Spec-Driven local. Refatorar é melhorar a forma do código (legibilidade, duplicação, acoplamento, nomes) **sem alterar o comportamento observável**. A prova de que o comportamento não mudou é simples e inegociável: **os testes existentes continuam passando, sem você alterá-los**.

Por não mudar comportamento, refactor não tem PRD (sem decisão de produto) nem decomposição em tasks. É uma unidade de trabalho, como o `/fix`.

Argumento (slug): `$ARGUMENTS`

Contexto:
- Branch atual: !`git branch --show-current 2>/dev/null || echo "(fora de repo git)"`
- Working tree: !`git status --short 2>/dev/null || echo "(fora de repo)"`
- Data: !`date +%Y-%m-%d`
- Refactors candidatos: !`find docs/changes -maxdepth 1 -type d -name 'chore-*' -o -type d -name 'refactor-*' 2>/dev/null | sort || echo "(nenhum)"`
- Stacks ativas (do constitution): !`grep -A20 '## Active Stacks' docs/explanation/constitution.md 2>/dev/null | grep -oE 'skill: `[a-z0-9-]+`' | sed 's/skill: //; s/`//g' | sort -u || echo "(nenhuma — rode /analyze)"`

---

## Carregar a base de conhecimento da stack

Antes de refatorar, leia o `SKILL.md` das stacks ativas e o `references/conventions.md` e `references/architecture.md` da skill — a refatoração deve mover o código **em direção** aos padrões da stack, não inventar um estilo novo. Sem skill ativa, sugira `/analyze`.

---

## Regra inviolável da refatoração

> **Comportamento idêntico, provado por testes.** Se você precisa mudar um teste para a suíte passar, então você mudou comportamento — e isso **não é mais refactor**: é fix ou feature. Pare e reclassifique.

Demais regras (da constitution):
1. **Cobertura primeiro.** Se a área a refatorar NÃO tem testes que provem o comportamento atual, você não pode refatorar com segurança. Adicione testes de caracterização (que capturam o comportamento atual) ANTES de mexer na estrutura.
2. **`files_touched` é fronteira dura.** Declare e respeite.
3. **Passos pequenos e reversíveis.** Refatore em incrementos, rodando os testes entre eles.
4. **Sem mistura.** Nada de "já que estou aqui" — não corrija bug nem adicione feature no meio do refactor. Se achou um bug, registre e trate em `/fix` separado.

---

## Fase 0 — Resolver e validar

1. Localize a pasta da change a partir de `$ARGUMENTS` (ou crie via `/ideia` antes, classificada como chore/refactor). Se vazio/ambíguo, liste candidatos e pergunte. Encerre.
2. Leia o `00-idea.md` (o que se quer melhorar e por quê).

---

## Fase 1 — Garantir a rede de segurança (testes)

1. Identifique os testes que cobrem o comportamento da área a refatorar.
2. Rode a suíte (test runner da stack ativa) e confirme que está **verde antes** de começar. Se já está vermelha, pare — conserte/entenda antes (pode ser um `/fix`).
3. Se a cobertura é insuficiente para provar o comportamento, **escreva testes de caracterização primeiro**. Esses testes descrevem o que o código faz hoje (mesmo que o design seja ruim) e serão a sua rede.

---

## Fase 2 — Gerar o REFACTOR.md

Crie `docs/changes/{pasta}/REFACTOR.md`:

```markdown
---
type: change
title: "REFACTOR — {o que melhora}"
kind: chore
slug: {slug}
status: draft
idea: ./00-idea.md
created: {YYYY-MM-DD}
---

# REFACTOR — {o que melhora}

## Motivação
{qual problema de design/legibilidade/duplicação justifica mexer}

## Comportamento que NÃO muda
{a fronteira: o que continua exatamente igual do ponto de vista de quem usa}

## Rede de segurança
{quais testes provam o comportamento; se foram adicionados testes de caracterização, quais}

## Plano de refatoração
{os passos pequenos e reversíveis, em ordem}

## files_touched
- {caminhos exatos}

## Rollback
{reverter o commit; refactor não deve ter risco de dados}
```

---

## Fase 3 — Gate de escopo

Vire o alerta e PARE se qualquer um for verdadeiro:
- A mudança altera comportamento observável (mesmo "pequeno") → é `/fix` ou feature.
- Exige mudar um teste existente para passar → mudou comportamento; reclassifique.
- Cresceu além de ~10 arquivos ou virou redesenho arquitetural grande → trate como feature (`/prd` → `/spec`).

Se disparou, deixe o `REFACTOR.md` salvo como registro e oriente o redirecionamento. Encerre.

---

## Fase 4 — Executar (branch, passos, testes)

1. **Branch.** `git checkout main && git pull && git checkout -b chore/{slug}` (ou `refactor/{slug}`).
2. Status do `REFACTOR.md` → `in-progress`.
3. Aplique os passos do plano, **um de cada vez**, rodando os testes entre eles. A suíte deve permanecer verde o tempo todo. Nunca edite os testes existentes para fazê-los passar.
4. Confirme `files_touched` com `git diff --name-only`. Algo fora → reverta ou peça decisão.

---

## Fase 5 — Validar, marcar e commitar

1. Suíte completa verde, sem nenhum teste existente alterado.
2. `REFACTOR.md` → `done`.
3. Commit:
   ```
   git add {files_touched} docs/changes/{pasta}/REFACTOR.md
   git commit -F - <<'EOF'
   refactor({slug}): {título curto}

   ## Motivação
   {resumo}

   ## O que mudou na estrutura
   {resumo}

   ## Garantia
   Comportamento inalterado — suíte existente passa sem alterações.
   EOF
   ```

---

## Fase 6 — Confirmação e próximo passo

Resuma: o que melhorou, a garantia (testes inalterados passando), branch e status. Próximo passo: `/review {slug}` (opcional) e depois merge squash em main, ou `/archive {slug}` se valer registrar.

Modelo recomendado: refatoração se beneficia do modelo mais forte disponível.

## Notas de instalação

Fonte-única `.sdd/workflow/commands/refactor.md`. Após `sdd sync`, vira `/refactor` no Claude, Codex e Gemini.
