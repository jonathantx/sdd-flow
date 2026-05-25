# SDD Workflow v2

Um fluxo **Spec-Driven Development** local-first: cada mudança vira um processo
rastreável (`ideia → PRD → SPEC → tasks → implementação → archive`), com o estado
vivendo em Markdown versionado no Git — sem board externo.

A v2 adiciona, sobre a base original:

- **Skills de stack** (`node-typescript`, `php-laravel`, `react`, `svelte`) — bases
  de conhecimento técnico que o agente carrega para **não alucinar** e gerar código
  no padrão da sua stack.
- **Multi-LLM** — uma fonte-única gera adaptadores para **Claude, Codex e Gemini**.
- **`/analyze`** — detecta as stacks de um repositório existente (ou faz bootstrap
  de um projeto novo) e ativa as skills certas.
- **Enforcement leve** — `sdd doctor`, `sdd lint` e `spec-hash` (detecção de drift).
- **Fumadocs + Scalar** — site de documentação e referência de API (mantidos da v1).

---

## Começando em 5 passos (para qualquer dev, inclusive júnior)

```bash
# 1. Instale o kit no seu projeto (Claude + todas as stacks + docs)
bash install.sh --all

# 2. No seu agente de IA, descubra as stacks e ative as skills
/analyze

# 3. Capture uma ideia (entrevista curta, uma pergunta por vez)
/ideia "permitir exportar relatório em PDF"

# 4. Siga o fluxo guiado
/prd <slug>     →  /approve <slug>
/spec <slug>    →  /approve <slug>
/tasks <slug>
/run-all <slug>     # ou /preparar-lote para revisão por lote
/archive <slug>

# 5. Sempre que tiver dúvida da saúde da instalação
.sdd/bin/sdd doctor
```

Não sabe a stack? Tudo bem — o `/analyze` te diz o que encontrou e o agente
passa a seguir as boas práticas dela automaticamente. Você não precisa dominar
a stack para o código sair correto: a skill é a base de conhecimento.

> 📘 **Primeira vez? Veja o [LIFECYCLE.md](./LIFECYCLE.md)** — manual passo a passo
> de instalar, atualizar e consertar, com a Regra de Ouro explicada.

---

## Conceito central: fonte-única → adaptadores

Você edita **apenas** `.sdd/workflow/` (comandos e skills). Um comando projeta
isso para cada ferramenta de IA:

```
.sdd/workflow/          ← VOCÊ EDITA AQUI (fonte-única)
├── commands/           ← /ideia, /prd, /spec, /tasks, /implement, /analyze ...
└── skills/
    ├── analyze-project/
    └── stacks/         ← node-typescript, php-laravel, react, svelte

      ↓  .sdd/bin/sdd sync --tools claude,codex,gemini

.claude/   .codex/   .gemini/     ← GERADOS (não edite à mão)
```

```bash
.sdd/bin/sdd sync --tools claude,codex,gemini
```

Acabou a duplicação `claude/` vs `generic/` da v1: uma fonte, três saídas.

---

## Skills de stack

Cada stack em `.sdd/workflow/skills/stacks/<nome>/` tem um `SKILL.md` (gatilho +
regras de ouro) e `references/` densos:

| Stack | Tipo | References principais |
|---|---|---|
| `node-typescript` | backend | architecture, api, persistence, testing, security, observability, conventions |
| `php-laravel` | backend | architecture, api, persistence, testing, security, observability, conventions |
| `react` | frontend | architecture, components, state, performance, accessibility, testing, conventions |
| `svelte` | frontend | architecture, components, state, performance, accessibility, testing, conventions |

Os comandos `/spec`, `/tasks` e `/implement` carregam automaticamente as skills
das stacks marcadas como ativas no `docs/explanation/constitution.md` (preenchido
pelo `/analyze`).

Para adicionar uma stack nova: copie a pasta de uma existente, mantenha os nomes
de arquivo e registre a âncora em
`.sdd/workflow/skills/analyze-project/scripts/detect-stack.sh`.

---

## CLI `sdd`

```
sdd sync --tools claude,codex,gemini   Gera adaptadores da fonte-única
sdd spec-hash <tasks.md>               Grava SHA do PRD/SPEC (detecção de drift)
sdd check-drift <tasks.md>             Falha se PRD/SPEC mudaram desde as tasks
sdd lint                               Valida SKILL.md e estrutura das skills
sdd doctor                             Checagem de saúde da instalação
```

> **Roadmap (híbrido):** hoje a CLI é em shell, transparente e sem build. A
> interface de subcomandos foi desenhada para, no futuro, virar um binário Go
> (`ai-spec`-style) sem mudar como você a invoca.

---

## Documentação viva (Fumadocs + Scalar)

- `--fumadocs` → site navegável da pasta `docs/` (porta 8801 via Docker).
- `--scalar` → referência interativa de API a partir de OpenAPI (porta 8802).

Mantidos da v1, integrados ao `docker-compose.sdd.yml` gerado.
