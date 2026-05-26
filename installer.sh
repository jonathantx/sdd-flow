#!/usr/bin/env bash
# installer.sh — bootstrap do SDD Workflow (estilo create-vite).
#
# Uso típico (Mac/Linux; Windows via Git Bash ou WSL):
#   curl -fsSL https://install.jonathanteixeira.com.br/install.sh | bash
#   curl -fsSL https://install.jonathanteixeira.com.br/install.sh | bash -s -- --all
#   curl -fsSL https://install.jonathanteixeira.com.br/install.sh | bash -s -- --tools claude,codex --stacks node-typescript
#
# O que faz:
#   1. Baixa/atualiza o kit (repo sdd-flow) em ~/.sdd-flow
#   2. Detecta as stacks do projeto atual e pré-seleciona
#   3. Pergunta interativamente (se houver terminal) o que instalar — ou usa flags
#   4. Roda o install.sh do kit no diretório atual
set -euo pipefail

REPO_URL="${SDD_REPO:-https://github.com/jonathantx/sdd-flow.git}"
KIT_HOME="${SDD_HOME:-$HOME/.sdd-flow}"
PROJECT="$(pwd)"

c0=$'\033[0m'; cb=$'\033[1m'; cg=$'\033[32m'; cy=$'\033[33m'; cc=$'\033[36m'; cd=$'\033[2m'
say()  { printf '%s\n' "$*"; }
ok()   { printf '%s✓%s %s\n' "$cg" "$c0" "$*"; }
note() { printf '%s•%s %s\n' "$cc" "$c0" "$*"; }
die()  { printf '✗ %s\n' "$*" >&2; exit 1; }

# --- flags (modo não-interativo / automação) --------------------------------
ARG_TOOLS=""; ARG_STACKS=""; WANT_FUMADOCS=0; WANT_SCALAR=0; WANT_CI=0; WANT_HOOK=0
FORCE_ALL=0; NONINTERACTIVE=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    sdd-workflow|sdd|workflow) shift ;;     # compat: aceita o nome do pacote e ignora
    --all) FORCE_ALL=1; shift ;;
    --yes|-y) NONINTERACTIVE=1; shift ;;
    --tools) ARG_TOOLS="$2"; shift 2 ;;
    --tools=*) ARG_TOOLS="${1#*=}"; shift ;;
    --stacks) ARG_STACKS="$2"; shift 2 ;;
    --stacks=*) ARG_STACKS="${1#*=}"; shift ;;
    --fumadocs) WANT_FUMADOCS=1; shift ;;
    --scalar) WANT_SCALAR=1; shift ;;
    --ci) WANT_CI=1; shift ;;
    --hook) WANT_HOOK=1; shift ;;
    -h|--help)
      cat <<EOF
SDD Workflow installer

  curl -fsSL https://install.jonathanteixeira.com.br/install.sh | bash
  ... | bash -s -- --all
  ... | bash -s -- --tools claude,codex --stacks node-typescript,svelte --fumadocs --ci

Sem flags e com terminal: faz perguntas interativas (estilo create-vite).
EOF
      exit 0 ;;
    *) die "opção desconhecida: $1" ;;
  esac
done

printf '\n%s┌─────────────────────────────────────┐%s\n' "$cb" "$c0"
printf '%s│   SDD Workflow — instalador          │%s\n' "$cb" "$c0"
printf '%s└─────────────────────────────────────┘%s\n\n' "$cb" "$c0"

command -v git >/dev/null 2>&1 || die "git é necessário. Instale o git e tente de novo."

# --- 1. baixar / atualizar o kit --------------------------------------------
if [[ -d "$KIT_HOME/.git" ]]; then
  note "Atualizando o kit em $KIT_HOME"
  git -C "$KIT_HOME" pull --ff-only --quiet || note "(não consegui atualizar; usando versão local)"
else
  note "Baixando o kit em $KIT_HOME"
  git clone --quiet --depth 1 "$REPO_URL" "$KIT_HOME" || die "falha ao clonar $REPO_URL"
