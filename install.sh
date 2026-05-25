#!/usr/bin/env bash
# SDD Workflow Kit installer (v2 — single-source + stacks + multi-LLM)
#
# Instala a fonte-única (.sdd/) no projeto alvo, gera os adaptadores das
# ferramentas de IA escolhidas, ativa as skills de stack e prepara docs.
set -euo pipefail

ROOT_DIR="$(pwd)"
KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS="$KIT_DIR/assets"

TOOLS="claude"           # ferramentas de IA: claude,codex,gemini
STACKS=""                # node-typescript,php-laravel,react,svelte (vazio = todas)
INSTALL_FUMADOCS=0
INSTALL_SCALAR=0
FORCE=0

usage() {
  cat <<'EOF'
SDD Workflow Kit installer (v2)

Uso:
  install.sh [opções]

Opções:
  --tools <lista>     Ferramentas de IA (vírgula): claude,codex,gemini   (default: claude)
  --stacks <lista>    Skills de stack a instalar (vírgula): node-typescript,php-laravel,react,svelte
                      (default: todas as disponíveis)
  --fumadocs          Instala o site de documentação Fumadocs + serviço docker
  --scalar            Instala a referência de API Scalar + serviço docker
  --all               Instala tudo: todas as ferramentas, todas as stacks, fumadocs e scalar
  --force             Sobrescreve arquivos já gerenciados por este kit
  -h, --help          Mostra esta ajuda

Sempre instalado (base):
  .sdd/workflow   (fonte-única: comandos + skills)
  .sdd/bin/sdd    (CLI do workflow)
  docs/           (esqueleto: constitution, changelog, adr, changes)

Depois de instalar, rode dentro do agente de IA:  /analyze   (detecta stacks)
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tools) TOOLS="$2"; shift 2 ;;
    --tools=*) TOOLS="${1#*=}"; shift ;;
    --stacks) STACKS="$2"; shift 2 ;;
    --stacks=*) STACKS="${1#*=}"; shift ;;
    --fumadocs) INSTALL_FUMADOCS=1; shift ;;
    --scalar) INSTALL_SCALAR=1; shift ;;
    --all) TOOLS="claude,codex,gemini"; STACKS=""; INSTALL_FUMADOCS=1; INSTALL_SCALAR=1; shift ;;
    --force) FORCE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Opção desconhecida: $1" >&2; usage; exit 1 ;;
  esac
done

say() { printf '• %s\n' "$*"; }
ok()  { printf '✓ %s\n' "$*"; }

# --- Base: fonte-única (.sdd) ------------------------------------------------
say "Instalando fonte-única em .sdd/"
mkdir -p "$ROOT_DIR/.sdd"
# Workflow (comandos + skills). Filtra stacks se --stacks foi passado.
mkdir -p "$ROOT_DIR/.sdd/workflow/commands" "$ROOT_DIR/.sdd/workflow/skills/stacks"
cp "$ASSETS"/workflow/commands/*.md "$ROOT_DIR/.sdd/workflow/commands/" 2>/dev/null || true
# Skills não-stack (analyze-project etc.)
for d in "$ASSETS"/workflow/skills/*/; do
  base="$(basename "$d")"
  [[ "$base" == "stacks" ]] && continue
  cp -R "$d" "$ROOT_DIR/.sdd/workflow/skills/$base"
