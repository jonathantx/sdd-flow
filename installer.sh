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
  DETECTED="$(bash "$DETECT" "$PROJECT" 2>/dev/null | sed -n 's/.*skill=\([a-z0-9-]*\).*/\1/p' | grep -v '^none$' | sort -u | paste -sd, -)"
fi
[[ -n "$DETECTED" ]] && note "Stacks detectadas no projeto: $cb$DETECTED$c0"

# --- helpers de prompt (leem do terminal real via /dev/tty) -----------------
# Interativo só quando dá para ABRIR /dev/tty para leitura. Num pipe puro de CI
# (sem terminal) isso falha e caímos no modo não-interativo. O 'exec' abre o fd 3
# ligado ao terminal real; se falhar, has_tty retorna falso sem abortar (set -e
# é neutralizado pelo '|| return 1').
has_tty() {
  # Força não-interativo em CI ou quando SDD_NONINTERACTIVE=1.
  [[ "${SDD_NONINTERACTIVE:-0}" == "1" || -n "${CI:-}" ]] && return 1
  [[ $NONINTERACTIVE -eq 1 ]] && return 1
  { exec 3</dev/tty; } 2>/dev/null || return 1
  return 0
}
ask_yn() { # $1 pergunta  $2 default(Y/N)
  local q="$1" def="${2:-N}" ans
  if [[ "$def" == "Y" ]]; then q="$q [Y/n] "; else q="$q [y/N] "; fi
  printf '%s? %s%s' "$cy" "$c0" "$q" > /dev/tty
  IFS= read -r ans <&3 || ans=""
  ans="${ans:-$def}"
  [[ "$ans" =~ ^[YySs] ]]
}
ask_csv() { # $1 pergunta  $2 default-csv  → ecoa resposta
  local q="$1" def="$2" ans
  printf '%s? %s%s%s[%s]%s: ' "$cy" "$c0" "$q " "$cd" "$def" "$c0" > /dev/tty
  IFS= read -r ans <&3 || ans=""
  echo "${ans:-$def}"
}

# --- 3. decidir opções: flags > --all > interativo > default ----------------
if [[ $FORCE_ALL -eq 1 ]]; then
  TOOLS="${ARG_TOOLS:-claude,codex,gemini}"; STACKS="$ARG_STACKS"
  WANT_FUMADOCS=1; WANT_SCALAR=1; WANT_CI=1; WANT_HOOK=1
elif [[ -n "$ARG_TOOLS$ARG_STACKS" || $NONINTERACTIVE -eq 1 ]]; then
  TOOLS="${ARG_TOOLS:-claude}"; STACKS="$ARG_STACKS"
elif has_tty; then
  say "Responda para personalizar (Enter aceita o padrão):"
  TOOLS="$(ask_csv 'Ferramentas de IA (claude,codex,gemini)' 'claude')"
  STACKS="$(ask_csv 'Stacks (node-typescript,php-laravel,react,svelte)' "${DETECTED:-}")"
  ask_yn 'Instalar documentação Fumadocs?' 'N' && WANT_FUMADOCS=1 || true
  ask_yn 'Instalar referência de API Scalar?' 'N' && WANT_SCALAR=1 || true
  ask_yn 'Instalar gate de CI (GitHub Action)?' 'N' && WANT_CI=1 || true
  ask_yn 'Instalar git hook de pre-commit?' 'N' && WANT_HOOK=1 || true
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
