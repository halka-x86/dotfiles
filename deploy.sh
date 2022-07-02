#!/usr/bin/env bash
set -e

readonly DOTFILES_EXCLUDES=(".git" ".gitignore")             # 無視したいファイルやディレクトリ
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
  -h Print help (this message)
_EOT_
}

################################################################################
# 現行のファイルをバックアップ

backup_current_dotfiles() {

  # 実行日時をバックアップディレクトリ名とする
  readonly BACKUP_DIR="${DOTFILES_BACKUP_DIRECTORY}/$(date +%Y%m%d%H%M%S)"
  mkdir -p ${BACKUP_DIR}

  for f in .??*; do

    # 無視したいファイルやディレクトリはスキップ
    [[ "${DOTFILES_EXCLUDES[@]}" =~ "${f}" ]] && continue

    # ホームディレクトリに同一のファイルがあればバックアップディレクトリにコピー
    if [ ! -L ${HOME}/${f} ]; then
      cp -rp ${HOME}/${f} ${BACKUP_DIR}/.
    fi

  done

  # バックアップディレクトリが空なら削除
  if [ -z "$(ls $BACKUP_DIR)" ]; then
    rm -r $BACKUP_DIR
  else
    echo "backup current dotfiles to ${BACKUP_DIR}"
  fi

  return 0
}

################################################################################
# Deploy処理 (ドットファイルをホームディレクトリに配置&リンク)

deploy() {

  cd ${DOTFILES_DIRECTORY}

  for f in .??*; do

    # 無視したいファイルやディレクトリ
    [[ "${DOTFILES_EXCLUDES[@]}" =~ "${f}" ]] && continue

    # ホームディレクトリに同一のファイルがあればバックアップディレクトリに移動
    if [ ! -L ${HOME}/${f} ]; then
      mv ${HOME}/${f} ${BACKUP_DIR}/
    fi
    rm -fr ${HOME}/${f}

    # シンボリックリンク作成
    ln -snfv ${DOTFILES_DIRECTORY}/${f} ${HOME}/${f}

  done

  echo $(tput setaf 2)Deploy dotfiles complete!. ✔︎$(tput sgr0)

  return 0
}

################################################################################
# main構文
main() {

  # オプション解析 (-h:ヘルプ表示)
  while getopts ":h" opt; do
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

  backup_current_dotfiles # 現行設定バックアップ
  deploy                  # デプロイ

  return 0
}

################################################################################
# Entrypoint script

main

exit 0
