---
description: Implementa uma task específica respeitando files_touched, valida depends_on, roda testes em banco isolado e gera relatório de implementação
argument-hint: <TASK-NNN> [slug]
allowed-tools: Bash, Read, Grep, Glob, Write, Edit
---

# Comando /implement

Você implementa **uma única task** do workflow Spec-Driven local, seguindo à risca o escopo definido no `TASK-NNN.md`. Você respeita a fronteira `files_touched`, valida dependências, roda testes, e nunca sai do escopo. Ao terminar, deixa a branch da task pronta para revisão — não mergeia nada (isso é o `/approve-task`).

> Para rodar **todas** as tasks em sequência, sem pausar entre elas, use `/run-all <slug>` em vez de chamar `/implement` task a task.

Argumento recebido: `$ARGUMENTS` (ex: `TASK-002` ou `TASK-002 export-inquerito-pdf`)

Contexto carregado automaticamente:
- Branch atual: !`git branch --show-current 2>/dev/null || echo "(fora de repo git)"`
- Working tree: !`git status --short 2>/dev/null || echo "(fora de repo git)"`
- Data: !`date +%Y-%m-%d`
- Stacks ativas (do constitution): !`grep -A20 '## Active Stacks' docs/explanation/constitution.md 2>/dev/null | grep -oE 'skill: `[a-z0-9-]+`' | sed 's/skill: //; s/`//g' | sort -u || echo "(nenhuma — rode /analyze)"`

---

## Carregar a base de conhecimento da stack (anti-hallucination)

**Antes de escrever qualquer linha de código**, carregue as skills das stacks ativas:

1. Identifique as skills ativas (listadas acima, vindas de `## Active Stacks` no `constitution.md`).
2. Para cada skill ativa, leia o `SKILL.md` em `skills/stacks/<skill>/SKILL.md` (ou `.claude/skills/stacks/<skill>/`).
3. Pelos arquivos que a task vai tocar (`files_touched`), abra os `references/` relevantes daquela skill — ex.: tocou rota/controller → `api.md`; tocou model/migration → `persistence.md`; tocou componente → `components.md`; sempre que houver teste → `testing.md`.
4. **Siga o que a skill define.** Ela é a fonte de verdade técnica da stack: convenções, padrões, segurança. Se a skill contradiz um impulso seu, a skill vence. Isso é o que impede alucinação de API/sintaxe.

Se não houver skill ativa para a stack desta task, avise o usuário e sugira rodar `/analyze` antes de prosseguir.

---

## Regras invioláveis (da constitution)

1. **`files_touched` é a fronteira dura.** Antes de editar qualquer arquivo, confirme que ele está em `files_touched`. Se precisar tocar algo fora, PARE — não saia do escopo. (O próprio `TASK-NNN.md` é exceção: você o edita para bookkeeping de status/checkboxes.)
2. **Anti-hallucination.** Nunca invente nome de método/classe/coluna — faça `grep` antes. Nunca crie endpoint, env var, config ou rota que a SPEC não previu. Nunca assuma schema; leia a migration.
3. **Pare em ambiguidades.** Se algo na task está ambíguo ou falta informação, PARE e pergunte ao usuário (encerre o turno). Não improvise.
4. **Testes são intocáveis.** Nunca delete, comente ou skipe um teste para fazer outro passar. Se um teste existente quebra: investigue se a regra mudou (atualize-o com justificativa no commit) ou se você quebrou algo (corrija o código).
5. **Implemente só esta task.** Nada de adiantar trabalho de outra task, mesmo que pareça conveniente.

---

## Fase 0 — Resolver a task

1. Extraia o ID (`TASK-NNN`) de `$ARGUMENTS`. Se houver slug, use-o para localizar a pasta; senão, procure em `docs/changes/feat-*/tasks/` o arquivo `TASK-NNN-*.md`.
2. Se ambíguo (várias features com a mesma TASK-NNN) ou não encontrado, liste as opções e pergunte. Encerre o turno.
3. Leia o `TASK-NNN.md` inteiro — frontmatter e corpo.

---

## Fase 1 — Validar pré-condições

1. **Status da task.** Confira `status` no frontmatter:
   - `ready`: prossiga.
   - `in-progress`: avise que a task já estava em andamento; pergunte se quer retomar.
   - `in-review`: avise que já foi implementada e aguarda revisão; pergunte se quer reimplementar.
   - `done`: avise que já está concluída. Encerre.
   - `blocked`: mostre o motivo do bloqueio anterior (se registrado) e pergunte se as condições mudaram.

