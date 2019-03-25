# .bash_profile
#
# File executed by bash(1) shell upon login

if [ -e $HOME/.bash_aliases ]; then
	. $HOME/.bash_aliases
fi

if [ -e $HOME/.bash_local ]; then
	. $HOME/.bash_local
fi

export PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/opt/bin:/opt/sbin:$HOME/bin
