#!/bin/bash

# If not running interactively, don't do anything
case $- in
        *i*) ;;
            *) return;;
esac

DEFAULT_STOP_WATCH="~~~${USER}~~~"

# export BASH_GLOBAL_TIMING=true


declare -A stopwatch
function startStopwatch()
{
    local name=${1:-${DEFAULT_STOP_WATCH}}
    stopwatch[$name]=$(date +%s%3N)
}

function checkStopwatch()
{
    local name=${1:-${DEFAULT_STOP_WATCH}}
    if [[ ! "${stopwatch[$name]}" ]]
    then
        echo "No stopwatch named $name"
        return 1
    fi
    local message="$(($(date +%s%3N)-stopwatch[$name]))ms elapsed"
    if [[ "$name" != "${DEFAULT_STOP_WATCH}" ]]
    then
        message+=" on '${name}'"
    fi
    [[ ! -z $2 ]] && message+=" -- $2"
    echo $message
}

function deleteStopwatch()
{
    local name=${1:-${DEFAULT_STOP_WATCH}}
    unset stopwatch[$name]
}

function resetStopwatch()
{
    checkStopwatch "$1" "$2"
    startStopwatch "$1"
}



[[ ! -z $BASH_GLOBAL_TIMING ]] && startStopwatch 'bash.global'


# Check to see that the directory exists and isn't already in the path
function addToPath()
{
    if [[ -d "$1" && ":$PATH:" != *":$1:"*    ]]
    then
        PATH="$PATH:$1"
    fi
}

# Don't put duplicate lines in the history. See bash(1) for more options
# Don't store history for commands that are preceded with a space
export HISTCONTROL=ignoredups:ignorespace

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
export HISTSIZE=5000
export HISTFILESIZE=10000

export HISTTIMEFORMAT="%F %T "
PROMPT_COMMAND="history -a;$PROMPT_COMMAND"

GLOBIGNORE=".:.."



if [[ "$SHELL" != *"/ash" ]]; then
    # These don't work on busybox shells
    
    # check the window size after each command and, if necessary,
    # update the values of LINES and COLUMNS.
    shopt -s checkwinsize

    # Make bash append rather than overwrite the history on disk
    shopt -s histappend


    # Use case-insensitive filename globbing
    shopt -s nocaseglob

    # If set, the pattern "**" used in a pathname expansion context will
    # match all files and zero or more directories and subdirectories.
    #shopt -s globstar
fi


# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"


[[ ! -z $BASH_GLOBAL_TIMING ]] && checkStopwatch 'bash.global' 'Before aliases'
# alias srm='rm -P'
alias md='mkdir -p'
alias mkdir='mkdir -p'
alias rd='rmdir'

alias mv='mv -i'
alias cp='cp -i'

alias dfh='df -h'
alias psef='ps -ef'
alias lsof='lsof -n -P'

alias ip='ip -color=auto'
alias diff='diff --color=auto'
export LESS='-R --use-color -Dd+r$Du+b'
export MANPAGER="less -R --use-color -Dd+r -Du+b"
export EDITOR=vi

#This follows symlinks, but I'm afraid that I'll use -delete without thinking
#alias find='find -L'
alias tail='tail --lines=20'
alias head='head --lines=20'
alias grep='grep -P --color=auto'
alias grpe='grep'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias pcre2grep='pcre2grep --color=auto'
alias sed='sed -E'
alias bzip=bzip2
alias cd..='cd ..'

# alias la='ls -AFpG --color=auto'
# alias l='ls -CFpG --color=auto'

alias ls='ls --group-directories-first -AFp --color=auto'
alias ll='ls --group-directories-first --time-style=long-iso -alFp --color=auto'
alias lh='ls --group-directories-first --time-style=long-iso -lhFApr --color=auto --sort=size'
alias lls='ll -r --sort=size'
alias lss=lls
alias lld='ll -tr'
alias lsd=lld

alias aria2c='aria2c -x5'
alias aria='aria2c -x5'

# alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

[[ ! -z $BASH_GLOBAL_TIMING ]] && checkStopwatch 'bash.global' 'after aliases'

function cd()
{
    if [[ "$1" = "..." ]]
    then
        builtin cd ../..
    elif [[ "$1" = "...." ]]
    then
        builtin cd ../../..
    elif [[ "$1" = "....." ]]
    then
        builtin cd ../../../..
    elif [[ "$1" = "......" ]]
    then
        builtin cd ../../../../..
    else
       builtin cd "$@"
    fi
}
    

