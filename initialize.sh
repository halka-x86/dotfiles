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
  -h Print help (this message)
_EOT_

  return 0
}

################################################################################
# オプション解析 (-h:ヘルプ表示)

while getopts ":h" opt
do
  case ${opt} in
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
  sudo apt install \
    curl \
    make \
    git \
    fish \
    ;

  return 0
}

# python関連インストール
install_python_packages() {

  # poetry
  curl -sSL https://install.python-poetry.org | python3 -

  return 0
}

# すべてのパッケージインストール
install_all_packages() {

  echo "Install packages..."

  install_essential_packages
  install_python_packages

  echo "$(tput setaf 2)Installed packages complete!. ✔︎$(tput sgr0)"

  return 0
}


################################################################################
# main

main() {

  # パッケージインストール
  install_all_packages

  return 0
}

################################################################################
# Entrypoint script

main

exit 0
