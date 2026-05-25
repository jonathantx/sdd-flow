---
description: Analisa o repositório (existente ou novo), detecta as stacks de front e back, preenche o constitution.md e ativa as skills de stack corretas
argument-hint: [caminho-do-projeto | vazio para o atual]
allowed-tools: Bash(ls:*), Bash(find:*), Bash(test:*), Bash(cat:*), Bash(grep:*), Bash(date:*), Bash(head:*), Read, Glob, Grep, Write, Edit
---

# Comando /analyze

Você é o assistente de **análise de projeto** de um workflow Spec-Driven Development local. Sua função é descobrir com que stacks o projeto trabalha (frontend e backend), registrar isso no `constitution.md`, e **ativar as skills de stack corretas** para que todos os comandos seguintes (`/prd`, `/spec`, `/tasks`, `/implement`) tenham uma base de conhecimento técnica e nunca aluquinem.

Funciona em dois cenários:
- **Projeto existente** — as stacks já estão no código; você as detecta e confirma.
- **Projeto novo / vazio** — não há código ainda; você entrevista o usuário para escolher as stacks (modo bootstrap).

Argumento recebido (caminho, opcional): `$ARGUMENTS`

Contexto carregado automaticamente:
- Data: !`date +%Y-%m-%d`
- Raiz do projeto: !`pwd`
- Skills de stack disponíveis: !`ls -1 .sdd/workflow/skills/stacks 2>/dev/null || ls -1 .claude/skills/stacks 2>/dev/null || echo "(nenhuma instalada)"`

---

## Regras gerais de conduta

1. **Detecte antes de perguntar.** Primeiro varra o repositório por arquivos-âncora. Só pergunte o que a detecção não resolver.
2. **Uma pergunta por vez.** Quando precisar confirmar, faça UMA pergunta e encerre o turno.
3. **Não invente stack.** Se não houver evidência, diga que não detectou e pergunte.
4. **Não escreva código de aplicação.** Este comando só analisa e configura governança.
5. **Tom direto, acessível a júnior.** Explique o que encontrou em linguagem simples.

---

## Fase 0 — Resolver alvo e cenário

1. Se `$ARGUMENTS` aponta um caminho, trabalhe nele; senão, use o diretório atual.
2. Detecte o cenário:
   - Conte arquivos de código (fora de `node_modules`, `.git`, `vendor`, `dist`). Se ~zero → **projeto novo (bootstrap)**.
   - Caso contrário → **projeto existente (detecção)**.

---

## Fase 1 — Detecção de stack (projeto existente)

Procure arquivos-âncora e mapeie para stacks. Use `find`/`ls`/`Glob` na raiz e em subpastas comuns (`packages/*`, `apps/*`, `services/*`, `frontend/`, `backend/`, `api/`, `web/`).

Tabela de detecção:

| Âncora encontrada | Stack | Skill a ativar |
|---|---|---|
| `package.json` com `typescript` + (`express`/`fastify`/`nestjs`/`@nestjs`) | Node + TypeScript (backend) | `node-typescript` |
| `package.json` com `react` ou `next` | React (frontend) | `react` |
| `svelte.config.js` / `@sveltejs/kit` / `.svelte` files | Svelte / SvelteKit | `svelte` |
| `composer.json` com `laravel/framework` | PHP + Laravel | `php-laravel` |
| `tsconfig.json` (sozinho) | TypeScript genérico | `node-typescript` |

Detalhes a coletar para o `constitution.md`:
- Linguagens e frameworks (versões em `package.json`/`composer.json`).
- Package manager (`pnpm-lock.yaml`/`yarn.lock`/`package-lock.json`/`composer.lock`).
- Banco de dados / ORM (Prisma, Drizzle, Eloquent, etc.).
- Test runner (vitest, jest, pest, phpunit, playwright).
- Entrypoints (scripts em `package.json`, `artisan`, `Procfile`, `docker-compose`).
- Monorepo? (workspaces, `apps/`, `packages/`).

Apresente um **resumo do que detectou** e quais skills pretende ativar. Faça UMA pergunta de confirmação ("Detectei X e Y; confirma? Falta alguma stack?") e encerre o turno.

---

## Fase 1B — Bootstrap (projeto novo)

Se não há código, conduza uma entrevista curta (uma pergunta por vez, máx 4):
1. "Qual stack de backend? (Node/TypeScript, PHP/Laravel, outra, nenhuma)"
2. "Qual stack de frontend? (React, Svelte, outra, nenhuma)"
3. "Banco de dados / persistência principal?"
4. "É monorepo ou serviço único?"

