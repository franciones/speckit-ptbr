#!/usr/bin/env bash
# Aplica a tradução pt-BR do Spec Kit sobre um projeto já inicializado com `specify init`.
# Versão bash do apply.ps1, para Linux e macOS. Não precisa de PowerShell.
#
# Uso:
#   scripts/apply.sh [caminho-do-projeto] [--force]
#
# Detecta a variante de scripts do projeto (ps ou sh) em .specify/integration.json.
# Na variante sh, os skills são convertidos na hora: a linha de invocação
# `.specify/scripts/powershell/x.ps1 -Json` vira `.specify/scripts/bash/x.sh --json`.
set -euo pipefail

PACK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OVERLAY="$PACK_ROOT/ptbr"
PROJECT="."
FORCE=0
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    *) PROJECT="$arg" ;;
  esac
done
PROJECT="$(cd "$PROJECT" && pwd)"

UPSTREAM_FILES=(
  .specify/templates/spec-template.md
  .specify/templates/plan-template.md
  .specify/templates/tasks-template.md
  .specify/templates/checklist-template.md
  .specify/templates/constitution-template.md
  .specify/memory/constitution.md
  .claude/skills/speckit-analyze/SKILL.md
  .claude/skills/speckit-checklist/SKILL.md
  .claude/skills/speckit-clarify/SKILL.md
  .claude/skills/speckit-constitution/SKILL.md
  .claude/skills/speckit-converge/SKILL.md
  .claude/skills/speckit-implement/SKILL.md
  .claude/skills/speckit-plan/SKILL.md
  .claude/skills/speckit-specify/SKILL.md
  .claude/skills/speckit-tasks/SKILL.md
  .claude/skills/speckit-taskstoissues/SKILL.md
)

step() { printf '\033[36m==> %s\033[0m\n' "$*"; }
ok()   { printf '\033[32m    OK  %s\033[0m\n' "$*"; }
warn() { printf '\033[33m    AVISO  %s\033[0m\n' "$*"; }
fail() { printf '\033[31m    ERRO  %s\033[0m\n' "$*"; }

version_field() { sed -n "s/^$1=//p" "$PACK_ROOT/VERSION" | head -1; }
PACK_VERSION="$(version_field upstream_version)"
PACK_COMMIT="$(version_field upstream_commit)"

step "Aplicando speckit-ptbr (upstream $PACK_VERSION) em $PROJECT"

# 1. Pré-condições
if [ ! -d "$PROJECT/.specify" ]; then
  fail "Pasta .specify não encontrada. Rode antes: specify init . --integration claude --script sh"
  exit 1
fi
if [ ! -f "$PROJECT/.claude/skills/speckit-specify/SKILL.md" ]; then
  fail "Skills do Claude Code não encontrados em .claude/skills. Este pacote suporta apenas --integration claude."
  exit 1
fi

VARIANT="$(version_field script)"
PROJECT_VERSION=""
if [ -f "$PROJECT/.specify/integration.json" ]; then
  v="$(grep -o '"script": *"[a-z]*"' "$PROJECT/.specify/integration.json" | head -1 | sed 's/.*"\([a-z]*\)"$/\1/')"
  [ -n "$v" ] && VARIANT="$v"
  PROJECT_VERSION="$(grep -o '"version": *"[^"]*"' "$PROJECT/.specify/integration.json" | head -1 | sed 's/.*"\([^"]*\)"$/\1/')"
fi
case "$VARIANT" in
  ps|sh) ;;
  *) fail "Variante de script '$VARIANT' não suportada. Use --script ps ou --script sh no specify init."; exit 1 ;;
esac
ok "Variante de scripts do projeto: $VARIANT"

if [ -n "$PROJECT_VERSION" ] && [ "$PROJECT_VERSION" != "$PACK_VERSION" ]; then
  warn "Projeto foi gerado pela specify $PROJECT_VERSION; o pacote acompanha a $PACK_VERSION."
  if [ "$FORCE" -ne 1 ]; then
    warn "Use --force para aplicar mesmo assim, ou atualize o pacote."
    exit 1
  fi
fi

# 2. Copia os arquivos traduzidos (skills convertidos se a variante for sh)
to_sh_variant() {
  perl -pe 's{`\.specify/scripts/powershell/([a-z-]+)\.ps1([^`]*)`}{ my ($n,$f)=($1,$2); $f =~ s/(?<=\s)-([A-Z][A-Za-z0-9]*)/"--".join("-", map { lc } ($1 =~ m{[A-Z][a-z0-9]*}g))/ge; "`.specify/scripts/bash/$n.sh$f`" }ge'
}
applied=0
for rel in "${UPSTREAM_FILES[@]}"; do
  src="$OVERLAY/$rel"; dst="$PROJECT/$rel"
  if [ ! -f "$src" ]; then warn "Arquivo ausente no pacote, pulando: $rel"; continue; fi
  mkdir -p "$(dirname "$dst")"
  case "$rel" in
    .claude/skills/*)
      if [ "$VARIANT" = "sh" ]; then to_sh_variant < "$src" > "$dst"; else cp "$src" "$dst"; fi ;;
    *) cp "$src" "$dst" ;;
  esac
  applied=$((applied + 1))
done
ok "$applied arquivos traduzidos aplicados"

# 3. CLAUDE.md: cria ou complementa
if [ -f "$PROJECT/CLAUDE.md" ]; then
  if grep -q '## Idioma de saída' "$PROJECT/CLAUDE.md"; then
    ok "CLAUDE.md já contém a seção de idioma, mantido"
  else
    { printf '\n\n'; cat "$OVERLAY/CLAUDE.md"; } >> "$PROJECT/CLAUDE.md"
    ok "CLAUDE.md existente complementado com as regras de idioma"
  fi
else
  cp "$OVERLAY/CLAUDE.md" "$PROJECT/CLAUDE.md"
  ok "CLAUDE.md criado"
fi

# 4. Registro da aplicação
{
  printf '{\n'
  printf '  "pack_upstream_version": "%s",\n' "$PACK_VERSION"
  printf '  "pack_upstream_commit": "%s",\n' "$PACK_COMMIT"
  printf '  "script_variant": "%s",\n' "$VARIANT"
  printf '  "applied_at": "%s",\n' "$(date +%Y-%m-%dT%H:%M:%S%z)"
  printf '  "files": [\n'
  for i in "${!UPSTREAM_FILES[@]}"; do
    sep=","; [ "$i" -eq $((${#UPSTREAM_FILES[@]} - 1)) ] && sep=""
    printf '    "%s"%s\n' "${UPSTREAM_FILES[$i]}" "$sep"
  done
  printf '  ]\n}\n'
} > "$PROJECT/.specify/ptbr.json"
ok "Registro gravado em .specify/ptbr.json"

echo
printf '\033[32mPronto. Abra o Claude Code no projeto e comece por /speckit-constitution.\033[0m\n'
