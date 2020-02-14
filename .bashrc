# 日本語対応
export LANG='ja_JP.UTF-8'

# ls 結果の色設定 + ls系のエイリアス
export LS_OPTIONS='--color=auto'
alias ls='ls $LS_OPTIONS'
alias ll='ls $LS_OPTIONS -l'
alias la='ls $LS_OPTIONS -a'
alias l='ls $LS_OPTIONS -lA'

# 実行前確認系エイリアス
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# grep 結果の色設定
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# gitスクリプト読み込み
if [ -f ~/.git-completion.bash ]; then
    source ~/.git-completion.bash
fi
if [ -f ~/.git-prompt.sh ]; then
    source ~/.git-prompt.sh
fi

# プロンプトに各種情報を表示
GIT_PS1_SHOWDIRTYSTATE=true
GIT_PS1_SHOWSTASHSTATE=true
GIT_PS1_SHOWUNTRACKEDFILES=true
GIT_PS1_SHOWUPSTREAM="auto"
GIT_PS1_SHOWCOLORHINTS=true

# プロンプト設定
if type "__git_ps1" > /dev/null 2>&1; then
    export PS1='\[\033[32m\]\u\[\033[00m\]:\[\033[34m\]\w\[\033[36m\]$(__git_ps1)\[\033[00m\] $ '
else
    export PS1='\[\033[32m\]\u\[\033[00m\]:\[\033[34m\]\w\[\033[36m\]\[\033[00m\] $ '
fi

# fish を起動
exec fish