fi
INSTALL="$KIT_HOME/install.sh"
[[ -f "$INSTALL" ]] || die "install.sh não encontrado no kit ($INSTALL)"
chmod +x "$INSTALL" "$KIT_HOME/bin/sdd" 2>/dev/null || true
ok "kit pronto (versão $(cat "$KIT_HOME/VERSION" 2>/dev/null || echo '?'))"

# --- 2. detectar stacks do projeto atual ------------------------------------
DETECT="$KIT_HOME/assets/workflow/skills/analyze-project/scripts/detect-stack.sh"
DETECTED=""
if [[ -x "$DETECT" ]]; then
  # '|| true' em cada elo: quando não há stack, grep -v filtra tudo e retorna 1,
  # o que com 'set -e' mataria o script. Blindamos a pipeline inteira.
  DETECTED="$( { bash "$DETECT" "$PROJECT" 2>/dev/null \
    | sed -n 's/.*skill=\([a-z0-9-]*\).*/\1/p' \
    | grep -v '^none$' \
    | sort -u \
    | paste -sd, - ; } || true )"
fi
[[ -n "$DETECTED" ]] && note "Stacks detectadas no projeto: $cb$DETECTED$c0"

# --- helpers de prompt (leem do terminal real via /dev/tty) -----------------
# Abre o terminal real uma única vez no fd 3. Num pipe (curl | bash) o stdin é o
# próprio script, então perguntamos pelo /dev/tty. Se não der (CI/sem terminal),
# TTY_OK fica 0 e caímos no modo não-interativo.
TTY_OK=0
if [[ "${SDD_NONINTERACTIVE:-0}" != "1" && -z "${CI:-}" && $NONINTERACTIVE -eq 0 ]]; then
  if { exec 3</dev/tty; } 2>/dev/null; then TTY_OK=1; fi
fi

