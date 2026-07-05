#!/bin/bash
set -e

readonly DOTFILES_DIRECTORY="${HOME}/dotfiles"
readonly DOTFILES_HOME="${DOTFILES_DIRECTORY}/dotfiles"

# 復元対象のシンボリックリンクディレクトリ（HOME からの相対パス）
readonly TARGET_DIRS=(
  ".config"
  ".claude"
  ".codex"
)

# dotfiles に残す管理対象（HOME からの相対パス）
# ファイルはそのまま、ディレクトリは中身を再帰的にコピー
readonly MANAGED=(
  ".config/fish/config.fish"
  ".config/fish/poetry.fish"
  ".claude/CLAUDE.md"
  ".codex/AGENTS.md"
  ".codex/skills"
)

# MANAGED 内のディレクトリをコピーする際に除外するパス（HOME からの相対パス）
readonly EXCLUDED=(
  ".codex/skills/.system"
)


################################################################################
# Usage
usage() {
  cat <<_EOT_
Usage:
  $(basename $0) [Options]

Options:
  -n  Dry-run (no changes will be made)
  -h  Show this help

Description:
  Restore symlinked dotfile directories to real directories.
  Targets: ${TARGET_DIRS[*]}
  Each directory's symlink is replaced with a real directory,
  and dotfiles is trimmed to managed entries only.
_EOT_
}


################################################################################
# オプション解析
DRY_RUN=false

while getopts ":nh" opt; do
  case ${opt} in
    n)  DRY_RUN=true ;;
    h)  usage; exit 0 ;;
    *)  echo "Invalid option"; usage; exit 1 ;;
  esac
done


################################################################################
# ヘルパー

run() {
  if "${DRY_RUN}"; then
    echo "  [dry-run] $*"
  else
    "$@"
  fi
}

# 除外対象かどうか判定（HOME からの相対パスで比較）
is_excluded() {
  local path="$1"
  for excl in "${EXCLUDED[@]}"; do
    if [[ "$path" == "$excl" || "$path" == "$excl"/* ]]; then
      return 0
    fi
  done
  return 1
}

# エントリ（ファイルまたはディレクトリ）を src から dst へコピー
copy_entry() {
  local entry="$1"   # HOME からの相対パス
  local src_base="$2"
  local dst_base="$3"

  local src="${src_base}/${entry}"
  local dst="${dst_base}/${entry}"

  if [ ! -e "$src" ]; then
    echo "  skip (not found): ${entry}"
    return
  fi

  if [ -f "$src" ]; then
    run mkdir -p "$(dirname "$dst")"
    run cp "$src" "$dst"
    echo "  copied: ${entry}"
  elif [ -d "$src" ]; then
    # ディレクトリは find でファイル単位にコピーし、除外リストを適用
    while IFS= read -r -d '' item; do
      local rel="${entry}${item#$src}"
      is_excluded "$rel" && continue
      local dst_item="${dst_base}/${rel}"
      if [ -d "$item" ]; then
        run mkdir -p "$dst_item"
      else
        run mkdir -p "$(dirname "$dst_item")"
        run cp "$item" "$dst_item"
      fi
    done < <(find "$src" -print0)
    echo "  copied: ${entry}/"
  fi
}


################################################################################
# 前提条件チェック

check_preconditions() {
  echo "[check] Verifying preconditions..."

  local ok=true
  for dir in "${TARGET_DIRS[@]}"; do
    local dst="${HOME}/${dir}"
    local expected_target="${DOTFILES_HOME}/${dir}"

    if [ ! -L "$dst" ]; then
      echo "  Warning: ~/${dir} is not a symlink — skipping"
      continue
    fi

    local link_target
    link_target=$(readlink "$dst")
    if [ "$link_target" != "$expected_target" ]; then
      echo "  Error: ~/${dir} does not point to ${expected_target} (current: ${link_target})"
      ok=false
      continue
    fi

    echo "  OK: ~/${dir} -> ${expected_target}"
  done

  "${ok}" || exit 1
}


################################################################################
# main

main() {
  if "${DRY_RUN}"; then
    echo "=== [dry-run mode] No changes will be made ==="
  fi
  echo "=== dotfiles symlink restore script ==="
  echo ""

  check_preconditions

  # 実行確認（dry-run 時はスキップ）
  if ! "${DRY_RUN}"; then
    echo ""
    echo "The following changes will be made:"
    for dir in "${TARGET_DIRS[@]}"; do
      echo "  - Replace ~/${dir} symlink with a real directory"
    done
    echo "  - Trim dotfiles managed directories to listed entries only"
    echo ""
    read -rp "Proceed? [y/N]: " answer
    case "${answer}" in
      [yY]) ;;
      *) echo "Aborted."; exit 0 ;;
    esac
    echo ""
  fi

  TMPDIR_WORK=$(mktemp -d)

  # Step 1: 管理対象エントリを一時領域に保存
  echo "[1/4] Saving managed entries..."
  for entry in "${MANAGED[@]}"; do
    copy_entry "$entry" "${DOTFILES_HOME}" "${TMPDIR_WORK}"
  done

  # Step 2: シンボリックリンクを解除して実ディレクトリとしてコピー
  echo ""
  echo "[2/4] Replacing symlinks with real directories..."
  for dir in "${TARGET_DIRS[@]}"; do
    local dst="${HOME}/${dir}"
    local src="${DOTFILES_HOME}/${dir}"

    # シンボリックリンクでない場合はスキップ
    [ -L "$dst" ] || continue

    run unlink "$dst"
    run cp -r "$src" "$dst"
    echo "  ~/${dir}: replaced with real directory"
  done

  # Step 3: dotfiles の各ディレクトリを管理対象エントリのみに再構築
  echo ""
  echo "[3/4] Rebuilding dotfiles directories with managed entries only..."
  for dir in "${TARGET_DIRS[@]}"; do
    local src="${DOTFILES_HOME}/${dir}"
    run rm -rf "$src"
    run mkdir -p "$src"
    echo "  cleared: dotfiles/${dir}/"
  done
  for entry in "${MANAGED[@]}"; do
    copy_entry "$entry" "${TMPDIR_WORK}" "${DOTFILES_HOME}"
  done
  run rm -rf "${TMPDIR_WORK}"

  # Step 4: 確認
  echo ""
  echo "[4/4] Verifying result..."
  if ! "${DRY_RUN}"; then
    for dir in "${TARGET_DIRS[@]}"; do
      local dst="${HOME}/${dir}"
      if [ -L "$dst" ]; then
        echo "  Error: ~/${dir} is still a symlink"
        exit 1
      else
        echo "  ~/${dir}: real directory ✔"
      fi
    done
    echo ""
    echo "  Managed entries in dotfiles:"
    for entry in "${MANAGED[@]}"; do
      local path="${DOTFILES_HOME}/${entry}"
      if [ -f "$path" ]; then
        echo "    ${entry}"
      elif [ -d "$path" ]; then
        find "$path" -type f | sed "s|${DOTFILES_HOME}/||" | sort | sed 's/^/    /'
      fi
    done
  fi

  echo ""
  echo "$(tput setaf 2)Done!$(tput sgr0)"
}


################################################################################
# Entrypoint

main

exit 0