2. **Dependências (`depends_on`).** Para cada ID em `depends_on`, leia o `status` do TASK correspondente. Todas devem estar `done`.
   - Se alguma não está `done`: PARE. Avise quais dependências faltam e oriente a implementá-las primeiro. Encerre o turno. **Esta validação é bloqueante** — implementar sobre dependência incompleta gera retrabalho em cascata.

3. **SPEC.** Confirme que o `02-SPEC.md` referenciado existe e está `validated`. Se draft, avise e peça confirmação antes de prosseguir.

---

## Fase 2 — Preparar o ambiente de trabalho

Detecte onde você está (branch atual, mostrada acima) e escolha o modo:

**Caso A — já está numa branch de task** (`feat/{slug}/task-NNN` correspondente a esta task): ótimo, trabalhe no diretório atual. Provavelmente foi o `/preparar-lote` que preparou a worktree.

**Caso B — está na branch da feature** (`feat/{slug}`): pergunte ao usuário qual modo (encerre o turno após perguntar, a menos que ele já tenha sinalizado):
- **Worktree isolada (recomendado para paralelismo):** mostre os comandos para ele criar e entrar na worktree, e peça para rodar `/implement` lá dentro:
  ```
  git worktree add ../{repo}-task-NNN -b feat/{slug}/task-NNN
  cd ../{repo}-task-NNN
  # configure banco isolado (ver abaixo), depois: claude → /implement TASK-NNN
  ```
- **In-place (sequencial, sem isolamento):** crie a branch da task no diretório atual:
  ```
  git checkout -b feat/{slug}/task-NNN
  ```
  Use este modo só quando a task roda sozinha (sequential) e você não precisa de paralelismo.

**Caso C — está em outra branch (main, ou branch de outra feature):** PARE e avise. Não implemente fora do contexto da feature. Oriente a fazer checkout da branch correta.

**Banco isolado (se a task toca dados).** Se `shared_resources` inclui `migrations` ou `files_touched` inclui migrations/models, configure um banco isolado para não colidir com outras worktrees (adapte à stack do projeto):
```
# no .env da worktree (não commitar):
DB_DATABASE={slug-sanitizado}_t{NNN}
# criar e migrar:
mysql -e "CREATE DATABASE IF NOT EXISTS {slug-sanitizado}_t{NNN}"
php artisan migrate:fresh
```

Se houver mudanças não commitadas que impeçam operações de branch (working tree mostrado acima), pare e avise — não force.

---

## Fase 3 — Carregar contexto de implementação

Leia, nesta ordem, mantendo o contexto enxuto (só o necessário para esta task):

1. **`TASK-NNN.md`** — o escopo, critérios de aceite, restrições, files_touched, DoD.
2. **`02-SPEC.md`** (referenciado no frontmatter da task) — para entender a arquitetura geral, mas implemente só a fatia desta task.
3. **ADRs referenciados** na SPEC que sejam relevantes a esta task — para respeitar decisões já tomadas.
4. **`docs/explanation/constitution.md`** — stack, padrões, segurança, anti-hallucination, regras de teste.
5. **Patterns relevantes** em `docs/patterns/` — leia o pattern do tipo de componente que esta task cria (service.md, controller.md, etc). Seu código deve parecer com o exemplar canônico.
6. **Arquivos reais** que a task vai modificar (não criar) — leia antes de editar, para não quebrar o existente.

---

## Fase 4 — Marcar início

Edite o frontmatter do `TASK-NNN.md`: `status: ready` → `status: in-progress`. (Não commite ainda; isso entra no commit final.)

---

## Fase 5 — Implementar

Implemente o escopo da task seguindo o corpo do `TASK-NNN.md`, restrito aos `files_touched`.

Durante a implementação, a cada arquivo que for tocar:
- **Confirme que está em `files_touched`.** Se não está e você acha que precisa, PARE. Mostre ao usuário:
  ```
  ⚠ Preciso tocar {arquivo}, mas não está em files_touched.
  Opções:
    1. Remover essa necessidade (manter no escopo da task)
    2. Adicionar ao files_touched desta task + justificar
    3. Criar uma task separada para isso
  ```
  Encerre o turno e espere a decisão. Não decida sozinho.
- **Siga os patterns.** Estrutura, nomes, organização conforme `docs/patterns/`.
- **Respeite a constitution.** Authorize via Policy, valide inputs via Form Request, nunca logue dados sensíveis, etc.
- **Grep antes de referenciar.** Qualquer método/classe/coluna que você usa de outra parte do código — confirme que existe com grep antes.

Se em qualquer ponto surgir ambiguidade que a SPEC e a task não resolvem, PARE e pergunte.

---

## Fase 6 — Testes