# Prompts por NÚMERO (à prova de erro de digitação) — sem subshell.
# ask_choice: menu de múltipla escolha. Resultado (csv de valores) em REPLY_VAL.
#   $1 = título   $2 = linha de ajuda   $3 = csv de pré-selecionados (defaults)
#   $4.. = itens no formato "valor:rótulo"
ask_choice() {
  local title="$1" help="$2" preset="$3"; shift 3
  local items=("$@") i val label
  printf '\n%s? %s%s%s\n' "$cy" "$cb" "$title" "$c0" >/dev/tty
  [[ -n "$help" ]] && printf '   %s%s%s\n' "$cd" "$help" "$c0" >/dev/tty
  for i in "${!items[@]}"; do
    val="${items[$i]%%:*}"; label="${items[$i]#*:}"
    local mark=' '; [[ ",$preset," == *",$val,"* ]] && mark='x'
    printf '   %s[%s]%s %s) %s\n' "$cg" "$mark" "$c0" "$((i+1))" "$label" >/dev/tty
  done
  printf '   %s→ números separados por espaço (ex: 1 3) · Enter aceita o padrão:%s ' "$cd" "$c0" >/dev/tty
  local ans=""; IFS= read -r ans <&3 || ans=""
  if [[ -z "$ans" ]]; then REPLY_VAL="$preset"; return 0; fi
  # converter números escolhidos em csv de valores
  local out="" n
  for n in $ans; do
    if [[ "$n" =~ ^[0-9]+$ ]] && (( n>=1 && n<=${#items[@]} )); then
      val="${items[$((n-1))]%%:*}"; out="${out:+$out,}$val"
    fi
  done
  REPLY_VAL="$out"   # vazio = nenhum (ex.: 0 ou inválido → instala sem aquilo)
}
ask_yn() { # $1 pergunta  $2 ajuda  $3 default(Y/N) → 0 se sim
  local q="$1" help="$2" def="${3:-N}" ans=""
  printf '\n%s? %s%s%s' "$cy" "$cb" "$q" "$c0" >/dev/tty
  [[ "$def" == "Y" ]] && printf ' [Y/n] ' >/dev/tty || printf ' [y/N] ' >/dev/tty
  printf '\n   %s%s%s\n   → ' "$cd" "$help" "$c0" >/dev/tty
  IFS= read -r ans <&3 || ans=""
  ans="${ans:-$def}"
  [[ "$ans" =~ ^[YySs] ]]
}

# --- 3. decidir opções: flags > --all > interativo > default ----------------
if [[ $FORCE_ALL -eq 1 ]]; then
  TOOLS="${ARG_TOOLS:-claude,codex,gemini}"; STACKS="$ARG_STACKS"
  WANT_FUMADOCS=1; WANT_SCALAR=1; WANT_CI=1; WANT_HOOK=1
elif [[ -n "$ARG_TOOLS$ARG_STACKS" || $NONINTERACTIVE -eq 1 ]]; then
  TOOLS="${ARG_TOOLS:-claude}"; STACKS="$ARG_STACKS"
elif [[ $TTY_OK -eq 1 ]]; then
  say "Vamos personalizar a instalação. Escolha pelos números (Enter = padrão)."

  ask_choice 'Ferramentas de IA' \
    'Onde os comandos /ideia, /spec etc. vão funcionar. Pode marcar mais de uma.' \
    'claude' \
    'claude:Claude Code' 'codex:Codex CLI' 'gemini:Gemini CLI'
  TOOLS="${REPLY_VAL:-claude}"

  ask_choice 'Stacks do projeto' \
    "Bases de conhecimento que evitam alucinação. Detectadas: ${DETECTED:-nenhuma} (já pré-marcadas)." \
    "${DETECTED:-}" \
    'node-typescript:Node.js + TypeScript (backend)' \
    'php-laravel:PHP + Laravel (backend)' \
    'react:React (frontend)' \
    'svelte:Svelte / SvelteKit (frontend)'
  STACKS="$REPLY_VAL"

  ask_yn 'Instalar Fumadocs?' 'Site de documentação navegável (roda via Docker, porta 8801).' 'N' && WANT_FUMADOCS=1 || true
  ask_yn 'Instalar Scalar?' 'Visualizador de API a partir de OpenAPI (porta 8802). Só útil se você tem API REST.' 'N' && WANT_SCALAR=1 || true
  ask_yn 'Instalar gate de CI?' 'GitHub Action que valida o workflow em cada Pull Request.' 'N' && WANT_CI=1 || true
  ask_yn 'Instalar git hook?' 'Checagem automática antes de cada commit (avisa problemas cedo).' 'N' && WANT_HOOK=1 || true
else
  # pipe sem terminal e sem flags → instalação mínima sensata
  TOOLS="claude"; STACKS="$DETECTED"
  note "Sem terminal interativo: instalando o básico (--tools claude). Use flags para mais."
fi

# --- 4. montar e rodar o install do kit -------------------------------------
ARGS=(--tools "$TOOLS")
[[ -n "$STACKS" ]] && ARGS+=(--stacks "$STACKS")
[[ $WANT_FUMADOCS -eq 1 ]] && ARGS+=(--fumadocs)
[[ $WANT_SCALAR -eq 1 ]] && ARGS+=(--scalar)
[[ $WANT_CI -eq 1 ]] && ARGS+=(--ci)
[[ $WANT_HOOK -eq 1 ]] && ARGS+=(--hook)

printf '\n%sInstalando com:%s tools=%s stacks=%s%s%s%s%s\n\n' "$cb" "$c0" \
  "$TOOLS" "${STACKS:-(nenhuma)}" \
  "$([[ $WANT_FUMADOCS -eq 1 ]] && echo ' +fumadocs')" \
  "$([[ $WANT_SCALAR -eq 1 ]] && echo ' +scalar')" \
  "$([[ $WANT_CI -eq 1 ]] && echo ' +ci')" \
  "$([[ $WANT_HOOK -eq 1 ]] && echo ' +hook')"

( cd "$PROJECT" && bash "$INSTALL" "${ARGS[@]}" )

printf '\n%s✓ Pronto!%s No seu agente de IA, rode %s/analyze%s para detectar a stack e começar.\n' "$cg" "$c0" "$cb" "$c0"
