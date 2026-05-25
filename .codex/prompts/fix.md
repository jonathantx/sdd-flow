
# Comando /fix

Você executa o **fluxo direto de correção** do workflow Spec-Driven local. Um fix corrige comportamento existente que está errado — o comportamento correto já é conhecido, então não há PRD (sem decisão de produto) nem decomposição em tasks (é uma unidade). Você diagnostica a causa raiz, registra o plano no `FIX.md`, e implementa, sempre dentro das regras da constitution.

Argumento (slug): `$ARGUMENTS`

Contexto:
- Branch atual: !`git branch --show-current 2>/dev/null || echo "(fora de repo git)"`
- Working tree: !`git status --short 2>/dev/null || echo "(fora de repo)"`
- Data: !`date +%Y-%m-%d`
- Fixes candidatos: !`find docs/changes -maxdepth 1 -type d -name 'fix-*' 2>/dev/null | sort || echo "(nenhum)"`

---

## Regras invioláveis (da constitution)

1. **Corrija a causa raiz, não o sintoma.** Investigue até entender por que o bug acontece. Tapar o sintoma cria dívida.
2. **Teste de regressão é obrigatório.** Todo fix adiciona um teste que falha por causa do bug e passa depois da correção. É o que impede o bug de voltar.
3. **`files_touched` é fronteira dura.** Declare e respeite. Se a correção quer se espalhar, é sinal de que cresceu (ver gate de complexidade).
4. **Teste é intocável.** Nunca delete/comente/skipe teste existente para passar. Se um teste quebra, investigue.
5. **Pare em ambiguidade.** Se a causa raiz não está clara após investigar, PARE e pergunte — não chute uma correção.
6. **Rollback continua valendo.** Fix também derruba produção se mal feito.

---

## Fase 0 — Resolver e validar

1. Localize `docs/changes/fix-*-{slug}` a partir de `$ARGUMENTS`. Se vazio/ambíguo, liste candidatos e pergunte. Encerre.
2. Confirme `kind: fix` no `00-idea.md`. Se for feature/chore, redirecione e encerre.
3. Leia o `00-idea.md` (sintoma, reprodução, comportamento esperado).
4. Se já existe `FIX.md` com status `done`, avise que o fix já foi feito; pergunte se quer reabrir.

---

## Fase 1 — Diagnosticar (causa raiz)

Investigue a codebase para encontrar a **causa raiz**, não só onde o sintoma aparece:

- Use Grep/Glob/Read para rastrear o fluxo do comportamento quebrado.
- Reproduza mentalmente os passos da reprodução do `00-idea.md`.
- Se o bug envolve uma biblioteca/comportamento externo, use WebSearch/WebFetch para confirmar (ex: comportamento default de uma lib, breaking change conhecido).
- Aplique anti-hallucination: confirme nomes de método/classe/coluna com grep antes de afirmar onde está o problema.

Se após investigar a causa raiz permanecer incerta, PARE. Mostre o que descobriu e o que ainda está ambíguo, e pergunte ao usuário. Encerre o turno.

---

## Fase 2 — Gerar o FIX.md

Crie `docs/changes/{pasta}/FIX.md`:

```markdown
---
type: change
title: "FIX — {Título do problema}"
kind: fix
slug: {slug}
status: draft
external_id: null
idea: ./00-idea.md
created: {YYYY-MM-DD}
---

# FIX — {Título do problema}

> {uma linha do comportamento quebrado}

## Sintoma
{o que acontece de errado, do ponto de vista de quem usa}

## Reprodução
{passos confirmados}

## Causa raiz
{POR QUE acontece — o achado do diagnóstico, com caminho de arquivo e linha}

## Plano de correção
{o que mudar, concretamente, para corrigir a causa raiz}

## files_touched
- {caminho/exato.php}
- {…}

## Teste de regressão
{qual teste será adicionado/ajustado para travar o bug; o caso que ele cobre}

## Rollback
{como desfazer; risco de dados; reverter o commit costuma bastar num fix}
```

---

## Fase 3 — Gate de complexidade

Antes de implementar, avalie se isto ainda é um fix:

**Vire o alerta se qualquer um for verdadeiro:**
- `files_touched` passou de ~5 arquivos
- Surgiu uma decisão de produto (o "comportamento correto" não é óbvio, precisa de alguém de negócio decidir)
- A correção exige mudança arquitetural ou nova dependência

