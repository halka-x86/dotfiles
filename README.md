# halka-x86's dotfiles

Linux(Ubuntu) / WSL(Ubuntu) 向けの dotfiles。
必要パッケージのインストールから、設定ファイルのシンボリックリンク配置までを行う。

## 構成

```txt
~/
├─ dotfiles/                    ...リポジトリルート
│  ├ install.sh                 ...インストール & デプロイ
│  ├ revert.sh                  ...シンボリックリンクの復元(restore / uninstall)
│  ├ dotfiles/                  ...デプロイ対象ファイル群
│  │  ├ .bashrc
│  │  ├ .git-completion.bash
│  │  ├ .git-prompt.sh
│  │  ├ .gitconfig
│  │  ├ .config/fish/
│  │  ├ .claude/CLAUDE.md
│  │  └ .codex/
│  │     ├ AGENTS.md
│  │     └ skills/
│
├─ dotfiles_backup/             ...現行設定バックアップ(デプロイ時に作成)
   ├ YYYYMMDDHHMMSS/            ...実行日時毎にディレクトリ作成
```

`dotfiles/dotfiles/` 配下のファイル・ディレクトリが、ファイル単位でホームディレクトリにシンボリックリンクされる。

## Usage

### Install

#### GitHubから直接ダウンロードして実行

スクリプト内で `git` もしくは `curl` にてダウンロードし、ホームディレクトリ直下に `~/dotfiles/` を作成する。

```bash
sudo -E bash -c "$(curl -sfSL raw.githubusercontent.com/halka-x86/dotfiles/master/install.sh)"
```

#### git にてダウンロードして実行

```bash
cd ~
git clone https://github.com/halka-x86/dotfiles.git
cd dotfiles/
./install.sh
```

## Script

- `install.sh` ... 必要パッケージのインストールから dotfiles のデプロイまでを一貫して実行
- `revert.sh`  ... シンボリックリンクを復元するサブコマンド群(`restore` / `uninstall`)

### `install.sh`

必要なパッケージのインストールと、dotfiles のシンボリックリンク配置を行う。
既に配置済みのファイルがある場合は `~/dotfiles_backup/` 下にバックアップしてから上書きする。

```txt:Option
[-f] : ローカルに既存のdotfilesがある場合、削除して再ダウンロード
[-d] : デプロイのみ実行(パッケージインストールをスキップ)
[-n] : ドライラン(実際の変更を行わない)
[-g] : ダウンロードに git を使用する(デフォルトは curl)
[-b] : fish のインストールを行わない
[-h] : ヘルプ表示
```

### `revert.sh`

`install.sh` で配置したシンボリックリンクを元に戻す。用途に応じて2つのサブコマンドを持つ。

```bash
./revert.sh restore   [-n] [-h]
./revert.sh uninstall [-n] [-h]
```

- `restore`
  `~/.config` `~/.claude` `~/.codex` のシンボリックリンクを解除し、実ディレクトリとして復元する。
  復元後、`dotfiles/dotfiles/` 配下の該当ディレクトリは管理対象として指定したファイルのみに整理される。
- `uninstall`
  `dotfiles/dotfiles/` を指すシンボリックリンクを、実ファイルへ置き換える(dotfiles配下の全ファイルが対象)。

```txt:Option (各サブコマンド共通)
[-n] : ドライラン(実際の変更を行わない)
[-h] : ヘルプ表示
```