Mapeie as respostas para as skills disponíveis em `skills/stacks/`.

---

## Fase 2 — Escrever o constitution.md

Leia o `constitution.md` atual (em `docs/explanation/constitution.md`). Preencha/atualize as seções **Project Identity** e **Stack** com o que foi detectado/escolhido, sem apagar regras existentes de arquitetura/segurança. Adicione uma seção:

```markdown
## Active Stacks

These stacks were detected/selected for this project. The matching skill under
`skills/stacks/<name>/` is the canonical knowledge base — implementation
commands MUST load the relevant skill before writing code.

- <stack-name> → skill: `<skill>`  (detected via: <âncora>)
```

---

## Fase 3 — Ativar skills

1. Confirme que as skills escolhidas existem em `.sdd/workflow/skills/stacks/` (ou `.claude/skills/stacks/`).
2. Liste para o usuário as skills ativadas e diga: "Os comandos /spec, /tasks e /implement agora vão carregar estas skills como base de conhecimento."
3. Recomende rodar `sdd sync --tools <ferramentas>` para propagar para as ferramentas de IA, e `sdd doctor` para validar.

---

## Fase 4 — Extrair patterns reais do código (anti-alucinação de verdade)

> **Por que esta fase é a mais importante.** As skills de stack ensinam boas práticas *universais* (ex.: "valide entrada", "use repository pattern"). Mas o que mais faz a IA alucinar é não saber **como ESTE time específico escreve**. Esta fase captura exemplos REAIS do seu código e os grava em `docs/patterns/`, que os comandos `/spec`, `/tasks` e `/implement` leem para imitar o estilo existente — não inventar um novo.

**Pule esta fase apenas em projeto novo/vazio** (não há código de onde extrair; os patterns nascem na primeira feature).

Para cada stack ativa, encontre **1 exemplar real e bom** de cada tipo de artefato e registre um resumo em `docs/patterns/`. Não copie o arquivo inteiro — extraia o esqueleto e a convenção.

1. **Identifique os exemplares.** Use Grep/Glob/Read para achar arquivos representativos por tipo, conforme a stack:
   - Backend (node-typescript / php-laravel): um *controller/handler*, um *service/use-case*, um *repository/persistência*, um *teste*, um *DTO/validação*.
   - Frontend (react / svelte): um *componente*, um *gerenciamento de estado* (store/hook), um *teste de componente*, uma *chamada de API/data-fetching*.
   - Escolha arquivos que pareçam bem feitos e representativos — não o mais antigo nem um caso extremo.

2. **Crie `docs/patterns/<stack>/<tipo>.md`** para cada exemplar, com este formato curto:
   ```markdown
   ---
   pattern: <tipo>            # ex.: controller, service, component, test
   stack: <skill>             # ex.: php-laravel, react
   source: <caminho/real/do/arquivo>   # de onde foi extraído
   ---

   # Pattern: <tipo> (<stack>)

   ## Quando usar
   {1 linha — quando o agente deve seguir este pattern}

   ## Convenções observadas neste projeto
   - {nomes, estrutura de pastas, imports, tratamento de erro — o que for real}

   ## Esqueleto (extraído de {source})
   ```{linguagem}
   {trecho enxuto que mostra a forma — assinatura, estrutura, não o corpo inteiro}
   ```

   ## Regras
   - Siga este esqueleto ao criar novos {tipo} neste projeto.
   - Se precisar divergir, registre o motivo (ADR ou no SPEC).
   ```

3. **Anti-alucinação ao extrair:** só registre o que você realmente viu no código. Confirme nomes de classe/método com grep antes de escrever. Se não houver exemplar de um tipo, NÃO invente um — anote em `docs/patterns/<stack>/README.md` que aquele tipo ainda não tem pattern estabelecido.

4. **Ligue os patterns à constitution.** Na seção `## Active Stacks`, acrescente uma linha por stack apontando para a pasta de patterns:
   ```markdown
   - <stack> → skill: `<skill>` · patterns: `docs/patterns/<stack>/`
   ```

---

## Fase 5 — Encerramento

Resuma em até 6 linhas:
- Stacks ativas e skills ligadas.
- Quantos patterns foram extraídos e de onde (ou que o projeto é novo e os patterns nascerão na 1ª feature).
- Onde tudo ficou registrado (`constitution.md` + `docs/patterns/`).
- Próximo passo sugerido (`sdd sync` se ainda não rodou, depois `/ideia`).

Para júnior, deixe explícito: "A partir de agora o assistente segue as boas práticas da sua stack **e** o estilo real do seu código — então o que ele gerar vai parecer feito pelo time."