Se disparou: PARE. Avise — "Isto cresceu além de um fix. Recomendo tratar como feature: rode `/ideia` reclassificando, ou `/prd {slug}` se quiser o fluxo completo." Deixe o `FIX.md` salvo como registro do diagnóstico. Encerre e deixe o usuário decidir. Não force a correção grande pelo fluxo direto.

Se continua sendo um fix pequeno: prossiga.

---

## Fase 4 — Checkpoint do plano

Mostre ao usuário, conciso: a **causa raiz**, o **plano de correção** e os **arquivos** a tocar. Pergunte se pode implementar.

- Aguarde confirmação (encerre o turno), a menos que o usuário já tenha sinalizado "corrige direto".
- Esse checkpoint é barato e evita implementar uma correção mal-diagnosticada.

---

## Fase 5 — Implementar

1. **Branch.** Crie/entre em `fix/{slug}` a partir da main atualizada:
   ```
   git checkout main && git pull && git checkout -b fix/{slug}
   ```
   (Se já existe, faça checkout. Se houver working tree sujo que impeça, pare e avise.)
   Se o fix toca migration, rode `php artisan migrate:fresh` localmente antes de testar.

2. **Mude o status** do `FIX.md` para `in-progress`.

3. **Escreva o teste de regressão PRIMEIRO** (red): um teste que reproduz o bug e, portanto, falha agora. Confirme que ele falha pelo motivo certo.

4. **Implemente a correção** restrita ao `files_touched`, seguindo os patterns e a constitution. Antes de tocar qualquer arquivo, confirme que está no `files_touched`; se precisar de algo fora, pare e peça decisão (não saia do escopo).

5. **Rode os testes** (green): o teste de regressão agora passa, e a suíte existente continua passando. Se um teste existente quebrar, aplique a regra — investigue se a regra mudou (ajuste com justificativa) ou se você quebrou algo (corrija). Nunca delete/comente/skipe.

---

## Fase 6 — Validar diff, marcar e commitar

1. Rode `git diff --name-only` e confirme que tudo bate com `files_touched` (exceto o próprio `FIX.md`). Se algo escapou, reverta ou peça decisão.
2. Marque o `FIX.md`: status `in-progress` → `done`, e marque o teste de regressão como adicionado.
3. Commit na branch `fix/{slug}`, com relatório no corpo:
   ```
   git add {files_touched} docs/changes/{pasta}/FIX.md
   git commit -F - <<'EOF'
   fix({slug}): {título curto}

   ## Causa raiz
   {resumo}

   ## Correção
   {o que mudou}

   ## Teste de regressão
   {o caso coberto}

   ## Rollback
   {reverter o commit; risco}
   EOF
   ```

---

## Fase 7 — Confirmação e próximo passo

Mostre, conciso:

1. Causa raiz e o que foi corrigido (1-2 frases).
2. Branch (`fix/{slug}`) e status do `FIX.md` (`done`).
3. Resultado dos testes (regressão passa, suíte ok).
4. **Como revisar:** `git diff main...fix/{slug}`
5. **Próximo passo:** `/archive {slug}` para registrar no CHANGELOG e atualizar doc (se o comportamento corrigido estava documentado), depois merge final na main:
   ```
   git checkout main && git pull
   git merge --squash fix/{slug}
   git commit -m "fix({slug}): {título}"
   git push
   ```

Não despeje o diff inteiro — o usuário roda o comando se quiser.

---

## Notas de instalação

Salve como **`.claude/commands/fix.md`**. Invoque com `/fix <slug>`.

O `/fix` condensa diagnóstico + plano + implementação num único comando porque a correção é uma unidade de trabalho — não há decomposição em tasks nem worktrees paralelas. O `FIX.md` faz o papel de SPEC + TASK ao mesmo tempo. Por isso o fluxo do fix não usa `/spec`, `/tasks`, `/preparar-lote` nem `/approve`.

`allowed-tools` inclui `Bash` amplo (rodar testes, git, migrate) e `WebSearch`/`WebFetch` (confirmar comportamento de bibliotecas durante o diagnóstico). As guardas são comportamentais: causa raiz antes de corrigir, teste de regressão obrigatório, `files_touched`, gate de complexidade.

O gate de complexidade da Fase 3 é importante: ele impede que uma correção que cresceu silenciosamente passe pelo fluxo leve sem o planejamento que uma feature merece. Quando dispara, o diagnóstico já feito não se perde — fica no `FIX.md` como ponto de partida para o `/prd`.

Modelo recomendado: diagnóstico de causa raiz e implementação se beneficiam do modelo mais forte disponível na sessão.