done
cp "$ASSETS"/workflow/skills/stacks/README.md "$ROOT_DIR/.sdd/workflow/skills/stacks/" 2>/dev/null || true
# Stacks selecionadas (ou todas)
if [[ -z "$STACKS" ]]; then
  for d in "$ASSETS"/workflow/skills/stacks/*/; do
    [[ -d "$d" ]] && cp -R "$d" "$ROOT_DIR/.sdd/workflow/skills/stacks/$(basename "$d")"
  done
else
  IFS=',' read -ra SLIST <<< "$STACKS"
  for s in "${SLIST[@]}"; do
    if [[ -d "$ASSETS/workflow/skills/stacks/$s" ]]; then
      cp -R "$ASSETS/workflow/skills/stacks/$s" "$ROOT_DIR/.sdd/workflow/skills/stacks/$s"
    else
      echo "  (aviso) stack desconhecida ignorada: $s" >&2
    fi
  done
fi
ok "fonte-única instalada"

# --- CLI sdd + VERSION ------------------------------------------------------
mkdir -p "$ROOT_DIR/.sdd/bin"
cp "$KIT_DIR/bin/sdd" "$ROOT_DIR/.sdd/bin/sdd"
chmod +x "$ROOT_DIR/.sdd/bin/sdd"
[[ -r "$KIT_DIR/VERSION" ]] && cp "$KIT_DIR/VERSION" "$ROOT_DIR/.sdd/VERSION"
find "$ROOT_DIR/.sdd/workflow/skills" -name '*.sh' -exec chmod +x {} \; 2>/dev/null || true
ok "CLI em .sdd/bin/sdd (versão $(cat "$KIT_DIR/VERSION" 2>/dev/null || echo '?'))"

# --- Docs skeleton (NÃO-destrutivo) -----------------------------------------
# Copia só o que ainda não existe: preserva docs e correções (ex.: titles) que o
# usuário já tenha. Sem isso, reinstalar sobrescreveria docs/patterns/README.md e
# reintroduziria o erro de frontmatter sem title no Fumadocs.
say "Instalando esqueleto de docs/ (sem sobrescrever existentes)"
mkdir -p "$ROOT_DIR/docs"
( cd "$ASSETS/templates/docs" && find . -type d -exec mkdir -p "$ROOT_DIR/docs/{}" \; )
( cd "$ASSETS/templates/docs" && find . -type f -exec cp -n {} "$ROOT_DIR/docs/{}" \; ) 2>/dev/null || true
ok "docs/ (constitution, changelog, adr/, changes/, patterns/)"

# --- Adaptadores das ferramentas (via CLI sdd sync) -------------------------
say "Gerando adaptadores para: $TOOLS"
( cd "$ROOT_DIR" && "$ROOT_DIR/.sdd/bin/sdd" sync --tools "$TOOLS" )

# --- Fumadocs / Scalar ------------------------------------------------------
if [[ $INSTALL_FUMADOCS -eq 1 ]]; then
  say "Instalando Fumadocs"
  mkdir -p "$ROOT_DIR/docs-fumadocs"
  cp -R "$ASSETS"/templates/fumadocs/. "$ROOT_DIR/docs-fumadocs/"
  ok "docs-fumadocs/ (porta 8801 via docker)"
fi
if [[ $INSTALL_SCALAR -eq 1 ]]; then
  say "Instalando Scalar"
  mkdir -p "$ROOT_DIR/scalar"
  cp -R "$ASSETS"/templates/scalar/. "$ROOT_DIR/scalar/"
  ok "scalar/ (porta 8802 via docker)"
fi

# --- docker-compose.sdd.yml (gerado conforme as flags de docs) --------------
# Arquivo SEPARADO do docker-compose.yml do projeto, para nunca conflitar.
# Use:  docker compose -f docker-compose.sdd.yml up
if [[ $INSTALL_FUMADOCS -eq 1 || $INSTALL_SCALAR -eq 1 ]]; then
  say "Gerando docker-compose.sdd.yml"
  {
    echo "# Serviços de documentação do SDD Workflow (separado do seu docker-compose.yml)."
    echo "# Subir:  docker compose -f docker-compose.sdd.yml up --build"
    echo "services:"
    if [[ $INSTALL_FUMADOCS -eq 1 ]]; then
      cat <<'YML'
  docs-fumadocs:
    build: ./docs-fumadocs
    ports:
      - "8801:3000"
    volumes:
      - ./docs:/app/content/docs:ro      # sua documentação, montada (sem rebuild ao editar)
    restart: unless-stopped
YML
    fi
    if [[ $INSTALL_SCALAR -eq 1 ]]; then
      cat <<'YML'
  scalar:
    build: ./scalar
    ports:
      - "8802:80"
    volumes:
      - ./scalar/openapi.yaml:/usr/share/nginx/html/openapi.yaml:ro
    restart: unless-stopped
YML
    fi
  } > "$ROOT_DIR/docker-compose.sdd.yml"
  ok "docker-compose.sdd.yml gerado (fumadocs:8801, scalar:8802 conforme escolhido)"
fi

cat <<EOF

✓ Instalação concluída.

Próximos passos:
  1. No seu agente de IA, rode:  /analyze     (detecta as stacks e ativa as skills)
  2. Comece uma mudança:         /ideia "o que você quer fazer"
  3. Valide a instalação:        .sdd/bin/sdd doctor

Edite o workflow SOMENTE em .sdd/workflow/ e rode  .sdd/bin/sdd sync  para propagar.
EOF

if [[ $INSTALL_FUMADOCS -eq 1 || $INSTALL_SCALAR -eq 1 ]]; then
  cat <<EOF

📚 Documentação via Docker:
  docker compose -f docker-compose.sdd.yml up --build
EOF
  [[ $INSTALL_FUMADOCS -eq 1 ]] && echo "  → Fumadocs:  http://localhost:8801"
  [[ $INSTALL_SCALAR   -eq 1 ]] && echo "  → Scalar:    http://localhost:8802"
fi