# It's annoying that du doesn't append a / to directory names from a glob. I looked into 
# running it against each file, but it takes almost 0.3 seconds per invocation.
function duh()
{
    # If no arguments were passed
    if (( $# == 0 ))
    then
        # If there are any files or subdirectories in the current directory, list the size for each
        # From https://stackoverflow.com/a/17902999/1148844
        files=$(shopt -s nullglob dotglob; echo ./*)
        if (( ${#files} ))
        then
            du -hs * |sort -h
        else
            echo "The current directory is empty"
        fi
    else
        du -hs "$@" |sort -h
    fi
}


function duc()
{
    # If no arguments were passed
    if (( $# == 0 ))
    then
        # If there are any files or subdirectories in the current directory, list the count for each
        # From https://stackoverflow.com/a/17902999/1148844
        files=$(shopt -s nullglob dotglob; echo ./*)
        if (( ${#files} ))
        then
            du --inodes -s * |sort -n
        else
            echo "The current directory is empty"
        fi
    else
        du --inodes -s "$@" |sort -n
    fi
}


[[ ! -z $BASH_GLOBAL_TIMING ]] && checkStopwatch 'bash.global' 'Before OS-specific commands'


if [[ "$OSTYPE" == "darwin"* ]]
then
    
    # Load nvm script when it's called for the first time
    function nvm()
    {
        if [[ -z $NVM_DIR && -d ${HOME}/.nvm ]]
        then
            unset -f nvm
            export NVM_DIR=${HOME}/.nvm
            source /usr/local/opt/nvm/nvm.sh
        fi
        nvm "$@"
    }    

    # Load sdk script when it's called for the first time
    function sdk()
    {
        if [[ -z $SDKMAN_CANDIDATES_API && -d "${HOME}/.sdkman/" ]]
        then
            unset -f sdk
            source "${HOME}/.sdkman/bin/sdkman-init.sh"  
        fi
        sdk "$@"
    }


    # adds 50-70 ms
    # test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"


    # export BASH_COMPLETION_LOG=/tmp/bash-completion.log
    # export BASH_COMPLETION_DEBUG=true
    # export BASH_COMPLETION_TRACE=true
    # export BASH_COMPLETION_TIMING=true
    
    # Printf is much faster than ? (I had 'rm' here, but that clearly isn't right) because it's a built-in
    [[ ! -z $BASH_COMPLETION_LOG ]] && printf '' > $BASH_COMPLETION_LOG
    

    # https://docs.brew.sh/Shell-Completion
    # Files in /usr/local/Cellar/bash-completion@2/2.11/share/bash-completion/completions are loaded 
    # dynamically, so they don't add latency to this script. Files in /usr/local/etc/bash_completion.d/ 
    # are loaded when the bash_completion script is run below, so they do ad latency.
    [[ ! -z $BASH_GLOBAL_TIMING ]] && checkStopwatch bash.global "Before MacOS completion"
    . /usr/local/share/bash-completion/bash_completion
    [[ ! -z $BASH_GLOBAL_TIMING ]] && checkStopwatch bash.global "After MacOs completion"


    # This is commented out because it's being called from /usr/local/share/bash-completion/bash_completion
    # There have been problems where it wasn't, so I'm keeping it here for now
    # for completion_file in /usr/local/etc/bash_completion.d/*
    # do
    #     [[ ! -z $BASH_COMPLETION_LOG ]] && echo bash.global - $completion_file >> $BASH_COMPLETION_LOG
    #     [[ -f "${completion_file}" -a -r "${completion_file}" ]] && source "${completion_file}"
    # done

    export HOMEBREW_NO_GITHUB_API=1
    export CPPFLAGS="-I/usr/local/opt/openjdk/include"
    addToPath "/Users/david/Library/Python/3.9/bin"
    addToPath "/usr/local/go/bin"
    addToPath "/usr/local/opt/erlang@24/bin"
    alias brew-no-update="HOMEBREW_NO_AUTO_UPDATE=1 brew"


elif [[ "$OSTYPE" == "cygwin" ]]; then
    PLATFORM="-cygwin"
    [[ ! -z $BASH_GLOBAL_TIMING ]] && startStopwatch 'cygwin specific'
    . /etc/profile
    [[ ! -z $BASH_GLOBAL_TIMING ]] && checkStopwatch 'cygwin specific' "profile complete"

    # These are added to replace slow scripts in /etc/profile.d
    addToPath "/usr/lib/lapack" # from lapack0.sh; lapath is used by numpy, but the profile script uses grep, which is sloooow
    #test -z "$TZ" && export TZ=$(/usr/bin/tzset) 
    export TZ='America/Denver' # from tz.sh
    [[ -e /usr/bin/vim ]] && alias vi=vim # from vim.sh
    test -z "${_LC_ALL_SET_:-${LC_CTYPE:-$LANG}}" && export LANG='en_US.UTF-8' # from lang.sh
    
    [[ ! -z $BASH_GLOBAL_TIMING ]] && checkStopwatch 'cygwin specific' "cygwin complete"

    function wdu()
    {
        # If no arguments were passed
        if (( $# == 0 ))
        then
            $HOME/AppData/Local/Microsoft/WindowsApps/du -l 1 | sort -n
        else
            $HOME/AppData/Local/Microsoft/WindowsApps/du "$@" | sort -n
        fi
    }

# elif [[ "$OSTYPE" == "msys" ]]; then
    # Lightweight shell and GNU utilities compiled for Windows (part of MinGW)

elif [[ "$OSTYPE" == "linux-gnu"* ]]
then

    # Load node/nvm/npm when one is called for the first time. This allows us to 
    # only load nvm into if it's being used. I think I did this because nvm
    # bash completion is a little slow.
    function init_nvm()
    {
        # Always unset the functions. If nvn isn't installed, we still don't want them around anymore
        unalias nvm
        unalias npm
        unalias node
        if [[ -z $NVM_DIR && -d ${HOME}/.nvm ]]
        then
            export NVM_DIR=${HOME}/.nvm
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
            [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
        fi
        $1 "$@"
    }

    alias nvm='init_nvm nvm'
    alias npm='init_nvm npm'
    alias node='init_nvm node'


    if [[ ! -z "${WSL_DISTRO_NAME}" ]]
    then
        PLATFORM="-wsl"

        # If this is a login shell on WSL, fix the screen dir
        shopt -q login_shell && export SCREENDIR=${HOME}/.screen
    fi

    # # set variable identifying the chroot you work in (used in the prompt below)
    # if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    #         debian_chroot=$(cat /etc/debian_chroot)
    # fi

    # # If this is an xterm, set the title to user@host:dir
    # case "$TERM" in
    # xterm*|rxvt*)
    #         PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    #         ;;
    # *)
    #         ;;
    # esac

    # I'm using sudo -sE instead, but keeping this for a while
    # if [ "$EUID" -eq 0 ]; then
    #     if [ -f /usr/share/bash-completion/bash_completion ]; then
    #         . /usr/share/bash-completion/bash_completion
    #     elif [ -f /etc/bash_completion ]; then
    #         . /etc/bash_completion
    #     fi
    # fi
else
    echo "Unknown operating system: $OSTYPE"
    PLATFORM="-unknown"
fi

# bash completion locations
# Ubuntu: 
#     /etc/bash_completion.d/
#     /usr/share/bash-completion
#     /usr/local/share/bash-completion
# Cygwin: 
#     /usr/share/bash-completion
#     /etc/bash_completion.d/
# MacOS:
#     /usr/local/Cellar/bash-completion
#     /usr/local/share/bash-completion
#     /usr/local/etc/bash_completion.d

[[ ! -z $BASH_GLOBAL_TIMING ]] && checkStopwatch bash.global "After OS-specific commands"





# These only need to happen in login shells because they will be carried over
# Cygwin shells are not login shells unless they are called with --login, but
# it doesn't matter because they won't be carried over.
if shopt -q login_shell || [[ "$OSTYPE" == "cygwin" ]]
then
    export LS_COLORS='rs=0:di=01;34:ln=01;35:mh=00:pi=36;40:so=36;40:do=36;40:bd=36;40:cd=36;40:or=40;31;01:mi=00:su=37;41:sg=37;41:ca=30;41:tw=30;42:ow=01;34:st=37;44:ex=01;32:'
    # Running dircolors every time a shell starts is sloooooow. 
    # if [[ -x /usr/bin/dircolors ]] || [[ -x /usr/local/opt/coreutils/libexec/gnubin/dircolors ]] ; then
    #         test -r ${HOME}/.dircolors && eval "$(dircolors -b ${HOME}/.dircolors)" || eval "$(dircolors -b)"
    # fi

    # colored GCC warnings and errors
    export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

    addToPath "${HOME}/bin"
    addToPath "${HOME}/go/bin"
    addToPath "${HOME}/.cargo/bin"
    addToPath "${HOME}/.local/bin"

    if [[ -d "${HOME}/perl5" ]]
    then
        addToPath "${HOME}/perl5/bin"
        PERL5LIB="${HOME}/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"; export PERL5LIB;
        PERL_LOCAL_LIB_ROOT="${HOME}/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"; export PERL_LOCAL_LIB_ROOT;
        PERL_MB_OPT="--install_base \"${HOME}/perl5\""; export PERL_MB_OPT;
        PERL_MM_OPT="INSTALL_BASE=${HOME}/perl5"; export PERL_MM_OPT;
    fi

    if [[ -d /usr/lib/ccache ]]; then
        addToPath "/usr/lib/ccache"
        export CCACHE_NLEVELS=3
    fi
    
    export PATH
fi


[[ ! -z $BASH_GLOBAL_TIMING ]] && checkStopwatch bash.global "After login shell"

# I'm guessing it's possible to point completion at a function that will load so it's entirely invisible
function deferCompletionLoad()
{
    local completion_file=$1

    if [[ -e "$completion_file" ]]
    then
        for command_name in "$@"
        do
            eval "
                function $command_name() 
                { 
                    . \"$completion_file\" 
                    unset -f $command_name
                    $command_name \"\$@\"
                }
                "
        done
    fi
}


function newDeferCompletionLoad()
{
    local completion_file=$1
    local completion_function=$2

    shift
    shift

    if [[ -e "$completion_file" ]]
    then
        for command_name in "$@"
        do
            eval "
                function __deferred__$command_name() 
                { 
                    . \"$completion_file\" 
                    unset -f __deferred__$command_name
                    $completion_function
                }
                "
            complete -F __deferred__$command_name -o default $command_name
        done
    fi
}



if [[ -d "${HOME}/bash-completion/" ]]
then
    # completion will not work without extglob set and it is normally only set for login shells
    # shopt -s extglob 
    # Hmmm... It must be set somewhere else
    [[ ! -z $BASH_GLOBAL_TIMING ]] && startStopwatch 'bash completion'

    # I think compgen is used here because it's a built-in (instead of something like ls)
    # if compgen -G "${HOME}/bash-completion/completions/*" > /dev/null
    # then
    #     for file in ${HOME}/bash-completion/completions/*
    #     do
    #         echo $file
    #         . "$file"
    #     done
    # fi
    # [[ ! -z $BASH_GLOBAL_TIMING ]] && checkStopwatch 'bash completion' "${HOME}/bash-completion/completions/ complete"

    deferCompletionLoad "${HOME}/bash-completion/completions/docker" docker
    deferCompletionLoad "${HOME}/bash-completion/completions/podman" podman

    deferCompletionLoad "${HOME}/bash-completion/gradle-completion/gradle-completion.bash" ./gradlew ./gradlew.bat gradle gradle.bat gradlew gradlew.bat gw

    deferCompletionLoad "${HOME}/bash-completion/nmap-completion/nmap" nmap zenmap
    newDeferCompletionLoad "${HOME}/bash-completion/nmap-completion/ncat" _ncat ncat 
    deferCompletionLoad "${HOME}/bash-completion/nmap-completion/nping" nping
    deferCompletionLoad "${HOME}/bash-completion/nmap-completion/ndiff" ndiff

    # if [[ -d "${HOME}/bash-completion/gradle-completion/" ]] ; then
    #     . "${HOME}/bash-completion/gradle-completion/gradle-completion.bash"
    # fi

    [[ ! -z $BASH_GLOBAL_TIMING ]] && checkStopwatch 'bash completion' "completion complete"
fi

[[ ! -z $BASH_GLOBAL_TIMING ]] && checkStopwatch bash.global "After bash completion"



# https://web.mit.edu/gnu/doc/html/features_7.html
# https://www.gnu.org/software/bash/manual/html_node/Bindable-Readline-Commands.html
# bind -p  --  lists all bindings
# bind '"\e": kill-whole-line' # escape, but very slow
bind '"\C-u": kill-whole-line' # ctrl-u  --  default, here to remind me
bind '"\C-h": backward-kill-word' # ctrl-backspace
bind '"\e[3;5~": kill-word' # ctrl-delete
bind '"\e[1;5D": backward-word' # ctrl-left arrow
bind '"\e[1;5C": forward-word' # ctrl-right arrow
bind '"\C-k": clear-display' # ctrl-k  --  clears display and buffer
bind '"\C-_": undo' # default, here to remind me
# bind '"\C-z": undo' # ctrl-z won't work because the terminal grabs it


[[ ! -z $BASH_GLOBAL_TIMING ]] && checkStopwatch bash.global "After key bindings"




# PS1 will be overwritten by /etc/bashrc, or something like that
# https://scriptim.github.io/bash-prompt-generator/
# https://www.cyberciti.biz/tips/howto-linux-unix-bash-shell-setup-prompt.html
# https://wiki.archlinux.org/title/Bash/Prompt_customization
# https://www.cyberciti.biz/faq/bash-shell-change-the-color-of-my-shell-prompt-under-linux-or-unix/

RED="\[\e[0;1;91m\]"
GREEN="\[\e[0;1;92m\]"
if [[ "$EUID" -eq 0 ]]
then
    COLOR=${RED}
    TITLE_USER="root@"
else
    COLOR=${GREEN}
fi

PROMPT="${COLOR}\u\[\e[0;1m\]@${GREEN}\h${PLATFORM}\[\e[0;1m\]:\[\e[0;1;94m\]\w\[\e[0m\]\n\\$\[\e[m\] "
export PS1="${PROMPT}${TITLE}"


[[ ! -z $BASH_GLOBAL_TIMING ]] && checkStopwatch bash.global "End"
