# Ciclo de Vida — Manual de Instalar, Atualizar e Consertar

Este é o manual prático do SDD Workflow. Se você nunca usou, comece pela **Regra de
Ouro** e depois siga o cenário que combina com você. Tudo aqui funciona para
**qualquer stack** (Node, PHP, React, Svelte…) e **qualquer IA** (Claude, Codex, Gemini).

---

## 🥇 A Regra de Ouro (decore isto)

> **Você edita SÓ em `.sdd/workflow/`. Roda `sdd sync` para propagar. Roda `sdd doctor` para validar.**

Por quê? Porque as pastas `.claude/`, `.codex/` e `.gemini/` são **cópias geradas**
da sua fonte-única. Se você editar uma cópia direto, sua mudança **será apagada** no
próximo `sync`. Pense na fonte-única como o "caderno de receitas original" e nos
adaptadores como "fotocópias" — você escreve no original, e o `sync` refaz as cópias.

```
.sdd/workflow/   ← VOCÊ EDITA AQUI (o original)
      │
      │  sdd sync
      ▼
.claude/  .codex/  .gemini/   ← CÓPIAS (não edite à mão)
```

---

## 🆕 Cenário 1 — Instalar do zero (projeto novo OU existente)

Funciona igual para um projeto vazio ou um já cheio de código.

```bash
# 1. Entre na pasta do seu projeto
cd /caminho/do/seu-projeto

# 2. Instale, escolhendo as IAs que você usa
bash /caminho/do/sdd-new/install.sh --tools claude,codex,gemini
#    (ou --tools claude   /   --all para incluir Fumadocs + Scalar)

# 3. Valide a instalação
.sdd/bin/sdd doctor       # deve terminar com "Doctor concluído"
```

Depois, **dentro do seu agente de IA** (Claude/Codex/Gemini), rode uma vez:

```
/analyze
```

Isso detecta suas stacks (ou pergunta, se o projeto é novo) e liga as skills certas.
A partir daqui o assistente já segue as boas práticas da sua stack.

**Pronto.** Comece a trabalhar com `/ideia "o que você quer fazer"`.

---

## 🔄 Cenário 2 — Atualizar (quando o workflow evoluir)

Use isto quando você melhorar um comando ou skill, ou pegar uma versão nova do kit.
**Nunca apague a instalação para atualizar** — só re-sincronize.

```bash
# 1. (se o kit mudou) traga a nova versão da fonte para o projeto
#    — re-rode o install; ele atualiza .sdd/ sem apagar suas docs/changes
bash /caminho/do/sdd-new/install.sh --tools claude,codex,gemini

# 2. Propague para as IAs
.sdd/bin/sdd sync --tools claude,codex,gemini

# 3. Confirme que as cópias batem com o original
.sdd/bin/sdd verify       # deve dizer "Tudo fiel à fonte-única"

# 4. Saúde geral
.sdd/bin/sdd doctor
```

> 💡 **No dia a dia**, se você só editou algo em `.sdd/workflow/`, o passo 2 (`sync`)
> já basta. Os passos 3 e 4 são a sua rede de segurança.

---

## 🔧 Cenário 3 — Consertar (a instalação ficou estranha)

Sintomas: um comando `/ideia` sumiu numa IA, ou você editou um adaptador à mão por
engano, ou o `doctor` reclamou de algo.

```bash
# 1. Diagnostique
.sdd/bin/sdd doctor       # mostra o que está faltando
.sdd/bin/sdd verify       # mostra quais cópias divergem do original

# 2. Na maioria dos casos, um sync resolve (realinha as cópias com o original)
.sdd/bin/sdd sync --tools claude,codex,gemini

# 3. Reconfirme
.sdd/bin/sdd verify
.sdd/bin/sdd doctor
```

**Reset total** (só se a instalação corrompeu de vez): apague as pastas geradas e
reinstale. Suas `docs/changes/` (o histórico do seu trabalho) NÃO ficam nessas pastas,
então é seguro:

```bash
rm -rf .claude .codex .gemini .sdd
bash /caminho/do/sdd-new/install.sh --tools claude,codex,gemini
```

---

## 📟 O que cada comando do `sdd` responde

| Comando | Pergunta que ele responde |
| --- | --- |
| `sdd sync` | "Copie meu original para todas as IAs." |
| `sdd verify` | "As cópias ainda batem com o original?" |
| `sdd doctor` | "A instalação está saudável no geral?" |
| `sdd lint` | "Minhas skills estão bem formadas?" |
| `sdd spec-hash <tasks>` | "Tire uma 'foto' do PRD/SPEC para eu detectar mudança depois." |
| `sdd check-drift <tasks>` | "O PRD/SPEC mudou desde que criei as tasks?" |

> **`verify` vs `doctor` — não confunda:**
> - `verify` responde **"as cópias são fiéis ao original?"** (foco nos adaptadores).
> - `doctor` é o **check-up geral** (git, fonte-única, constitution, docs, e chama o verify por baixo).
> A confirmação final de saúde é **`doctor` verde + `verify` fiel**.

---

## ⚠️ Erros comuns (e como evitar)

- **"Editei `.claude/commands/...` e sumiu."** → Você editou uma cópia. Edite em
  `.sdd/workflow/commands/` e rode `sync`. O `verify` avisa quando isso acontece.
- **"Mudei a fonte mas a IA não viu."** → Faltou `sync`. Rode-o.
- **"O `/ideia` não aparece no Codex."** → Dependendo da versão, o Codex lê de
  `~/.codex/prompts/`. Copie uma vez: `cp .codex/prompts/*.md ~/.codex/prompts/`.
- **"`check-drift` deu erro."** → Já não dá mais: se ainda não há tasks, ele só avisa
  e segue.
