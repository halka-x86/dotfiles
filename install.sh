#!/bin/bash
set -e

# readonly DOTFILES_TARBALL="https://github.com/halka-x86/dotfiles/tarball/master"
readonly DOTFILES_TARBALL="https://github.com/halka-x86/dotfiles/tarball/develop"
readonly REMOTE_URL="git@github.com:halka-x86/dotfiles.git"
readonly DOTFILES_DIRECTORY="${HOME}/dotfiles" # ホームディレクトリに展開
readonly SHELL_INITIALIZE="${DOTFILES_DIRECTORY}/initialize.sh"
readonly SHELL_DEPLOY="${DOTFILES_DIRECTORY}/deploy.sh"


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
  if [-n "${USE_GIT}" ] && [ type "git" >/dev/null 2>&1 ]; then
    git clone --recursive "${REMOTE_URL}" "${DOTFILES_DIRECTORY}"
  else
    # curlでダウンロード
    curl -fsSLo --insecure ${HOME}/dotfiles.tar.gz ${DOTFILES_TARBALL}
    tar -zxf ${HOME}/dotfiles.tar.gz --strip-components 1 -C ${DOTFILES_DIRECTORY}
    rm -f ${HOME}/dotfiles.tar.gz
  fi

  echo $(tput setaf 2)Download dotfiles complete!. ✔︎$(tput sgr0)

  return 0
}


################################################################################
# main

main() {

  # Dotfilesがない，あるいは上書きオプションがあればダウンロード
  if [ -n "${OVERWRITE}" ] || [ ! -d ${DOTFILES_DIRECTORY} ]; then
    download_dotfiles
  fi

  # dotfilesダウンロード後に initialize & deploy
  ${SHELL_INITIALIZE};
  ${SHELL_DEPLOY};

 return 0
}


################################################################################
# Entrypoint script

main

exit 0
