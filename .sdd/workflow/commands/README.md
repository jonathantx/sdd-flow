# SDD — Spec-Driven Development

> Fluxo de desenvolvimento com IA, local-first, onde cada mudança no sistema nasce de uma especificação versionada e termina em documentação atualizada. Sem board externo — o estado vive nos arquivos.

---

## O que é

O SDD transforma cada alteração no código em uma **change** rastreável, que passa por etapas claras: ideia → especificação → tasks → implementação → documentação. Agentes de IA (Claude Code, Codex, Gemini) executam cada etapa via comandos `/`, sempre dentro de trilhos definidos por você.

O objetivo: aproveitar a velocidade da IA sem perder controle, rastreabilidade nem documentação.

---

## Conceitos-chave

- **Change** — qualquer alteração no sistema. Tem três pesos: `feature` (fluxo completo), `fix` (fluxo direto), `chore` (fluxo mínimo).
- **Artefatos** — arquivos `.md` versionados que descrevem a change: ideia, PRD, SPEC, tasks. São a fonte de verdade.
- **Estado no frontmatter** — não há board. O `status` no YAML de cada arquivo é onde a change "está".
- **Branch por change** — toda change vive em sua própria branch (`feat/slug`, `fix/slug`, `chore/slug`). A `main` recebe um commit limpo por change no final.
- **Constitution** — `docs/explanation/constitution.md` define as regras que todo agente segue (stack, padrões, segurança, anti-alucinação).
- **Patterns** — `docs/patterns/` tem exemplares reais do seu código. A IA aprende por exemplo, não por regra abstrata.

---

## Estrutura de pastas

```
docs/
├── CHANGELOG.md                    # registro de tudo que foi entregue
├── explanation/
│   └── constitution.md             # as regras do projeto
├── patterns/                       # exemplares canônicos (Service, Controller…)
├── adr/                            # decisões arquiteturais (ADR-001…)
├── guides/                         # como usar (how-to)
├── reference/                      # API, permissions, schemas
└── changes/
    └── feat-2026-05-minha-feature/
        ├── README.md               # dossiê vivo da change
        ├── 00-idea.md
        ├── PRD.md
        ├── SPEC.md
        └── tasks/
            ├── TASK-001-*.md
            └── TASK-002-*.md
```

---

## Setup inicial (uma vez só)

1. Crie `docs/explanation/constitution.md` com stack, padrões, segurança e regras anti-alucinação.
2. Crie 3-4 arquivos em `docs/patterns/` apontando para exemplares reais do seu código.
3. Coloque os comandos em `.claude/commands/` (versionados, compartilhados com o time).
4. (Opcional) Configure preview do VitePress em PRs, se quiser revisão renderizada.

---

## Comandos

| Comando | O que faz |
|---|---|
| `/ideia <texto>` | Entrevista curta, classifica em feat/fix/chore e cria o `00-idea.md` |
| `/prd <slug>` | Gera o PRD (requisitos de negócio) com pesquisa na codebase e web |
| `/spec <slug>` | Gera a SPEC (plano técnico) + ADRs, com estratégia de rollback |
| `/approve <slug>` | Marca PRD/SPEC como `approved` após sua revisão (mexe em frontmatter de documentos) |
| `/tasks <slug>` | Decompõe a SPEC em tasks pequenas com dependências, paralelismo e gera o `03-PLAN-EXEC.md` |
| `/run-all <slug>` | **Autônomo:** executa todas as tasks sequencialmente, 1 commit por task, sem pausa entre elas |
| `/preparar-lote <slug>` | **Manual:** orquestra a implementação em lotes; prepara worktrees e pausa para revisão |
| `/implement <TASK>` | Implementa uma task respeitando sua fronteira de arquivos (usado pelo `/preparar-lote`) |
| `/approve-task <TASK>` | Após revisar, mergeia a task, marca `done` e limpa worktree+banco (usado pelo `/preparar-lote`) |
| `/fix <slug>` | Fluxo direto de correção (diagnóstico + plano + implementação) |
| `/status [slug]` | Mostra onde cada change está e qual a próxima ação (read-only) |
| `/archive <slug>` | Fecha a change: dossiê final, sincroniza docs e atualiza CHANGELOG |

---

## Fluxo 1a — Feature (manual, com revisão por lote)

Para algo novo, com decisões de produto e técnicas. Você revisa cada lote antes do próximo.

