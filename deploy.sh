#!/usr/bin/env bash
set -e

readonly DOTFILES_EXCLUDES=(".git" ".gitignore" ".vscode")             # 無視したいファイルやディレクトリ
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
  -l Display list dotfiles
_EOT_
}


################################################################################
# オプション解析 (-h:ヘルプ表示  -l:デプロイ対象リスト表示)

while getopts ":lh" opt
do
  case ${opt} in
    l)  readonly DISPLAY_LIST_DOTFILES=true
        ;;
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
# Deploy処理 (ドットファイルをホームディレクトリに配置&リンク)

deploy() {

  cd ${DOTFILES_DIRECTORY}

  # 実行日時を名前としたバックアップディレクトリを作成
  readonly BACKUP_DIR="${DOTFILES_BACKUP_DIRECTORY}/$(date +%Y%m%d%H%M%S)"
  mkdir -p ${BACKUP_DIR}

  for f in .??*; do

    # 無視したいファイルやディレクトリ
    [[ "${DOTFILES_EXCLUDES[@]}" =~ "${f}" ]] && continue

    # オプションでリスト表示が指定されていたら表示のみ行う
    if [ "${DISPLAY_LIST_DOTFILES}" == true ]; then
      echo "- ${f}"
      continue
    fi

    # ホームディレクトリに同一のファイルがあればバックアップディレクトリに移動
    if [ ! -L ${HOME}/${f} ]; then
      mv ${HOME}/${f} ${BACKUP_DIR}/
    fi

    # シンボリックリンク作成
    ln -snfv ${DOTFILES_DIRECTORY}/${f} ${HOME}/${f}

  done

  # 表示のみ行った場合終了
  if [ "${DISPLAY_LIST_DOTFILES}" == true ]; then
    exit 0
  fi

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
# main構文
main() {

  deploy

  return 0
}


################################################################################
# Entrypoint script

main

exit 0
