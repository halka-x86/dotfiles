#!/bin/bash
set -e

readonly DOTFILES_DIRECTORY="${HOME}/dotfiles"
readonly DOTFILES_HOME="${DOTFILES_DIRECTORY}/dotfiles"

# restore コマンドの対象（HOME からの相対パス）
readonly TARGET_DIRS=(
  ".config"
  ".claude"
  ".codex"
)

# restore コマンドで dotfiles に残す管理対象（HOME からの相対パス）
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
  $(basename $0) <command> [Options]

Commands:
  restore    Restore symlinked dotfile directories to real directories.
             Targets: ${TARGET_DIRS[*]}
  uninstall  Replace symlinks pointing to ${DOTFILES_HOME} with real files.

Run '$(basename $0) <command> -h' for command-specific options.
_EOT_
}

usage_restore() {
  cat <<_EOT_
Usage:
  $(basename $0) restore [Options]

Description:
  Restore symlinked dotfile directories to real directories.
  Targets: ${TARGET_DIRS[*]}
  Each directory's symlink is replaced with a real directory,
  and dotfiles is trimmed to managed entries only.

Options:
  -n  Dry-run (no changes will be made)
  -h  Show this help
_EOT_
}

usage_uninstall() {
  cat <<_EOT_
Usage:
  $(basename $0) uninstall [Options]

Description:
  Replace symlinks managed by install.sh with real files.
  Only symlinks pointing to ${DOTFILES_HOME} are affected.

Options:
  -n  Dry-run (no changes will be made)
  -h  Show this help
_EOT_
}


################################################################################
# ヘルパー

DRY_RUN=false

run() {
  if "${DRY_RUN}"; then
    echo "  [dry-run] $*"
  else
    "$@"
  fi
}

# dry-run でなければ確認プロンプトを表示し、拒否されたら終了する
confirm() {
  "${DRY_RUN}" && return 0

  echo ""
  echo "$1"
  echo ""
  read -rp "Proceed? [y/N]: " answer
  case "${answer}" in
    [yY]) ;;
    *) echo "Aborted."; exit 0 ;;
  esac
  echo ""
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
# restore コマンド

restore_check_preconditions() {
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

cmd_restore() {
  while getopts ":nh" opt; do
    case ${opt} in
      n)  DRY_RUN=true ;;
      h)  usage_restore; exit 0 ;;
      *)  echo "Invalid option"; usage_restore; exit 1 ;;
    esac
  done

  if "${DRY_RUN}"; then
    echo "=== [dry-run mode] No changes will be made ==="
  fi
  echo "=== dotfiles symlink restore ==="
  echo ""

  restore_check_preconditions

  # 実行確認（dry-run 時はスキップ）
  local message="The following changes will be made:"
  for dir in "${TARGET_DIRS[@]}"; do
    message+=$'\n'"  - Replace ~/${dir} symlink with a real directory"
  done
  message+=$'\n'"  - Trim dotfiles managed directories to listed entries only"
  confirm "${message}"

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
# uninstall コマンド

uninstall_file() {
  local src="$1"
  local rel="${src#$DOTFILES_HOME/}"
  local dst="${HOME}/${rel}"

  # DOTFILES_HOME を指すシンボリックリンクのみ対象
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    run unlink "$dst"
    run cp "$src" "$dst"
    echo "  replaced: ~/${rel}"
  fi
}

uninstall_check_preconditions() {
  echo "[check] Verifying preconditions..."

  if [ ! -d "${DOTFILES_HOME}" ]; then
    echo "Error: ${DOTFILES_HOME} does not exist. Aborting."
    exit 1
  fi

  echo "  OK: ${DOTFILES_HOME} found"
}

cmd_uninstall() {
  while getopts ":nh" opt; do
    case ${opt} in
      n)  DRY_RUN=true ;;
      h)  usage_uninstall; exit 0 ;;
      *)  echo "Invalid option"; usage_uninstall; exit 1 ;;
    esac
  done

  if "${DRY_RUN}"; then
    echo "=== [dry-run mode] No changes will be made ==="
  fi
  echo "=== dotfiles uninstall ==="
  echo ""

  uninstall_check_preconditions

  # 実行確認（dry-run 時はスキップ）
  confirm "Symlinks pointing to ${DOTFILES_HOME} will be replaced with real files."

  echo "[1/2] Replacing symlinks with real files..."
  local count=0

  # DOTFILES_HOME 以下の全ファイルを走査して対応する HOME のシンボリックリンクを置き換え
  while IFS= read -r -d '' src; do
    uninstall_file "$src"
    count=$((count + 1))
  done < <(find "${DOTFILES_HOME}" -type f -print0)

  echo ""
  echo "[2/2] Done."
  if "${DRY_RUN}"; then
    echo "  ${count} file(s) would be replaced."
  else
    echo "  ${count} file(s) processed."
  fi

  echo ""
  echo "$(tput setaf 2)Uninstall complete!$(tput sgr0)"
}


################################################################################
# main

main() {
  local cmd="$1"

  case "${cmd}" in
    restore)
      shift
      cmd_restore "$@"
      ;;
    uninstall)
      shift
      cmd_uninstall "$@"
      ;;
    -h|--help|"")
      usage
      exit 0
      ;;
    *)
      echo "Unknown command: ${cmd}"
      usage
      exit 1
      ;;
  esac
}


################################################################################
# Entrypoint

main "$@"

exit 0
