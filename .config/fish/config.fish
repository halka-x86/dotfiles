# Fish git prompt
set __fish_git_prompt_showdirtystate 'yes'
set __fish_git_prompt_showstashstate 'yes'
set __fish_git_prompt_showuntrackedfiles 'yes'
set __fish_git_prompt_showupstream 'yes'
set __fish_git_prompt_color_branch yellow
set __fish_git_prompt_color_upstream_ahead green
set __fish_git_prompt_color_upstream_behind red

# Status Chars
set __fish_git_prompt_char_dirtystate '⚡'
set __fish_git_prompt_char_stagedstate '→'
set __fish_git_prompt_char_untrackedfiles '☡'
set __fish_git_prompt_char_stashstate '↩'
set __fish_git_prompt_char_upstream_ahead '+'
set __fish_git_prompt_char_upstream_behind '-'

# prompt
function fish_prompt

    test $SSH_TTY
    and printf (set_color red)$USER(set_color brwhite)'@'(set_color yellow)(prompt_hostname)' '

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
