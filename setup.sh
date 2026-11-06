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

if $UPDATE && [[ ! -d "$TARGET/.claude" && ! -d "$TARGET/.agents" ]]; then
  echo "Erro: '$TARGET' não tem um workflow instalado. Rode sem --update para fazer o setup inicial."
  exit 1
fi

BEGIN_MARK="<!-- ai-workflow:begin -->"
END_MARK="<!-- ai-workflow:end -->"
MANIFEST="$TARGET/workflow/.ai-workflow-manifest"

# Instalação nova, ou atualização de um projeto que já usa Claude Code, recebe os arquivos do Claude.
WITH_CLAUDE=true
if $UPDATE && [[ ! -d "$TARGET/.claude" ]]; then
  WITH_CLAUDE=false
fi

# Instruções com bloco gerenciado: o conteúdo local fica, o bloco do framework vai para o fim.
BLOCK_FILES=(AGENTS.md GEMINI.md)
if $WITH_CLAUDE; then
  BLOCK_FILES+=(CLAUDE.md)
fi

# sha256 de versões antigas de CLAUDE.md/GEMINI.md, instaladas inteiras antes do bloco gerenciado.
# Um arquivo idêntico a uma delas é só do framework e pode ser substituído pelo bloco.
LEGACY_HASHES=(
  135d269ee037042fccdbcf75c2be609fd6e05292ae001baca919ce6e3f555bf4
  213b4aaed6f09c53b8d2a3e4f384f495f3dd597857b51a6229f83d307c0ff58e
  2be501c7d44114748626a3a5211b8f335b8898943321f7da4178b8584d665353
  330ac85be32655e6769e2f3d050d23b06ee7575087e44c4041dd8789f0226272
  4fc7bebfd1260f40eb9cfcf57d41ca913c9188f064ece98973e6b4a550a23154
  56c03ebecc9183f6397b3566fe879c632c06eb911f0cc9e4ed65d98336735d97
  649a215ff735c73a50b3349bd9b560058b3a71efdcf3378d12a0c46563590a28
  866e3d155c6566ff71e1bd673e84778c960871ee63cdf94e9cf03093badf36d4
  979446df2877a6c31f18897566d6412d4ffa3f5a4820d8f1731e97af9bf7c0b5
  c0ec9941ebdb489e3ff200e843a7391c03eeb5e7bba64cd9f90a40125db20088
  cadd35c96d33e5c7e5640a0debdd57e0d489ec94fc9ade236a953a9c84fec416
  d397a94448fd4d2c1622012be1c729e5177b693fbe0a51b0295e4a964ca49d43
  da9b561de77ad83948a52b977b262dc99c5a878d8c9e1d3573f17b30182072da
  f01daa6bc2812b176f348e907fd122e78a13aa66f7629d677da5371338141e91
  f30a271938158daad9cbb238f580c1d0b730515da8b9cc595522382e369a3f2e
  f7a686cc1b910c603aaecb06b0e6b9ae969556df70f3733ff27339944e8fa484
)

file_sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d' ' -f1
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | cut -d' ' -f1
  fi
}

is_legacy_copy() {
  local hash h
  grep -Fxq -- "$BEGIN_MARK" "$1" && return 1
  hash="$(file_sha256 "$1")"
  [[ -n "$hash" ]] || return 1
  for h in "${LEGACY_HASHES[@]}"; do
    [[ "$h" == "$hash" ]] && return 0
  done
  return 1
}

# Imprime o arquivo sem o bloco gerenciado; falha se os marcadores estiverem inválidos.
strip_block() {
  awk -v begin="$BEGIN_MARK" -v end="$END_MARK" '
    $0 == begin {
      if (managed || seen) exit 1
      managed = 1; seen = 1; next
    }
    $0 == end {
      if (!managed) exit 1
      managed = 0; next
    }
    !managed { print }
    END { if (managed) exit 1 }
  ' "$1"
}

# Valida todos os marcadores antes de mudar qualquer arquivo.
for name in "${BLOCK_FILES[@]}"; do
  if [[ -f "$TARGET/$name" ]] && ! strip_block "$TARGET/$name" > /dev/null; then
    echo "Erro: bloco ai-workflow inválido em $TARGET/$name. Corrija os marcadores antes de continuar."
    exit 1
  fi
done

