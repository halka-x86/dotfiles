#!/usr/bin/env bash
set -e

readonly DOTFILES_EXCLUDES=(".git" ".gitignore" ".vscode")                         # 無視したいファイルやディレクトリ
readonly DOTFILES_DIRECTORY="${HOME}/dotfiles"                                     # ホームディレクトリに展開
readonly DOTFILES_BACKUP_DIRECTORY="${HOME}/dotfiles_backup/$(date +%Y%m%d%H%M%S)" # 現行の設定のバックアップ保存先


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
  -d dry-run
_EOT_
}


################################################################################
# オプション解析 (-h:ヘルプ表示  -l:デプロイ対象リスト表示  -d:ドライラン)

while getopts ":ldh" opt
do
  case ${opt} in
    l)  readonly DISPLAY_LIST_DOTFILES=true
        ;;
    d)  readonly DRYRUN=true
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
# .configディレクトリを除くDeploy処理 (ドットファイルをホームディレクトリに配置&リンク)

deploy_excute_config_home() {

  local -r DEPLOY_SOURCE_DIR="${DOTFILES_DIRECTORY}"  # デプロイ元
  local -r DEPLOY_DESTINATION_DIR="${HOME}"           # デプロイ先
  local -r BACKUP_DESTINATION_DIR="${DOTFILES_BACKUP_DIRECTORY}"  # バックアップ先

  # リスト表示がオプション指定されていなければバックアップディレクトリを作成
  if [ "${DISPLAY_LIST_DOTFILES}" != true ]; then
    [ "${DRYRUN}" == true ] && echo "[dry-run]: mkdir backup dir (${BACKUP_DESTINATION_DIR})"
    [ "${DRYRUN}" != true ] && mkdir -p ${BACKUP_DESTINATION_DIR}
  fi

  cd ${DEPLOY_SOURCE_DIR}

  for f in .??*; do

    # 無視したいファイルやディレクトリ
    [[ "${DOTFILES_EXCLUDES[@]}" =~ "${f}" ]] && continue
    [[ "${f}" == ".config" ]] && continue

    # オプションでリスト表示が指定されていたら表示のみ行う
    if [ "${DISPLAY_LIST_DOTFILES}" == true ]; then
      echo "- ${f}"
      continue
    fi

    # 同一のファイル(シンボリックリンクは除く)があればバックアップディレクトリに移動
    if [ -e ${DEPLOY_DESTINATION_DIR}/${f} ] && [ ! -L ${DEPLOY_DESTINATION_DIR}/${f} ]; then
      [ "${DRYRUN}" == true ] && echo "[dry-run]: backup file (${DEPLOY_DESTINATION_DIR}/${f} -> ${BACKUP_DESTINATION_DIR}/)"
      [ "${DRYRUN}" != true ] && mv ${DEPLOY_DESTINATION_DIR}/${f} ${BACKUP_DESTINATION_DIR}/
    fi

    # シンボリックリンク作成
    [ "${DRYRUN}" == true ] && echo "[dry-run]: create a symbolic link (${DEPLOY_DESTINATION_DIR}/${f})" \
                            && echo "           ${DEPLOY_SOURCE_DIR}/${f} -> ${DEPLOY_DESTINATION_DIR}/${f}"
    [ "${DRYRUN}" != true ] && ln -snfv ${DEPLOY_SOURCE_DIR}/${f} ${DEPLOY_DESTINATION_DIR}/${f}

  done

  # 表示のみ行った場合終了
  [ "${DISPLAY_LIST_DOTFILES}" == true ] && return 0

  # バックアップディレクトリが空なら削除
  set +e
  [ "${DRYRUN}" != true ] && [ -d ${BACKUP_DESTINATION_DIR} ] && rmdir -p ${BACKUP_DESTINATION_DIR} > /dev/null 2>&1
  set -e

  return 0
}


################################################################################
# .config ディレクトリ内 Deploy処理 (ドットファイルをホームディレクトリに配置&リンク)

