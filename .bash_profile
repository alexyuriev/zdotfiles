# .bash_profile
#
# File executed by bash(1) shell upon login

if [ -e $HOME/.bash_aliases ]; then
	. $HOME/.bash_aliases
fi

if [ -e $HOME/.bash_local ]; then
	. $HOME/.bash_local
fi

if [ -e $HOME/.bash_colors ]; then
	. $HOME/.bash_colors
fi

function peco_history() {
  BUFFER=$(history | tail -1000 | tac | sed 's/^[[:space:]]\+[[:digit:]]\+[[:space:]]\+//'| uniq | peco)
  READLINE_LINE=${BUFFER}
  READLINE_POINT=${#READLINE_LINE}
}

bind -x '"\C-r":peco_history'

if [ -e $HOME/bin/gitprompt ]; then
	PS1="\n$COLOR_BG_BLUE$COLOR_FG_LIGHTGRAY \$(date) $COLOR_RESET_ALL\e[7;49;90m \u@\h \n$COLOR_RESET_ALL\$(gitprompt) $COLOR_FG_YELLOW\w $r \n\[$COLOR_FG_YELLOW\]\$ \[$COLOR_FG_GREEN\]"
else
	PS1='\n$COLOR_BG_BLUE$COLOR_FG_LIGHTGRAY \$(date) $COLOR_RESET_ALL\e[7;49;90m \u@\h \n$COLOR_RESET_ALL$COLOR_FG_YELLOW\w $r \n\[$COLOR_FG_YELLOW\$ $COLOR_FG_GREEN\]'
fi

export PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/opt/bin:/opt/sbin:$HOME/bin
