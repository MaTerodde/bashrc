# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

## other aliases
alias bashrc='GITLAB_WORKFLOW_INSTANCE_URL=https://gitlab.ernstings-family.com GITLAB_WORKFLOW_TOKEN=Nz6yn1f2194hx_LiWfqr code ~/git/bashrc/.bashrc'
alias .b='source ~/.bashrc 2>/dev/null'
function pubkey() { sudo chmod 0600 $1 && ssh-keygen -f $1 -y; }
function resolvecurl() { curl -H "host:$1" --resolve $1:${3:-'443'}:$2 https://$1 -v; }
alias vaultUnsealKey='jq -r ".unseal_keys_b64[]" ./cluster-keys.json'
function loop() {
    trap "echo Exited!; exit;" SIGINT SIGTERM

    MAX_RETRIES=100
    i=0
    # Set the initial return value to failure
    false
    while [ $i -lt $MAX_RETRIES ]
    do
        i=$(($i+1))
        $1 $2 $3 $4 $5 $6 $7 $8 $9
        sleep 100
    done
    if [ $i -eq $MAX_RETRIES ]
    then
        echo "Hit maximum number of retries, giving up."
    fi
}

function loopFail() {
    trap "echo Exited!" SIGINT SIGTERM

    MAX_RETRIES=100
    i=0
    # Set the initial return value to failure
    false
    while [ $? -ne 0 -a $i -lt $MAX_RETRIES ]
    do
        trap "echo Exited!; exit;" SIGINT SIGTERM
        i=$(($i+1))
        $1 $2 $3 $4 $5 $6 $7 $8 $9
    done
    if [ $i -eq $MAX_RETRIES ]
    then
        echo "Hit maximum number of retries, giving up."
    fi
}

# Windows programs
alias exp='/mnt/c/Windows/explorer.exe .'


# Directory shortcuts
alias cdgit='cd ~/git'
alias cdter='cd ~/git/Terraform && git pull && code .'
alias cdter_='cd ~/git/Terraform'
alias cdci='cd ~/git/ci-pipeline-config && git pull'
alias cdps='cd ~/git/platform-services && git pull && code .'

# Terraform
alias tapply='terraform apply "plan.tfplan"'
alias ti='terraform init'
function tplan() { terraform init && terraform plan -out plan.tfplan $1 $2 $3 $4 $5 $6;}

# Docker
alias dkill='echo "stopped:" && docker stop $(docker ps -a -q) && echo "removed:" && docker rm $(docker ps -a -q)'
function dexec() { docker exec -it $1 bash; }
function dg() { docker exec gitlab $*; }
function micup() { while aws ecs describe-services --cluster arn:aws:ecs:eu-central-1:774124932165:cluster/micrositeclusterpreprod --services ef-$1-preprod | grep rolloutStateReason | head -n 1 | grep progress > /dev/null; do echo 'in progress' && test $? == 0| sleep 10; done; }

# Git
alias gp='git pull'
alias gs='git status'
alias br='git branch -l'
function gc() { git commit -m  "$*" && git push; }
function ga() { git add  "$1" && git status; }
function gca() { git add  -A && git commit -m  "$*" && git push; }
alias gall='git add -A'

# Kubernetes
function getCfg() {  eksctl utils write-kubeconfig --cluster=eks-ef$1; }
alias k='kubectl'
function kd() { kubectl $1 $2 $3 $4 $5 $6 $7 $8 $9 $10 -n development;}
function kexec() { kubectl exec --stdin --tty "$1" -n $2 -- sh;}
function debugPod() { kubectl -n $1 debug -it $2 --image=ubuntu --target=$3 -- /bin/bash;}
function debugSA() { export TOKEN=$(kubectl exec $2 -n $1 -- cat /var/run/secrets/eks.amazonaws.com/serviceaccount/token) && kubectl -n $1 debug -it $2 --image=amazon/aws-cli --target=$3 -- aws sts assume-role-with-web-identity --role-arn $4 --role-session-name test --web-identity-token=$TOKEN ;}
function x() { cat ~/.bashrc | grep "function $1"; cat ~/.bashrc | grep "alias $1";}
# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi
# Start Docker daemon automatically when logging in if not running.
RUNNING=`ps aux | grep dockerd | grep -v grep`
if [ -z "$RUNNING" ]; then
    sudo dockerd > /dev/null 2>&1 &
    disown
fi

complete -C /usr/bin/terraform terraform

function retryPlan() {
    success=false
    while [ $success = false ] ;
        do
    # Execute the command
            terraform init | grep The newest available version
            if [ $? -eq 0 ];
                then
                    success=true
                else
                echo "Trying again..."
            fi
        done
}

parse_git_branch() {
    git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}
parse_aws_creds() {
    if env | grep -q AWS
    then
        CALLER_ID=$(aws sts get-caller-identity || true)
        CALLER_ID_ERROR=$(echo $CALLER_ID | grep error)
        if [ -n "$CALLER_ID_ERROR" ]
        then
            echo '-'
        else
            CALLER_ID=$(aws sts get-caller-identity | jq -r .Account)
            case $CALLER_ID in
            166439682244)
                echo 'dev/rel'
                ;;
            774124932165)
                echo 'preprod'
                ;;
            593977314557)
                echo 'net'
                ;;
            041891899590)
                echo 'prod'
                ;;
            164238261836)
                echo 'efdev'
                ;;
            356704626339)
                echo 'efpreprod'
                ;;
            137664671815)
                echo 'efnet'
                ;;
            305331930007)
                echo 'efprod'
                ;;
            313137676260)
                echo 'training'
                ;;
            esac
        fi
    fi

}
check_creds_validity() {
    CALLER_ID=$(aws sts get-caller-identity)
    CALLER_ID_ERROR=$(echo $CALLER_ID | grep error)
    if [ -n "$CALLER_ID_ERROR" ]
    then
        echo '01;35'
    else
        echo '01;32'
    fi
}

PS1='\[\033[01;31m\]\u@\h\[\033[00m\]($(parse_aws_creds)):\[\033[01;34m\]\w\[\033[00m\]\[\033[01;33m\]$(parse_git_branch)\[\033[00m\]\$ '
# PS1='\[\033[$(check_creds_validity)m\]\u@\h\[\033[00m\]($(parse_aws_creds)):\[\033[01;34m\]\w\[\033[00m\]\[\033[01;33m\]$(parse_git_branch)\[\033[00m\]\$ '


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
export PATH=$PATH:$HOME/bin
export GITLAB_WORKFLOW_INSTANCE_URL=https://gitlab.ernstings-family.com
export GITLAB_WORKFLOW_TOKEN=Nz6yn1f2194hx_LiWfqr
[[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh
