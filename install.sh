#!/bin/bash
set -e

# readonly DOTFILES_TARBALL="https://github.com/halka-x86/dotfiles/tarball/master"
readonly DOTFILES_TARBALL="https://github.com/halka-x86/dotfiles/tarball/develop"
readonly REMOTE_URL="git@github.com:halka-x86/dotfiles.git"
readonly DOTFILES_EXCLUDES=(".git" ".gitignore" ".vscode")   # 無視したいファイルやディレクトリ
readonly DOTFILES_DIRECTORY="${HOME}/dotfiles"               # ホームディレクトリに展開
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
  -g Using git.
  -h Print help (this message)
_EOT_
}


################################################################################
# オプション解析 (-f:上書き -g:gitを使用する -h:ヘルプ表示)
while getopts ":fgh" opt
do
  case ${opt} in
    f)  readonly OVERWRITE=true ;;
    g)  readonly USE_GIT=true ;;
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
# dotfilesをダウンロード(存在する場合は上書き)

function download_dotfiles() {

  echo "Downloading dotfiles..."

  # dotfileがすでに存在する場合削除
  rm -rf ${DOTFILES_DIRECTORY}
  mkdir ${DOTFILES_DIRECTORY}

  # gitオプションが使用されているかつgitインストール済みであればgitでダウンロード
  if [ -n "${USE_GIT}" ] && [ type "git" >/dev/null 2>&1 ]; then
    git clone --recursive "${REMOTE_URL}" "${DOTFILES_DIRECTORY}"
  else
    # curlでダウンロード
    curl -kfsSLo ${HOME}/dotfiles.tar.gz ${DOTFILES_TARBALL}
    tar -zxf ${HOME}/dotfiles.tar.gz --strip-components 1 -C ${DOTFILES_DIRECTORY}
    rm -f ${HOME}/dotfiles.tar.gz
  fi

  echo $(tput setaf 2)Download dotfiles complete!. ✔︎$(tput sgr0)

  return 0
}


################################################################################
#  パッケージインストール

# 必要なパッケージインストール
install_essential_packages() {
  apt install \
    curl \
    make \
    git \
    ;

  return 0
}

# すべてのパッケージインストール
install_all_packages() {

  echo "Install packages..."

  install_essential_packages

  echo "$(tput setaf 2)Installed packages complete!. ✔︎$(tput sgr0)"

  return 0
}


################################################################################
# Deploy処理 (ドットファイルをホームディレクトリに配置&リンク)

deploy() {

  cd ${DOTFILES_DIRECTORY}

  # 実行日時を名前としたバックアップディレクトリを作成
  readonly BACKUP_DIR="${DOTFILES_BACKUP_DIRECTORY}/$(date +%Y%m%d%H%M%S)"
  mkdir -p ${BACKUP_DIR}

  for f in .??*; do

    # 無視したいファイルやディレクトリ
    [[ "${DOTFILES_EXCLUDES[@]}" =~ "${f}" ]] && continue

    # ホームディレクトリに同一のファイルがあればバックアップディレクトリに移動
    if [ ! -L ${HOME}/${f} ]; then
      mv ${HOME}/${f} ${BACKUP_DIR}/
    fi

    # シンボリックリンク作成
    ln -snfv ${DOTFILES_DIRECTORY}/${f} ${HOME}/${f}

  done

  # バックアップディレクトリが空なら削除
  if [ -z "$(ls $BACKUP_DIR)" ]; then
    rm -r $BACKUP_DIR
  else
    echo "backup current dotfiles to ${BACKUP_DIR}"
  fi

  echo $(tput setaf 2)Deploy dotfiles complete!. ✔︎$(tput sgr0)

  return 0
}



################################################################################
# main

main() {

  # Dotfilesがない，あるいは上書きオプションがあればダウンロード
  if [ -n "${OVERWRITE}" ] || [ ! -d ${DOTFILES_DIRECTORY} ]; then
    download_dotfiles
  fi

  # パッケージインストール
  install_all_packages

  # ドットファイルのシンボリックリンク作成
  deploy

 return 0
}


################################################################################
# Entrypoint script

main

exit 0
