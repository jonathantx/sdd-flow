#!/usr/bin/env bash
# detect-stack.sh — detecção agnóstica de stacks por arquivos-âncora.
# Uso: detect-stack.sh [project-root]
# Saída: linhas "stack=<nome> skill=<skill> evidence=<arquivo>"
set -euo pipefail

ROOT="${1:-$(pwd)}"
cd "$ROOT"

PRUNE=( -name node_modules -o -name vendor -o -name .git -o -name dist -o -name build )
findcode() { find . \( "${PRUNE[@]}" \) -prune -o -type f -name "$1" -print 2>/dev/null; }
has() { grep -qiE "$2" "$1" 2>/dev/null; }

report() { printf 'stack=%s skill=%s evidence=%s\n' "$1" "$2" "$3"; }

found_any=0

# Node / TypeScript backend
while IFS= read -r pkg; do
  [[ -z "$pkg" ]] && continue
  if has "$pkg" '"(express|fastify|@nestjs/core|koa|hapi)"'; then
    report "node-backend" "node-typescript" "$pkg"; found_any=1
  fi
  if has "$pkg" '"(react|next)"'; then
    report "react" "react" "$pkg"; found_any=1
  fi
  if has "$pkg" '"(svelte|@sveltejs/kit)"'; then
    report "svelte" "svelte" "$pkg"; found_any=1
  fi
done < <(findcode "package.json")

# Svelte config (mesmo sem dependência declarada óbvia)
if [[ -n "$(findcode 'svelte.config.js')$(findcode '*.svelte')" ]]; then
  report "svelte" "svelte" "svelte.config.js/*.svelte"; found_any=1
fi

# PHP / Laravel
while IFS= read -r comp; do
  [[ -z "$comp" ]] && continue
  if has "$comp" '"laravel/framework"'; then
    report "php-laravel" "php-laravel" "$comp"; found_any=1
  fi
done < <(findcode "composer.json")

# TypeScript genérico (fallback se nada acima casou em backend)
if [[ $found_any -eq 0 ]] && [[ -n "$(findcode 'tsconfig.json')" ]]; then
  report "typescript" "node-typescript" "tsconfig.json"; found_any=1
fi

if [[ $found_any -eq 0 ]]; then
  echo "stack=none skill=none evidence=(no application code detected — bootstrap mode)"
fi
