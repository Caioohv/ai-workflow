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

if [[ -d "$TARGET" && "$(cd "$TARGET" && pwd -P)" == "$(cd "$SCRIPT_DIR" && pwd -P)" ]]; then
  echo "Erro: use uma pasta de destino diferente do repositório do setup."
  exit 1
fi

# Atualiza somente o bloco do workflow, preservando instruções locais do projeto.
install_codex_instructions() {
  local dest="$TARGET/AGENTS.md" temp
  temp="$(mktemp "$TARGET/.ai-workflow-agents.XXXXXX")"
  if [[ -f "$dest" ]]; then
    if ! awk '
      $0 == "<!-- ai-workflow:begin -->" {
        if (managed || seen) exit 1
        managed = 1; seen = 1; next
      }
      $0 == "<!-- ai-workflow:end -->" {
        if (!managed) exit 1
        managed = 0; next
      }
      !managed { print }
      END { if (managed) exit 1 }
    ' "$dest" > "$temp"; then
      rm -f "$temp"
      echo "Erro: bloco ai-workflow inválido em $dest. Corrija os marcadores antes de continuar."
      exit 1
    fi
  fi
  cat "$SCRIPT_DIR/AGENTS.md" >> "$temp"
  mv "$temp" "$dest"
  echo "  instruções Codex atualizadas: $dest"
}

# Copia um arquivo apenas se ele ainda não existir no destino (nunca sobrescreve).
copy_if_absent() {
  local src="$1" dest="$2"
  if [[ -e "$dest" ]]; then
    echo "  mantido (já existe): $dest"
  else
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    echo "  criado: $dest"
  fi
}

# Copia uma pasta recursivamente, arquivo a arquivo, sem sobrescrever o que já existe.
copy_tree_if_absent() {
  local src_dir="$1" dest_dir="$2"
  local f rel
  while IFS= read -r -d '' f; do
    rel="${f#"$src_dir"/}"
    copy_if_absent "$f" "$dest_dir/$rel"
  done < <(find "$src_dir" -type f -print0)
}

if $UPDATE; then
  if [[ ! -d "$TARGET/.claude" && ! -d "$TARGET/.agents" ]]; then
    echo "Erro: '$TARGET' não tem um workflow instalado. Rode sem --update para fazer o setup inicial."
    exit 1
  fi

  # Atualiza os arquivos gerenciados pelo framework (Claude Code)
  if [[ -d "$TARGET/.claude" ]]; then
    rm -rf "$TARGET/.claude/agents" "$TARGET/.claude/skills"
    cp -r "$SCRIPT_DIR/.claude/agents" "$TARGET/.claude/"
    cp -r "$SCRIPT_DIR/.claude/skills" "$TARGET/.claude/"
    cp "$SCRIPT_DIR/.claude/settings.json" "$TARGET/.claude/settings.json"
    cp "$SCRIPT_DIR/CLAUDE.md" "$TARGET/CLAUDE.md"
  fi

  # Atualiza os arquivos gerenciados pelo framework (Antigravity)
  rm -rf "$TARGET/.agents/rules" "$TARGET/.agents/skills"
  mkdir -p "$TARGET/.agents"
  cp -r "$SCRIPT_DIR/.agents/rules" "$TARGET/.agents/"
  cp -r "$SCRIPT_DIR/.agents/skills" "$TARGET/.agents/"
  cp "$SCRIPT_DIR/GEMINI.md" "$TARGET/GEMINI.md"
  install_codex_instructions

  rm -rf "$TARGET/workflow/templates"
  cp -r "$SCRIPT_DIR/workflow/templates" "$TARGET/workflow/"

  echo "Workflow atualizado em: $TARGET"
  echo "Conteúdo de workflow/ e instruções locais de AGENTS.md preservados; agentes, skills, regras e templates atualizados."
  exit 0
fi

mkdir -p "$TARGET"

# Setup inicial: copia tudo, mas nunca sobrescreve arquivos que já existam no destino.
copy_tree_if_absent "$SCRIPT_DIR/.claude" "$TARGET/.claude"
copy_tree_if_absent "$SCRIPT_DIR/.agents" "$TARGET/.agents"
copy_if_absent "$SCRIPT_DIR/CLAUDE.md" "$TARGET/CLAUDE.md"
copy_if_absent "$SCRIPT_DIR/GEMINI.md" "$TARGET/GEMINI.md"
install_codex_instructions
copy_tree_if_absent "$SCRIPT_DIR/workflow/templates" "$TARGET/workflow/templates"
copy_if_absent "$SCRIPT_DIR/workflow/definition.md" "$TARGET/workflow/definition.md"
copy_if_absent "$SCRIPT_DIR/workflow/project-memory.md" "$TARGET/workflow/project-memory.md"

mkdir -p \
  "$TARGET/workflow/todos" \
  "$TARGET/workflow/tasks/todo" \
  "$TARGET/workflow/tasks/in-progress" \
  "$TARGET/workflow/tasks/to-review" \
  "$TARGET/workflow/tasks/done" \
  "$TARGET/workflow/steps/todo" \
  "$TARGET/workflow/steps/in-progress" \
  "$TARGET/workflow/steps/done"

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
echo 'Abra o Codex e use $discover, ou o Claude Code/Antigravity e use /discover.'
