---
description: Revisa o diff de uma change antes do merge — correção, segurança, testes e aderência às convenções da skill da stack ativa. Read-only, produz um relatório com severidades.
argument-hint: <slug | branch | vazio para o diff atual>
allowed-tools: Bash(git:*), Bash(date:*), Bash(ls:*), Bash(find:*), Bash(grep:*), Read, Grep, Glob
---

# Comando /review

Você é o **revisor** do workflow Spec-Driven local. Sua função é olhar o que mudou (o diff) com olhar crítico, ANTES do merge, e produzir um relatório de achados classificados por severidade. Você **não corrige nada** — só revisa e reporta. A correção é decisão de quem implementou.

Argumento (slug, branch, ou vazio): `$ARGUMENTS`

Contexto:
- Branch atual: !`git branch --show-current 2>/dev/null || echo "(fora de repo git)"`
- Data: !`date +%Y-%m-%d`
- Stacks ativas (do constitution): !`grep -A20 '## Active Stacks' docs/explanation/constitution.md 2>/dev/null | grep -oE 'skill: `[a-z0-9-]+`' | sed 's/skill: //; s/`//g' | sort -u || echo "(nenhuma — rode /analyze)"`

---

## Carregar a base de conhecimento da stack

Leia o `SKILL.md` e os `references/` das stacks ativas (sobretudo `conventions.md`, `security.md`, `testing.md`, e o reference da camada tocada). **A skill é o critério de revisão**: você avalia o diff contra os padrões dela. Sem skill ativa, revise pelos princípios gerais e avise que `/analyze` daria uma revisão mais precisa.

---

## Fase 0 — Determinar o diff a revisar

1. Se `$ARGUMENTS` é um slug → ache a pasta `docs/changes/*-{slug}` e a branch correspondente (`feat/{slug}`, `fix/{slug}`, `chore/{slug}`). Diff = `git diff main...<branch>`.
2. Se é uma branch → `git diff main...<branch>`.
3. Se vazio → revise o working tree atual: `git diff` + `git diff --staged`.
4. Liste os arquivos do diff (`git diff --name-only ...`) e confirme o alvo com o usuário se houver ambiguidade.

---

## Fase 1 — Ler antes de julgar

1. Leia o diff inteiro.
2. Para arquivos muito alterados, leia o arquivo completo (não só o hunk) — contexto evita falso positivo.
3. Se houver `SPEC`/`FIX.md`/`tasks`, leia para saber qual era a intenção. Revisão é "isto cumpre a intenção corretamente?", não "eu faria diferente".

---

## Fase 2 — Eixos de revisão

Avalie cada eixo. Reporte só achados reais — não invente problema para preencher.

1. **Correção** — o código faz o que a SPEC/FIX pediu? Edge cases, off-by-one, null/undefined, condições de corrida, erros engolidos.
2. **Segurança** — contra `references/security.md` da stack: validação de entrada, injeção, autorização, secrets, dados sensíveis em log. (Foque aqui se a change toca auth, entrada de usuário, query, upload.)
3. **Testes** — existe teste para o que mudou? Testa comportamento e não implementação? Algum teste foi deletado/skipado/enfraquecido?
4. **Aderência à stack** — segue `conventions.md` e os padrões de `architecture.md` da skill? Inventou abstração/dependência que destoa do resto?
5. **Escopo** — o diff bate com `files_touched`? Tem mudança fora do escopo declarado (refactor oportunista, feature escondida)?
6. **Legibilidade/manutenção** — nomes, duplicação, função grande demais, complexidade desnecessária.

---

## Fase 3 — Relatório

Produza um relatório conciso, agrupado por severidade. NÃO despeje o diff.

```markdown
# Review — {alvo} ({data})

Stacks: {skills usadas como critério}
Arquivos revisados: {n}

## 🔴 Blocker ({n})   — impede o merge
- [arquivo:linha] {problema} → {por que é blocker} → {sugestão concreta}

## 🟡 Warning ({n})   — corrigir antes de mergear, mas não trava sozinho
- [arquivo:linha] {problema} → {sugestão}

## 🔵 Nit ({n})       — opcional, melhoria
- [arquivo:linha] {sugestão}

## ✅ Pontos positivos
- {o que ficou bom — reconheça}

## Veredito
{APROVADO | APROVADO COM RESSALVAS | MUDANÇAS NECESSÁRIAS}
{1-2 frases de fechamento e próximo passo}
```

Regras do relatório:
- Sempre cite **arquivo:linha**. Achado sem localização é ruído.
- Toda crítica vem com **sugestão concreta** do que fazer.
- Se não houver blocker, diga claramente que está liberado para merge.
- Seja específico e respeitoso — o objetivo é melhorar o código, não exibir conhecimento.

---

## Notas de instalação

Fonte-única `.sdd/workflow/commands/review.md`. Após `sdd sync`, vira `/review` no Claude, Codex e Gemini. Read-only por design: `allowed-tools` não inclui Write/Edit.

Modelo recomendado: revisão de correção e segurança se beneficia do modelo mais forte disponível.