1. Escreva/atualize os testes que a task exige (critérios de aceite costumam mapear para asserts).
2. Rode a suíte relevante (no banco isolado, se configurado):
   ```
   php artisan test --filter={escopo relevante}
   ```
3. **Se um teste existente quebrar:** aplique a regra da constitution — investigue se a regra de negócio mudou (atualize o teste, justifique no commit) ou se você quebrou algo (corrija o código). NUNCA delete/comente/skipe.
4. Não prossiga enquanto os testes da task não passarem. Se não conseguir fazer passar e suspeitar de problema na própria task/SPEC, marque `status: blocked`, registre o motivo, e avise o usuário.

---

## Fase 7 — Validar o diff contra files_touched

1. Rode `git status --short` e `git diff --name-only` para listar tudo que mudou.
2. **Compare com `files_touched`.** Todo arquivo modificado (exceto o próprio `TASK-NNN.md`) deve estar coberto por `files_touched`.
   - Se algo escapou: ou reverta (saiu do escopo) ou pare e peça ao usuário para decidir (adicionar ao files_touched + justificar, ou criar task separada).
3. Confirme que nenhum arquivo de `files_touched` ficou sem ser tocado sem motivo — se a task previa criar algo que você não criou, ou está incompleta ou o files_touched estava errado.

---

## Fase 8 — Marcar conclusão no TASK.md

No `TASK-NNN.md`:
1. Marque os **critérios de aceite** atendidos (`- [x]`).
2. Marque os itens do **DoD** atendidos. Itens não-aplicáveis: marque com nota (ex: `- [x] Observabilidade — N/A nesta task`).
3. Mude o frontmatter `status: in-progress` → `status: in-review`.

---

## Fase 9 — Commit

Faça um único commit na branch da task, com **relatório estruturado no corpo**, em conventional commits e slug como escopo:

```
git add {arquivos do files_touched} docs/changes/{pasta}/tasks/TASK-NNN-*.md
git commit -F - <<'EOF'
feat({slug}): TASK-NNN — {título curto}

## O que foi feito
- {bullets}

## Decisões tomadas
- {decisões, com referência a ADR se aplicável}

## Arquivos alterados
{lista; confirma que bate com files_touched}

## Pendências
{nenhuma, ou lista}

## Riscos / atenção para o revisor
{pontos de atenção}

## Como testar manualmente
{passos}

## DoD
- [x] critérios marcados
- [x] testes passando
- [x] sem TODO temporário
- [x] segurança conforme constitution
- [x] files_touched bate com diff
- [x] nenhum teste deletado/comentado/skipado
EOF
```

Use o tipo de commit conforme o tipo de trabalho (`feat`, `fix`, `chore`, `test`, `refactor`).

---

## Fase 10 — Confirmação e próximo passo

Mostre ao usuário, de forma concisa:

1. Task implementada e seu novo status (`in-review`).
2. Branch da task (`feat/{slug}/task-NNN`).
3. **Relatório resumido** (mesmas seções do commit, mas curto) — isto é o que ele revisa.
4. **Como revisar o diff:**
   ```
   git diff feat/{slug}...feat/{slug}/task-NNN
   ```
5. Resultado dos testes (passou/quantos).
6. Se algo ficou `blocked` ou se você parou por ambiguidade/escopo, deixe isso claro no topo.
7. **Próximo passo:** após revisar, aprove com `/approve-task TASK-NNN` (que mergeia na branch da feature, marca `done` e limpa a worktree/banco). Ou rode `/preparar-lote {slug}` para continuar a orquestração do próximo lote.

Não despeje o diff inteiro — o usuário roda o comando de diff se quiser ver tudo.

---

## Notas de instalação

Salve como **`.claude/commands/implement.md`**. Invoque com `/implement TASK-NNN [slug]`.

`allowed-tools` inclui `Bash` amplo porque a implementação precisa rodar testes, composer, artisan, git e o setup de banco — restringir demais quebraria a flexibilidade entre stacks. As guardas reais deste comando são comportamentais (`files_touched`, anti-hallucination, regras de teste), não de tooling. Se quiser endurecer, restrinja `Bash` aos comandos da sua stack (ex: `Bash(git:*)`, `Bash(php artisan:*)`, `Bash(composer:*)`, `Bash(mysql:*)`).

Este comando é o executor que o `/preparar-lote` dispara em cada worktree. Quando chamado pelo orquestrador, o ambiente (worktree + banco isolado) já vem preparado, e o `/implement` cai direto no Caso A da Fase 2.

Modelo recomendado: use o modelo mais forte disponível para implementação de qualidade (Opus, se disponível na sessão). Tasks `small` podem rodar em modelo mais barato; `medium`/`large` se beneficiam do mais forte.
