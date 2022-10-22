# Fish git prompt
set __fish_git_prompt_showdirtystate 'yes'
set __fish_git_prompt_showstashstate 'yes'
set __fish_git_prompt_showuntrackedfiles 'yes'
set __fish_git_prompt_showupstream 'yes'
set __fish_git_prompt_color_branch yellow
set __fish_git_prompt_color_upstream_ahead green
set __fish_git_prompt_color_upstream_behind red

# prompt
function fish_prompt

    # ssh
    test $SSH_TTY
    and printf (set_color red)$USER(set_color brwhite)'@'(set_color yellow)(prompt_hostname)' '

    # Current directory
    printf (set_color cyan)(prompt_pwd)(set_color normal)

    # Git
    set last_status $status
    printf '%s ' (__fish_git_prompt)

    switch $USER
    case root
        printf (set_color red)"#"
    case '*'
        printf (set_color normal)">"
    end

    set_color normal
end

# 右prompt
function fish_right_prompt
    date +"%Y/%m/%d %H:%M"
end

# abbr

abbr -a upd  "sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y"

## git
abbr -a g    git
abbr -a gs   git status
abbr -a gss  git status -s
abbr -a gb   git branch
abbr -a gba  git branch -a
abbr -a gbr  git branch -r
abbr -a gco  git checkout
abbr -a gcob git checkout -b
abbr -a ga   git add
abbr -a gau  git add --update
abbr -a gaa  git add --all
abbr -a gcm  git commit
abbr -a gcmm git commit -m
abbr -a gcma git commit --amend
abbr -a gf   git fetch
abbr -a gfp  git fetch --prune
abbr -a gp   git push
abbr -a gpo  git push origin
abbr -a gl   git log
abbr -a glo  git log --oneline
abbr -a ggr  git log --graph --date=short --pretty=format:\'%Cgreen%h %cd %Cblue%cn %Creset%s\'
abbr -a gr   git reset HEAD
abbr -a gr1  git reset HEAD~
abbr -a gr2  git reset HEAD~~
abbr -a gr3  git reset HEAD~~
abbr -a grs  git reset --soft HEAD
abbr -a grs1 git reset --soft HEAD~
abbr -a grs2 git reset --soft HEAD~~
abbr -a grs3 git reset --soft HEAD~~~
abbr -a gd   git diff
abbr -a gd1  git diff HEAD~
abbr -a gd2  git diff HEAD~~
abbr -a gd3  git diff HEAD~~~
abbr -a gg git grep
