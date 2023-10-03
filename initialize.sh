#!/usr/bin/env bash
set -e

################################################################################
# Usage

function usage() {
  name=$(basename $0)
  cat <<_EOT_
Usage:
  $name [Options]
Options:
  -b install without fish
  -h Print help (this message)
_EOT_

  return 0
}

################################################################################
# オプション解析 (-h:ヘルプ表示)

while getopts ":bh" opt
do
  case ${opt} in
    b)  readonly WITHOUT_FISH=true ;;
    h)  usage;
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
#  パッケージインストール

# 必要なパッケージインストール
install_essential_packages() {

  # install packages
  apt install \
    make \
    git \
    ;

  return 0
}

# fishインストール
install_fish_packages() {

  # add repository
  apt-add-repository ppa:fish-shell/release-3

  # install packages
  apt install fish;

  return 0
}


################################################################################
# main

main() {

  echo "Install packages..."

  install_essential_packages

  if [ -z "${WITHOUT_FISH}" ]; then
    install_fish_packages
  fi

  echo "$(tput setaf 2)Installed packages complete!. ✔︎$(tput sgr0)"

  return 0
}

################################################################################
# Entrypoint script

main

exit 0
