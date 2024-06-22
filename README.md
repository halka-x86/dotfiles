# halka-x86's dotfiles

Deploy and Initialize for Linux(Ubuntu) and WSL(Ubuntu).

## 用語

- initialize
  必要なパッケージのインストール(初回時のみ実行)．
- deploy
  コンフィグファイルのシンボリックファイルを配置

## 構成

dotfilesはホームディレクトリに配置される想定．

```txt
~/
├─ dotfiles/
│  ├ install.sh
│
├─ dotfiles_backup/   現行設定バックアップディレクトリ(デプロイにて作成)
│  ├ YYYYMMDDHHMMSS/ バックアップ日時毎にディレクトリ作成
│
```

## Usage

### Insall

- Githubから直接ダウンロードして実行．
  スクリプト内で`git`もしくは`curl`にてダウンロード．
  ホームディレクトリ直下に`~/dotfiles/`が作成．

```bash
bash -c "$(curl -L raw.githubusercontent.com/halka-x86/dotfiles/master/install.sh)"
```

- git にてダウンロードして実行

```bash
cd ~
git clone https://github.com/halka-x86/dotfiles.git
cd dotfiles/
./install.sh
```

### Option

- `install.sh`

```txt
[-h] : help
[-f] : ローカルに既存のdotfilesがある場合に上書き
[-g] : gitを使用してダウンロード(デフォルトはcurl使用)
```
