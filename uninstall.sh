#!/bin/bash
set -e

readonly DOTFILES_DIRECTORY="${HOME}/dotfiles"
readonly DOTFILES_HOME="${DOTFILES_DIRECTORY}/dotfiles"


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
  Replace symlinks managed by install.sh with real files.
  Only symlinks pointing to ${DOTFILES_HOME} are affected.
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


################################################################################
# シンボリックリンクを実ファイルに置き換え

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


################################################################################
# 前提条件チェック

check_preconditions() {
  echo "[check] Verifying preconditions..."

  if [ ! -d "${DOTFILES_HOME}" ]; then
    echo "Error: ${DOTFILES_HOME} does not exist. Aborting."
    exit 1
  fi

  echo "  OK: ${DOTFILES_HOME} found"
}


################################################################################
# main

main() {
  if "${DRY_RUN}"; then
    echo "=== [dry-run mode] No changes will be made ==="
  fi
  echo "=== dotfiles uninstall script ==="
  echo ""

  check_preconditions

  # 実行確認（dry-run 時はスキップ）
  if ! "${DRY_RUN}"; then
    echo ""
    echo "Symlinks pointing to ${DOTFILES_HOME} will be replaced with real files."
    echo ""
    read -rp "Proceed? [y/N]: " answer
    case "${answer}" in
      [yY]) ;;
      *) echo "Aborted."; exit 0 ;;
    esac
    echo ""
  fi

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
# Entrypoint

main

exit 0