install_block() {
  local name="$1" dest="$TARGET/$1" temp
  temp="$(mktemp "$TARGET/.ai-workflow-block.XXXXXX")"
  if [[ -f "$dest" ]] && ! is_legacy_copy "$dest"; then
    strip_block "$dest" > "$temp"
  fi
  cat "$SCRIPT_DIR/$name" >> "$temp"
  chmod 644 "$temp"
  mv "$temp" "$dest"
  echo "  instruções atualizadas: $dest"
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

# Arquivos que pertencem ao framework, relativos à raiz do projeto.
managed_list() {
  local roots=(.agents/skills .agents/rules workflow/templates)
  if $WITH_CLAUDE; then
    roots=(.claude/agents .claude/skills "${roots[@]}")
  fi
  {
    (cd "$SCRIPT_DIR" && find "${roots[@]}" -type f ! -name '.DS_Store')
    echo workflow/verify.sh
  } | LC_ALL=C sort
}

# Só caminhos dentro das pastas do framework podem ser removidos a partir do manifesto.
is_managed_path() {
  case "$1" in
    *..* | /*) return 1 ;;
    .claude/agents/* | .claude/skills/* | .agents/skills/* | .agents/rules/* | workflow/templates/* | workflow/verify.sh) return 0 ;;
    *) return 1 ;;
  esac
}

# Remove arquivos que o framework instalou antes e não distribui mais. Os do projeto ficam.
remove_obsolete() {
  local list="$1" f dir
  if [[ ! -f "$MANIFEST" ]]; then
    return 0
  fi
  while IFS= read -r f; do
    if ! is_managed_path "$f" || grep -Fxq -- "$f" "$list"; then
      continue
    fi
    if [[ -f "$TARGET/$f" ]]; then
      rm -f "$TARGET/$f"
      echo "  removido (saiu do framework): $f"
    fi
  done < "$MANIFEST"
  for dir in .claude/agents .claude/skills .agents/skills .agents/rules workflow/templates; do
    if [[ -d "$TARGET/$dir" ]]; then
      find "$TARGET/$dir" -mindepth 1 -type d -empty -delete
    fi
  done
}

install_managed() {
  local list="$1" overwrite="$2" f
  while IFS= read -r f; do
    if $overwrite; then
      mkdir -p "$(dirname "$TARGET/$f")"
      cp "$SCRIPT_DIR/$f" "$TARGET/$f"
    else
      copy_if_absent "$SCRIPT_DIR/$f" "$TARGET/$f"
    fi
  done < "$list"
  chmod +x "$TARGET/workflow/verify.sh"
  cp "$list" "$MANIFEST"
}

mkdir -p "$TARGET/workflow"
LIST="$(mktemp "$TARGET/.ai-workflow-list.XXXXXX")"
trap 'rm -f "$LIST"' EXIT
managed_list > "$LIST"

if $UPDATE; then
  remove_obsolete "$LIST"
  install_managed "$LIST" true
  if $WITH_CLAUDE; then
    copy_if_absent "$SCRIPT_DIR/.claude/settings.json" "$TARGET/.claude/settings.json"
  fi
  for name in "${BLOCK_FILES[@]}"; do
    install_block "$name"
  done
  mkdir -p "$TARGET/workflow/manual-tasks" "$TARGET/workflow/decisions"
  touch "$TARGET/workflow/manual-tasks/.gitkeep" "$TARGET/workflow/decisions/.gitkeep"

  echo "Workflow atualizado em: $TARGET"
  echo "Atualizados: agentes, skills, regras, templates e workflow/verify.sh do framework, e o bloco ai-workflow das instruções."
  echo "Preservados: estado em workflow/, texto fora do bloco ai-workflow, agentes/skills/regras do projeto e .claude/settings.json."
  exit 0
fi

# Setup inicial: nunca sobrescreve arquivos que já existam no destino.
install_managed "$LIST" false
copy_if_absent "$SCRIPT_DIR/.claude/settings.json" "$TARGET/.claude/settings.json"
for name in "${BLOCK_FILES[@]}"; do
  install_block "$name"
done
copy_if_absent "$SCRIPT_DIR/workflow/definition.md" "$TARGET/workflow/definition.md"
copy_if_absent "$SCRIPT_DIR/workflow/project-memory.md" "$TARGET/workflow/project-memory.md"

mkdir -p \
  "$TARGET/workflow/todos" \
  "$TARGET/workflow/manual-tasks" \
  "$TARGET/workflow/decisions" \
  "$TARGET/workflow/tasks/todo" \
  "$TARGET/workflow/tasks/in-progress" \
  "$TARGET/workflow/tasks/to-review" \
  "$TARGET/workflow/tasks/done" \
  "$TARGET/workflow/steps/todo" \
  "$TARGET/workflow/steps/in-progress" \
  "$TARGET/workflow/steps/done"

touch \
  "$TARGET/workflow/manual-tasks/.gitkeep" \
  "$TARGET/workflow/decisions/.gitkeep" \
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
echo 'Em dúvida sobre o próximo passo? Use $orchestrator (Codex) ou /orchestrator.'
