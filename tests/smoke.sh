#!/usr/bin/env bash
# smoke.sh — teste de fumaça do kit SDD Workflow.
# Cria um projeto-sandbox temporário, roda o ciclo completo de governança
# (install → sync → verify → doctor → spec-hash → check-drift) e valida as
# saídas. Falha (exit 1) se qualquer etapa não se comportar como esperado.
#
# Uso:  bash tests/smoke.sh
# CI:   exit code 0 = tudo ok; 1 = alguma regressão.
set -uo pipefail

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/sdd-smoke.XXXXXX")"
PASS=0; FAIL=0

c_g=$'\033[32m'; c_r=$'\033[31m'; c_b=$'\033[34m'; c_0=$'\033[0m'
pass() { printf "%s✓%s %s\n" "$c_g" "$c_0" "$*"; PASS=$((PASS+1)); }
fail() { printf "%s✗%s %s\n" "$c_r" "$c_0" "$*"; FAIL=$((FAIL+1)); }
step() { printf "\n%s▶ %s%s\n" "$c_b" "$*" "$c_0"; }

cleanup() { rm -rf "$SANDBOX"; }
trap cleanup EXIT

# assert_contains <descrição> <texto> <agulha>
assert_contains() {
  if grep -qF "$3" <<< "$2"; then pass "$1"; else fail "$1 (esperava conter: '$3')"; fi
}
# assert_exit <descrição> <código-esperado> <código-real>
assert_exit() {
  if [[ "$2" == "$3" ]]; then pass "$1"; else fail "$1 (exit esperado=$2, real=$3)"; fi
}
# assert_file <descrição> <caminho>
assert_file() {
  if [[ -e "$2" ]]; then pass "$1"; else fail "$1 (arquivo ausente: $2)"; fi
}

printf "%s\n" "SDD Workflow — smoke test"
printf "Kit:     %s\n" "$KIT_DIR"
printf "Sandbox: %s\n" "$SANDBOX"

# --- Preparar um repo-alvo fingindo ser Node + React ------------------------
cd "$SANDBOX"
git init -q
echo '{"dependencies":{"express":"^4","react":"^18","typescript":"^5"}}' > package.json

# --- 1. INSTALL -------------------------------------------------------------
step "install.sh --tools claude,codex,gemini"
out="$(bash "$KIT_DIR/install.sh" --tools claude,codex,gemini 2>&1)"; rc=$?
assert_exit "install retorna 0" 0 "$rc"
assert_file "fonte-única criada"     ".sdd/workflow/commands/ideia.md"
assert_file "CLI instalada"          ".sdd/bin/sdd"
assert_file "VERSION instalada"      ".sdd/VERSION"
assert_file "adaptador claude"       ".claude/commands/ideia.md"
assert_file "adaptador codex"        ".codex/prompts/ideia.md"
assert_file "adaptador gemini"       ".gemini/commands/ideia.toml"
assert_file "skill de stack react"   ".sdd/workflow/skills/stacks/react/SKILL.md"

SDD=".sdd/bin/sdd"

# --- 2. VERSION -------------------------------------------------------------
step "sdd version"
out="$("$SDD" version 2>&1)"; rc=$?
assert_exit "version retorna 0" 0 "$rc"
assert_contains "version lê do arquivo VERSION" "$out" "$(cat "$KIT_DIR/VERSION")"

# --- 3. LINT ----------------------------------------------------------------
step "sdd lint"
out="$("$SDD" lint 2>&1)"; rc=$?
assert_exit "lint retorna 0" 0 "$rc"
assert_contains "lint aprova" "$out" "Lint OK"

# --- 4. VERIFY (logo após install: tudo fiel) -------------------------------
step "sdd verify (limpo)"
out="$("$SDD" verify 2>&1)"; rc=$?
assert_exit "verify retorna 0" 0 "$rc"
assert_contains "verify diz fiel" "$out" "fiel à fonte-única"

# --- 5. VERIFY detecta edição à mão -----------------------------------------
step "sdd verify (adaptador editado à mão)"
echo "# rabisco" >> .claude/commands/ideia.md
out="$("$SDD" verify 2>&1)"; rc=$?
assert_contains "verify acusa divergência" "$out" "divergente"
assert_exit "verify só avisa (exit 0 por padrão)" 0 "$rc"

# --- 6. VERIFY --strict falha em divergência --------------------------------
step "sdd verify --strict"
out="$("$SDD" verify --strict 2>&1)"; rc=$?
assert_exit "verify --strict retorna 1 com divergência" 1 "$rc"