deploy_config_home() {

  local -r DEPLOY_SOURCE_DIR="${DOTFILES_DIRECTORY}/.config" # デプロイ元
  local -r DEPLOY_DESTINATION_DIR="${HOME}/.config"          # デプロイ先
  local -r BACKUP_DESTINATION_DIR="${DOTFILES_BACKUP_DIRECTORY}/.config"  # バックアップ先

  # dotfiles で .config を管理していなければ終了
  [ ! -d ${DEPLOY_SOURCE_DIR} ] && return 0

  # リスト表示がオプション指定されていなければデプロイ先とバックアップディレクトリを作成
  if [ "${DISPLAY_LIST_DOTFILES}" != true ]; then
    [ "${DRYRUN}" == true ] && echo "[dry-run]: mkdir backup dir (${BACKUP_DESTINATION_DIR})"
    [ "${DRYRUN}" == true ] && echo "[dry-run]: mkdir deploy dir (${DEPLOY_DESTINATION_DIR})"
    [ "${DRYRUN}" != true ] && mkdir -p ${BACKUP_DESTINATION_DIR}
    [ "${DRYRUN}" != true ] && mkdir -p ${DEPLOY_DESTINATION_DIR}
  fi

  cd ${DEPLOY_SOURCE_DIR}

  for f in *; do

    # オプションでリスト表示が指定されていたら表示のみ行う
    if [ "${DISPLAY_LIST_DOTFILES}" == true ]; then
      echo "- .config/${f}"
      continue
    fi

    # 同一のファイル(シンボリックリンクは除く)があればバックアップディレクトリに移動
    if [ -e ${DEPLOY_DESTINATION_DIR}/${f} ] && [ ! -L ${DEPLOY_DESTINATION_DIR}/${f} ]; then
      [ "${DRYRUN}" == true ] && echo "[dry-run]: backup file (${DEPLOY_DESTINATION_DIR}/${f} -> ${BACKUP_DESTINATION_DIR}/)"
      [ "${DRYRUN}" != true ] && mv ${DEPLOY_DESTINATION_DIR}/${f} ${BACKUP_DESTINATION_DIR}/
    fi

    # シンボリックリンク作成
    [ "${DRYRUN}" == true ] && echo "[dry-run]: create a symbolic link (${DEPLOY_DESTINATION_DIR}/${f})" \
                            && echo "           ${DEPLOY_SOURCE_DIR}/${f} -> ${DEPLOY_DESTINATION_DIR}/${f}"
    [ "${DRYRUN}" != true ] && ln -snfv ${DEPLOY_SOURCE_DIR}/${f} ${DEPLOY_DESTINATION_DIR}/${f}

  done

  # 表示のみ行った場合終了
  [ "${DISPLAY_LIST_DOTFILES}" == true ] && return 0

  # バックアップディレクトリが空なら削除
  set +e
  [ "${DRYRUN}" != true ] && rmdir -p ${BACKUP_DESTINATION_DIR} > /dev/null 2>&1
  set -e

  return 0
}


################################################################################
# home に gitユーザファイル(gitconfig.local)を作成

create_gitconfig_local() {

  local -r GIT_CONFIG_LOCAL="${HOME}/.gitconfig.local"

  # .gitconfig.local ファイルが存在する場合は作成不要
  [ -e ${GIT_CONFIG_LOCAL} ] && return 0

  # オプションでリスト表示が指定されていたら表示のみ行う
  if [ "${DISPLAY_LIST_DOTFILES}" == true ]; then
    echo "- .gitconfig.local"
    return 0
  fi

  # dyr-run オプション指定
  if [ "${DRYRUN}" == true  ]; then
    echo "[dry-run]: local gitconfig (${GIT_CONFIG_LOCAL})"
    return 0
  fi

  # 対話式にコンフィグ内容を入力
  echo -n "git config user.email?> "
  read GIT_AUTHOR_EMAIL
  echo -n "git config user.name?> "
  read GIT_AUTHOR_NAME

  # cat のリダイレクトにてファイルを作成
  cat << EOF > ${GIT_CONFIG_LOCAL}
[user]
  name = $GIT_AUTHOR_NAME
  email = $GIT_AUTHOR_EMAIL
EOF
}


################################################################################
# main構文
main() {

  deploy_excute_config_home
  deploy_config_home
  create_gitconfig_local

  [ "${DISPLAY_LIST_DOTFILES}" == true ] && return 0

  [ -a ${DOTFILES_BACKUP_DIRECTORY} ] && echo "backup current dotfiles to ${DOTFILES_BACKUP_DIRECTORY}"

  echo $(tput setaf 2)Deploy dotfiles complete!. ✔︎$(tput sgr0)

  return 0
}


################################################################################
# Entrypoint script

main

exit 0
