#!/usr/bin/env bash
set -euo pipefail

UPDATE=false
ARGS=()
for arg in "$@"; do
  if [[ "$arg" == "--update" ]]; then
    UPDATE=true
  else
    ARGS+=("$arg")
  fi
done

TARGET="${ARGS[0]:-}"

if [[ -z "$TARGET" ]]; then
  echo "Uso: ./setup.sh <pasta-destino> [--update]"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if $UPDATE; then
  if [[ ! -d "$TARGET/.claude" ]]; then
    echo "Erro: '$TARGET' não tem um workflow instalado. Rode sem --update para fazer o setup inicial."
    exit 1
  fi

  rm -rf "$TARGET/.claude"
  cp -r "$SCRIPT_DIR/.claude" "$TARGET/"
  cp "$SCRIPT_DIR/CLAUDE.md" "$TARGET/"
  cp -r "$SCRIPT_DIR/workflow/templates" "$TARGET/workflow/"

  echo "Workflow atualizado em: $TARGET"
  exit 0
fi

mkdir -p "$TARGET"

cp -r "$SCRIPT_DIR/.claude" "$TARGET/"
cp "$SCRIPT_DIR/CLAUDE.md" "$TARGET/"

mkdir -p \
  "$TARGET/workflow/tasks/todo" \
  "$TARGET/workflow/tasks/in-progress" \
  "$TARGET/workflow/tasks/to-review" \
  "$TARGET/workflow/tasks/done" \
  "$TARGET/workflow/steps/todo" \
  "$TARGET/workflow/steps/in-progress" \
  "$TARGET/workflow/steps/done"

cp -r "$SCRIPT_DIR/workflow/templates" "$TARGET/workflow/"
cp "$SCRIPT_DIR/workflow/definition.md" "$TARGET/workflow/"
cp "$SCRIPT_DIR/workflow/project-memory.md" "$TARGET/workflow/"

touch \
  "$TARGET/workflow/tasks/todo/.gitkeep" \
  "$TARGET/workflow/tasks/in-progress/.gitkeep" \
  "$TARGET/workflow/tasks/to-review/.gitkeep" \
  "$TARGET/workflow/tasks/done/.gitkeep" \
  "$TARGET/workflow/steps/todo/.gitkeep" \
  "$TARGET/workflow/steps/in-progress/.gitkeep" \
  "$TARGET/workflow/steps/done/.gitkeep"

if [[ ! -d "$TARGET/.git" ]]; then
  git -C "$TARGET" init -q
  echo "Repositório git inicializado."
fi

echo "Setup concluído em: $TARGET"
echo "Abra o Claude Code na pasta e rode /init para começar."