```bash
/ideia "permitir exportar inquérito em PDF"   # → 00-idea.md, classifica como feature
/prd export-inquerito-pdf                      # → PRD.md (você revisa)
/approve export-inquerito-pdf                  # → PRD marcado como approved
/spec export-inquerito-pdf                     # → SPEC.md + ADRs (você revisa)
/approve export-inquerito-pdf                  # → SPEC marcada como approved
/tasks export-inquerito-pdf                    # → TASK-001…N + 03-PLAN-EXEC.md

# implementação orquestrada em lotes:
/preparar-lote export-inquerito-pdf                # prepara o lote, entrega comandos, pausa
/implement TASK-001                            # implementa (em worktree ou in-place)
/approve-task TASK-001                         # revisa → mergeia → done → limpa
/preparar-lote export-inquerito-pdf                # próximo lote… (repete até acabar)

/archive export-inquerito-pdf                  # dossiê + docs + changelog
# merge final na main (squash)
```

O `/preparar-lote` calcula sozinho a ordem e o que pode rodar em paralelo. Você só revisa e aprova cada lote.

---

## Fluxo 1b — Feature (autônomo, sem pausa entre tasks)

Mesmo fluxo até `/tasks`. Em vez de orquestrar lote a lote, dispare o executor autônomo: ele percorre o DAG na ordem topológica, implementa todas as tasks sequencialmente em `feat/{slug}`, com 1 commit por task, e só **para** se houver ambiguidade real, teste sem solução, files_touched violation ou dependência não satisfeita. É **retomável**: depois de você resolver, basta rodar o comando de novo e ele continua de onde parou.

```bash
/ideia → /prd → /approve → /spec → /approve → /tasks               # idêntico ao Fluxo 1a

/run-all export-inquerito-pdf                  # roda tudo: TASK-001 → 002 → 003 → …
# se parar por ambiguidade/escopo/teste: você responde/decide e roda /run-all de novo

/archive export-inquerito-pdf                  # quando todas as tasks ficam done
# merge final na main (squash)
```

Quando usar cada um:
- **`/preparar-lote`** — quando você quer paralelismo real (worktrees em terminais separados), revisar cada lote, ou intervir entre tasks.
- **`/run-all`** — quando você confia no plano e prefere ver o resultado de uma vez (sequencial, in-place, sem pausa de revisão).

---

## Fluxo 2 — Fix (direto)

Para corrigir comportamento existente. Sem PRD, sem decomposição.

```bash
/ideia "o PDF sai com acento quebrado"   # → classifica como fix
/fix pdf-encoding                         # → FIX.md (diagnóstico + plano) e implementa
/archive pdf-encoding                     # → changelog + doc se necessário
# merge final
```

---

## Fluxo 3 — Chore (mínimo)

Para manutenção sem decisão (deps, refactor, config). Muitas vezes só um commit.

```bash
/ideia "bump laravel 11.4 → 11.5"   # → classifica como chore
# se trivial: implementa e commita direto
# se relevante documentar: gera NOTE.md, depois /archive
```

---

## Regras de ouro

1. **A SPEC é a fonte de verdade.** O código materializa a spec.
2. **Contexto enxuto.** Cada etapa é uma janela nova, só com o necessário.
3. **`files_touched` é fronteira dura.** Um agente nunca toca arquivo fora do escopo da task.
4. **Pare em ambiguidade.** A IA pergunta em vez de inventar.
5. **Teste é intocável.** Nunca deletar/comentar/skipar para fazer outro passar.
6. **Recurso compartilhado → sequencial.** Migrations, rotas e configs globais não rodam em paralelo.
7. **Rollback não é opcional.** Toda SPEC responde "como desfazer".
8. **Doc anda junto.** Nenhuma change fecha sem `/archive`.
9. **Doc publicada precisa renderizar.** Markdown em `docs/` precisa de `title` no frontmatter; se Fumadocs/Scalar estiverem instalados, `/archive` valida o preview e o OpenAPI antes do commit.
10. **Manual antes de automático.** Só automatize o que doeu 3 vezes.
11. **Revise cada lote (Fluxo 1a) ou o resultado final (Fluxo 1b).** A IA implementa; você aprova — entre cada lote no manual, ou no fim do batch quando rodando autônomo.

---

## Estados (referência rápida)

| Artefato | Estados |
|---|---|
| PRD | `draft` → `approved` |
| SPEC | `draft` → `validated` |
| TASK | `ready` → `in-progress` → `in-review` → `done` (ou `blocked`) |
| Change (README) | `draft` → `in-progress` → `delivered` |

Rode `/status` a qualquer momento para ver tudo de uma vez.

---

## Em uma frase

Você descreve o que quer (`/ideia`), valida o plano que a IA propõe (`/prd`, `/spec`, `/tasks`), deixa a IA implementar — sob supervisão (`/preparar-lote` + `/implement` + `/approve-task`) ou em batch autônomo (`/run-all`) — e fecha com a documentação em dia (`/archive`). O Git e os arquivos guardam todo o histórico — sem board, sem ferramenta externa.
