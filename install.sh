#!/bin/bash
set -e

readonly DOTFILES_TARBALL="https://github.com/halka-x86/dotfiles/tarball/master"
readonly REMOTE_URL="git@github.com:halka-x86/dotfiles.git"
readonly DOTFILES_EXCLUDES=(".git" ".gitignore" ".vscode")   # 無視したいファイルやディレクトリ
readonly DOTFILES_DIRECTORY="${HOME}/dotfiles"               # リポジトリルート
readonly DOTFILES_HOME="${DOTFILES_DIRECTORY}/dotfiles"      # デプロイ対象ファイルのディレクトリ
readonly DOTFILES_BACKUP_DIRECTORY="${HOME}/dotfiles_backup" # 現行の設定のバックアップ保存先


################################################################################
# Usage
function usage() {
  name=$(basename $0)
  cat <<_EOT_
Usage:
  $name [Options]
Options:
  -f $(tput setaf 1)** warning **$(tput sgr0) Overwrite dotfiles.
  -d Deploy only (without install package)
  -n Dry-run (no changes will be made)
  -g Using git.
  -b install without fish
  -h Print help (this message)
_EOT_
}


################################################################################
# オプション解析 (-f:上書き -d:デプロイのみ -n:ドライラン -g:gitを使用する -b:fishはインストールから除外する -h:ヘルプ表示)
DRY_RUN=false

while getopts ":fdngbh" opt
do
  case ${opt} in
    f)  readonly OVERWRITE=true ;;
    d)  readonly DEPLOY_ONLY=true ;;
    n)  DRY_RUN=true ;;
    g)  readonly USE_GIT=true ;;
    b)  readonly WITHOUT_FISH=true ;;
    h)  usage
        exit 0
        ;;
    *)  echo "Invalid option"
        usage
        exit 1
        ;;
  esac
done
shift $((OPTIND - 1))


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
# dotfilesをダウンロード(存在する場合は上書き)

function download_dotfiles() {

  echo "Downloading dotfiles..."

  # dotfileがすでに存在する場合削除
  run rm -rf ${DOTFILES_DIRECTORY}
  run mkdir ${DOTFILES_DIRECTORY}

  # gitオプションが使用されているかつgitインストール済みであればgitでダウンロード
  if [ -n "${USE_GIT}" ] && [ type "git" >/dev/null 2>&1 ]; then
    run git clone --recursive "${REMOTE_URL}" "${DOTFILES_DIRECTORY}"
  else
    # curlでダウンロード
    run curl -kfsSLo ${HOME}/dotfiles.tar.gz ${DOTFILES_TARBALL}
    run tar -zxf ${HOME}/dotfiles.tar.gz --strip-components 1 -C ${DOTFILES_DIRECTORY}
    run rm -f ${HOME}/dotfiles.tar.gz
  fi

  echo $(tput setaf 2)Download dotfiles complete!. ✔︎$(tput sgr0)

  return 0
}


################################################################################
#  パッケージインストール

# 必要なパッケージインストール
install_essential_packages() {
  echo "Install packages..."

  run env DEBIAN_FRONTEND=noninteractive \
  apt-get install -y \
    curl \
    make \
    git \
    ;

  echo "$(tput setaf 2)Installed packages complete!. ✔︎$(tput sgr0)"

  return 0
}

install_fish_packages() {
  echo "Install fisf packages..."

  run env DEBIAN_FRONTEND=noninteractive \
  apt-get install -y \
    fish \
    ;

  echo "$(tput setaf 2)Installed packages complete!. ✔︎$(tput sgr0)"

  return 0
}


################################################################################
# Deploy処理 (ドットファイルをホームディレクトリに配置&リンク)

# ファイル1つのシンボリックリンク作成（既存ファイルはバックアップ）
link_file() {
  local src="$1"
  local dst="$2"

  if [ -f "$dst" ] || [ -L "$dst" ]; then
    local rel="${dst#$HOME/}"
    local backup_path="${BACKUP_DIR}/${rel}"
    run mkdir -p "$(dirname "$backup_path")"
    run mv "$dst" "$backup_path"
  fi

  run mkdir -p "$(dirname "$dst")"
  run ln -snfv "$src" "$dst"
}

# ディレクトリを再帰的に処理してファイル単位でリンク
link_dir() {
  local src_dir="$1"
  local dst_dir="$2"

  run mkdir -p "$dst_dir"

  for item in "$src_dir"/.[!.]* "$src_dir"/*; do
    [ -e "$item" ] || continue
    local name
    name=$(basename "$item")

    if [ -d "$item" ]; then
      link_dir "$item" "$dst_dir/$name"
    else
      link_file "$item" "$dst_dir/$name"
    fi
  done
}

deploy() {

  cd "${DOTFILES_HOME}"

  # 実行日時を名前としたバックアップディレクトリを作成
  readonly BACKUP_DIR="${DOTFILES_BACKUP_DIRECTORY}/$(date +%Y%m%d%H%M%S)"
  run mkdir -p "${BACKUP_DIR}"

  for f in .??*; do

    # 無視したいファイルやディレクトリ
    [[ "${DOTFILES_EXCLUDES[*]}" =~ ${f} ]] && continue

    local src="${DOTFILES_HOME}/${f}"
    local dst="${HOME}/${f}"

    if [ -d "$src" ]; then
      # ディレクトリはファイル単位でシンボリックリンクを作成
      link_dir "$src" "$dst"
    else
      link_file "$src" "$dst"
    fi

  done

  # バックアップディレクトリが空なら削除（dry-run 時はディレクトリ自体が存在しない）
  if ! "${DRY_RUN}"; then
    if [ -z "$(ls -A "${BACKUP_DIR}")" ]; then
      rm -r "${BACKUP_DIR}"
    else
      echo "backup current dotfiles to ${BACKUP_DIR}"
    fi
  fi

  echo "$(tput setaf 2)Deploy dotfiles complete!. ✔︎$(tput sgr0)"

  return 0
}



################################################################################
# main

main() {

  if "${DRY_RUN}"; then
    echo "=== [dry-run mode] No changes will be made ==="
  fi

  # 必要なパッケージをインストール(デプロイのみのオプションがない場合)
  if [ -z "${DEPLOY_ONLY}" ]; then
    install_essential_packages
  fi

  # fishパッケージをインストール(デプロイのみ及びfish除外のオプションがない場合)
  if [ -z "${DEPLOY_ONLY}" ] && [ -z "${WITHOUT_FISH}" ]; then
    install_fish_packages
  fi

  # Dotfilesがない，あるいは上書きオプションがあればダウンロード
  if [ -n "${OVERWRITE}" ] || [ ! -d ${DOTFILES_DIRECTORY} ]; then
    download_dotfiles
  fi

  # ドットファイルのシンボリックリンク作成
  deploy

  return 0
}


################################################################################
# Entrypoint script

main

exit 0