# --- 7. SYNC realinha -------------------------------------------------------
step "sdd sync (realinha)"
"$SDD" sync --tools claude,codex,gemini >/dev/null 2>&1
out="$("$SDD" verify 2>&1)"
assert_contains "verify volta a fiel após sync" "$out" "fiel à fonte-única"

# --- 8. CHECK-DRIFT no-op (sem tasks) ---------------------------------------
step "sdd check-drift (arquivo inexistente)"
out="$("$SDD" check-drift docs/changes/nao-existe/03-PLAN-EXEC.md 2>&1)"; rc=$?
assert_exit "check-drift no-op retorna 0" 0 "$rc"
assert_contains "check-drift avisa graciosamente" "$out" "Nada a verificar"

# --- 9. SPEC-HASH + CHECK-DRIFT (ciclo real) --------------------------------
step "spec-hash + check-drift (change simulada)"
mkdir -p docs/changes/feat-demo
echo "# PRD" > docs/changes/feat-demo/01-PRD.md
echo "# SPEC" > docs/changes/feat-demo/02-SPEC.md
echo "# Plano" > docs/changes/feat-demo/03-PLAN-EXEC.md
"$SDD" spec-hash docs/changes/feat-demo/03-PLAN-EXEC.md >/dev/null 2>&1
out="$("$SDD" check-drift docs/changes/feat-demo/03-PLAN-EXEC.md 2>&1)"; rc=$?
assert_exit "check-drift sem drift retorna 0" 0 "$rc"
assert_contains "check-drift diz sem drift" "$out" "Sem drift"
# muda a SPEC → deve detectar drift
echo "# SPEC MUDADO" > docs/changes/feat-demo/02-SPEC.md
out="$("$SDD" check-drift docs/changes/feat-demo/03-PLAN-EXEC.md 2>&1)"; rc=$?
assert_exit "check-drift com drift retorna 1" 1 "$rc"
assert_contains "check-drift acusa drift" "$out" "drift"

# --- 10. DETECT-STACK -------------------------------------------------------
step "detect-stack.sh"
out="$(bash .sdd/workflow/skills/analyze-project/scripts/detect-stack.sh "$SANDBOX" 2>&1)"
assert_contains "detecta node backend" "$out" "skill=node-typescript"
assert_contains "detecta react" "$out" "skill=react"

# --- 11. DOCTOR -------------------------------------------------------------
step "sdd doctor"
out="$("$SDD" doctor 2>&1)"; rc=$?
assert_exit "doctor retorna 0" 0 "$rc"
assert_contains "doctor conclui" "$out" "Doctor concluído"

# --- 12. ONDA 2: titles --check ---------------------------------------------
step "sdd titles --check"
mkdir -p docs/zz && printf '# Doc sem frontmatter\ntexto\n' > docs/zz/bad.md
out="$("$SDD" titles --check docs 2>&1)"; rc=$?
assert_exit "titles --check falha com doc sem title" 1 "$rc"
"$SDD" titles docs >/dev/null 2>&1   # corrige
out="$("$SDD" titles --check docs 2>&1)"; rc=$?
assert_exit "titles --check passa após corrigir" 0 "$rc"

# --- 13. ONDA 2: lint de artefatos ------------------------------------------
step "sdd lint (artefato com status inválido)"
mkdir -p docs/changes/feat-lint && printf -- '---\ntitle: "X"\nstatus: invalido\n---\n# X\n' > docs/changes/feat-lint/01-PRD.md
out="$("$SDD" lint 2>&1)"; rc=$?
assert_exit "lint falha com status inválido" 1 "$rc"
rm -rf docs/changes/feat-lint

# --- 14. ONDA 2: hooks install ----------------------------------------------
step "sdd hooks install"
out="$("$SDD" hooks install 2>&1)"; rc=$?
assert_exit "hooks install retorna 0" 0 "$rc"
assert_file "pre-commit instalado" ".git/hooks/pre-commit"

# --- 15. ONDA 2: CI template via install --ci -------------------------------
step "install --ci"
bash "$KIT_DIR/install.sh" --tools claude --ci >/dev/null 2>&1
assert_file "GitHub Action instalado" ".github/workflows/sdd.yml"

# --- Resumo -----------------------------------------------------------------
printf "\n──────────────────────────────\n"
printf "%sPASS: %d%s   %sFAIL: %d%s\n" "$c_g" "$PASS" "$c_0" "$c_r" "$FAIL" "$c_0"
[[ $FAIL -eq 0 ]] && { printf "%s✓ smoke test verde%s\n" "$c_g" "$c_0"; exit 0; }
printf "%s✗ smoke test vermelho%s\n" "$c_r" "$c_0"; exit 1
