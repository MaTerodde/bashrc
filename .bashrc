# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

######################
## General Settings ##
######################

#### History ####
HISTCONTROL=ignoreboth # don't put duplicate lines or lines starting with space in the history.
HISTSIZE=1000
HISTFILESIZE=2000

shopt -s histappend # append to the history file, don't overwrite it
shopt -s checkwinsize # check the window size after each command and, if necessary, update the values of LINES and COLUMNS.
shopt -s globstar # match all files and zero or more directories and subdirectories.


[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)" # make less more friendly for non-text input files, see lesspipe(1)

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

#### Prompt ####
# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
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
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01' # colored GCC warnings and errors
## Actual Prompt
get_aws_env() {
    if [ -z "$AWSENV" ]; then
        export AWSENV=" "
    fi
    if [ -n "$AWSENV" ]; then
        echo " [$AWSENV]"
    fi
}

parse_git_branch() {
    git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

PS1='\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\[\033[01;33m\]$(parse_git_branch)\[\033[01;92m\]$(get_aws_env)\[\033[00m\]\$ '
# PS1='\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\[\033[01;33m\]$(parse_git_branch)\[\033[00m\]\$ '

###############
## Shortcuts ##
###############

# ls
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

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
function getCfg() {  eksctl utils write-kubeconfig --cluster=eks-$1; }
alias k='kubectl'
function kd() { kubectl $1 $2 $3 $4 $5 $6 $7 $8 $9 $10 -n development;}
function kexec() { kubectl exec --stdin --tty "$1" -n $2 -- sh;}
function debugPod() { kubectl -n $1 debug -it $2 --image=ubuntu --target=$3 -- /bin/bash;}
function debugSA() { export TOKEN=$(kubectl exec $2 -n $1 -- cat /var/run/secrets/eks.amazonaws.com/serviceaccount/token) && kubectl -n $1 debug -it $2 --image=amazon/aws-cli --target=$3 -- aws sts assume-role-with-web-identity --role-arn $4 --role-session-name test --web-identity-token=$TOKEN ;}

# loops
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

# other
alias bashrc='code ~/git/bashrc/.bashrc'
alias .b='. ~/.bashrc'
function .a() {
    export AWSENV=$(aws sts get-caller-identity | jq -r .Account | sed 's/166439682244/dev/g' | sed 's/164238261836/efdev/g' | sed 's/137664671815/efnet/g' | sed 's/356704626339/efpreprod/g' | sed 's/305331930007/efprod/g' | sed 's/593977314557/net/g' | sed 's/774124932165/preprod/g' | sed 's/041891899590/prod/g')
    export ENV="$AWSENV"
    if [ "$ENV" == "efdev" ] || [ "$ENV" == "efpreprod" ] || [ "$ENV" == "efprod" ] || [ "$ENV" == "efnet" ]; then
        getCfg "$ENV"
    fi
}
function pubkey() { sudo chmod 0600 $1 && ssh-keygen -f $1 -y; }
function x() { cat ~/.bashrc | grep "function $1"; cat ~/.bashrc | grep "alias $1";}
function resolvecurl() { curl -H "host:$1" --resolve $1:${3:-'443'}:$2 https://$1 -v    ; }
alias vaultUnsealKey='jq -r ".unseal_keys_b64[]" ./cluster-keys.json'
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
alias awsenv='aws sts get-caller-identity | jq -r .Account | sed 's/166439682244/dev/g' | sed 's/164238261836/efdev/g' | sed 's/137664671815/efnet/g' | sed 's/356704626339/efpreprod/g' | sed 's/305331930007/efprod/g' | sed 's/593977314557/net/g' | sed 's/774124932165/preprod/g' | sed 's/041891899590/prod/g'' >&/dev/null
function vaultRole() { vault read auth/jwt/role/$1; }
###########
## Other ##
###########
# enable programmable completion features
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

complete -C /usr/bin/terraform terraform

export PATH=$PATH:$HOME/bin
[[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh
