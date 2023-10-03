# halka-x86's dotfiles

Deploy and Initialize for Linux(Ubuntu) and WSL(Ubuntu).

## 用語

- initialize
  必要なパッケージのインストール(初回時のみ実行)．
  `initialize.sh`に対応．
- deploy
  コンフィグファイルのシンボリックファイルを配置
  `deploy.sh`に対応．

## 構成

dotfilesはホームディレクトリに配置される想定．

```txt
~/
├─ dotfiles/
│  ├ install.sh
│  ├ initialize.sh
│  ├ deploy.sh
│
├─ dotfiles_backup/    ...現行設定バックアップディレクトリ(デプロイにて作成)
    ├ YYYYMMDDHHMMSS/    ...バックアップ日時毎にディレクトリ作成

```

## Usage

### Insall

#### Githubから直接ダウンロードして実行．

スクリプト内で`git`もしくは`curl`にてダウンロード．  
ホームディレクトリ直下に`~/dotfiles/`が作成．

```bash:bash
sudo -E bash -c "$(curl -sfSL raw.githubusercontent.com/halka-x86/dotfiles/master/install.sh)"
```

```bash:fish
bash -c 'sudo -E bash -c "$(curl -sfSL raw.githubusercontent.com/halka-x86/dotfiles/master/install.sh)"'
```

#### git にてダウンロードして実行

```bash
cd ~
git clone https://github.com/halka-x86/dotfiles.git
cd dotfiles/
./install.sh
```

## Script

- `install.sh`    ... dotfilesのダウンロードから initialize, deploy まで一貫して実行
- `initialize.sh` ... パッケージのインストールを実行
- `deploy.sh`     ... dotfiles のシンボリックリンクを作成



### `install.sh`

dotfiles のダンロードからデプロイまで全てを行う．  
dotfiles を GitHub からダウンロード後，他のスクリプト `initialize.sh`および `deploy.sh`を実行する．

```txt:Option
[-h] : ヘルプ表示
[-f] : ローカルに既存のdotfilesがある場合に上書き
[-b] : fish のインストールを行わない
[-g] : gitを使用してダウンロード(デフォルトはcurl使用)
```


### `initialize.sh`

ソフトウェアのインストールを実行．  

```txt:Option
[-b] : fish のインストールを行わない
[-h] : ヘルプ表示
```


### `deploy.sh`

dotfiles のシンボリックリンクを作成．  
既にコンフィグファイルがある場合には `~/dotfiles_backup/` 下にバックアップされる．

```txt:Option
[-h] : ヘルプ表示
[-l] : 展開するdotfilesファイル群をリスト表示
[-d] : dyr-run
```
