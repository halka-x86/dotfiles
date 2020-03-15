#!/bin/bash
set -e

readonly DOTFILES_EXCLUDES=(".git" ".gitignore") # 無視したいファイルやディレクトリ
readonly DOTFILES_DIRECTORY="${HOME}/dotfiles"
readonly DOTFILES_TARBALL="https://github.com/halka-x86/dotfiles/tarball/master"
readonly REMOTE_URL="git@github.com:halka-x86/dotfiles.git"
readonly CONFIG_DIR=".config"

function usage() {
  name=$(basename $0)
  cat <<_EOT_
Usage:
  $name [Options] [Command]
Commands:
  deploy
  initialize
Options:
  -f $(tput setaf 1)** warning **$(tput sgr0) Overwrite dotfiles.
  -h Print help (this message)

_EOT_
  exit 1
}

# オプション解析 (-f:上書き -h:ヘルプ表示)
while getopts ":fh" opt; do
  case ${opt} in
  f) readonly OVERWRITE=true ;;
  h) usage ;;
  esac
done
shift $((OPTIND - 1))

# 引数がなければヘルプ
[ $# -lt 1 ] && usage

# Dotfilesがない、あるいは上書きオプションがあればダウンロード
if [ -n "${OVERWRITE}" -o ! -d ${DOTFILES_DIRECTORY} ]; then
  echo "Downloading dotfiles..."
  rm -rf ${DOTFILES_DIRECTORY}
  mkdir ${DOTFILES_DIRECTORY}

  if type "git" >/dev/null 2>&1; then
    git clone --recursive "${REMOTE_URL}" "${DOTFILES_DIRECTORY}"
  else
    curl -fsSLo ${HOME}/dotfiles.tar.gz ${DOTFILES_TARBALL}
    tar -zxf ${HOME}/dotfiles.tar.gz --strip-components 1 -C ${DOTFILES_DIRECTORY}
    rm -f ${HOME}/dotfiles.tar.gz
  fi

  echo $(tput setaf 2)Download dotfiles complete!. ✔︎$(tput sgr0)
fi

# Deploy処理
deploy() {

  cd ${DOTFILES_DIRECTORY}

  for f in .??*; do

    # 無視したいファイルやディレクトリ
    [[ "${DOTFILES_EXCLUDES[@]}" =~ "${f}" ]] && continue

    # .config 内のファイル処理
    if [ ${f} = ${CONFIG_DIR} ]; then
      while read -d $'\0' file; do
        mkdir -p ${HOME}/$(dirname ${file})
        ln -snfv ${DOTFILES_DIRECTORY}/${file} ${HOME}/${file}
      done < <(find ${CONFIG_DIR} -type f -print0)
      continue
    fi

    # シンボリックリンク作成
    ln -snfv ${DOTFILES_DIRECTORY}/${f} ${HOME}/${f}

  done

  echo $(tput setaf 2)Deploy dotfiles complete!. ✔︎$(tput sgr0)
}

# Initialize処理
initialize() {
  :
}

# 引数取得
command=$1
[ $# -gt 0 ] && shift

# 引数で場合分け
case $command in
deploy) deploy ;;
init*) initialize ;;
*) usage ;;
esac

exit 0
