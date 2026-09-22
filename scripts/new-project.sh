#!/usr/bin/env bash
# Cria um projeto Spec Kit novo já em pt-BR: roda `specify init` e aplica a tradução.
# Versão bash do new-project.ps1, para Linux e macOS.
#
# Uso:
#   scripts/new-project.sh <nome-ou-caminho> [--script sh|ps] [--extension NOME ...]
#   scripts/new-project.sh --here        [--script sh|ps] [--extension NOME ...]
#
# Padrão: --script sh (scripts bash no projeto gerado).
set -euo pipefail

PACK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NAME=""; HERE=0; SCRIPT="sh"; EXTENSIONS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --here) HERE=1 ;;
    --script) SCRIPT="$2"; shift ;;
    --extension) EXTENSIONS+=("$2"); shift ;;
    -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
    *) NAME="$1" ;;
  esac
  shift
done

fail() { printf '\033[31m    ERRO  %s\033[0m\n' "$*"; }
warn() { printf '\033[33m    AVISO  %s\033[0m\n' "$*"; }
step() { printf '\033[36m==> %s\033[0m\n' "$*"; }

if [ "$HERE" -eq 0 ] && [ -z "$NAME" ]; then fail "Informe <nome> ou --here."; exit 1; fi
case "$SCRIPT" in ps|sh) ;; *) fail "--script deve ser sh ou ps"; exit 1 ;; esac

version_field() { sed -n "s/^$1=//p" "$PACK_ROOT/VERSION" | head -1; }
PACK_VERSION="$(version_field upstream_version)"
PACK_COMMIT="$(version_field upstream_commit)"

if ! command -v specify > /dev/null 2>&1; then
  fail 'CLI `specify` não encontrada. Instale com:'
  echo "  uv tool install specify-cli --from git+https://github.com/github/spec-kit.git@$PACK_COMMIT"
  exit 1
fi
INSTALLED="$(specify version 2>/dev/null | sed -n 's/.*CLI Version *\([^ │]*\).*/\1/p' | head -1)"
if [ -n "$INSTALLED" ] && [ "$INSTALLED" != "$PACK_VERSION" ]; then
  warn "specify instalada: $INSTALLED | pacote acompanha: $PACK_VERSION"
  warn "Para alinhar: uv tool install specify-cli --force --from git+https://github.com/github/spec-kit.git@$PACK_COMMIT"
fi

args=(init)
if [ "$HERE" -eq 1 ]; then args+=(--here --force); else args+=("$NAME"); fi
args+=(--integration claude --script "$SCRIPT" --non-interactive)
for e in "${EXTENSIONS[@]:-}"; do [ -n "$e" ] && args+=(--extension "$e"); done

step "specify ${args[*]}"
specify "${args[@]}"

target="."
[ "$HERE" -eq 0 ] && target="$NAME"
exec "$PACK_ROOT/scripts/apply.sh" "$target" --force
