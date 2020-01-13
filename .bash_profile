# .bash_profile
#
# File executed by bash(1) shell upon login
#
# tabs: 4. Convert tabs to spaces

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
    BUFFER=$(history | tail -1000 | tac | sed 's/^[[:space:]]\+[[:digit:]]\+[[:space:]]\+//'| uniq | peco --promot "COMMAND LINE >> ")
    READLINE_LINE=${BUFFER}
    READLINE_POINT=${#READLINE_LINE}
}

# if peco exists, bind Ctrl-R to it.

peco_present=(which peco)
if [ ! -z $peco_present ]; then
    bind -x '"\C-r":peco_history'
fi

# for some reason xterm mapping of colors does not match ALACRITTY mappings but since we want identical prompts
# in both we hack around it

ALACRITTY_COLOR_FG_GREEN="\e[38;5;034m"
ALACRITTY_COLOR_FG_LIGHTGREY="\e[38;5;250m"
ALACRITTY_COLOR_FG_BLACK="\e[38;5;16m"
ALACRITTY_COLOR_FG_BRIGHTGREEN="\e[38;5;046m"
ALACRITTY_COLOR_FG_BRIGHTYELLOW="\e[38;5;226m"
ALACRITTY_COLOR_FG_YELLOW="\e[38;5;15m"

ALACRITTY_COLOR_BG_BLUE="\e[48;5;020m"
ALACRITTY_COLOR_BG_MUTEGREY="\e[48;5;245m"

if [ ! -z $ALACRITTY_TERM ]; then

    DEF_PROMPT_DATE_BG=${ALACRITTY_COLOR_BG_BLUE}
    DEF_PROMPT_DATE_FG=${ALACRITTY_COLOR_FG_GREY}

    DEF_PROMPT_UH_BG=${ALACRITTY_COLOR_BG_MUTEGREY}
    DEF_PROMPT_UH_FG=${ALACRITTY_COLOR_FG_BLACK}

    DEF_PROMPT_GIT_FG=${ALACRITTY_COLOR_FG_BRIGHTGREEN}

    DEF_PROMPT_DIR_FG=${ALACRITTY_COLOR_FG_BRIGHTYELLOW}

    DEF_PROMPT_INDICATOR_FG=${ALACRITTY_COLOR_FG_YELLOW}

    DEF_PROMPT_TEXT_FG=${ALACRITTY_COLOR_FG_GREEN}
else
    DEF_PROMPT_DATE_BG=${COLOR_BG_BLUE}
    DEF_PROMPT_DATE_FG=${COLOR_FG_LIGHTGRAY}

    DEF_PROMPT_UH_BG=${COLOR_RESET_ALL}
    DEF_PROMPT_UH_FG="\e[7;49;90m"

    DEF_PROMPT_GIT_FG=${COLOR_RESET_ALL}

    DEF_PROMPT_DIR_FG=${COLOR_FG_YELLOW}

    DEF_PROMPT_INDICATOR_FG=${COLOR_FG_YELLOW}

    DEF_PROMPT_TEXT_FG=${COLOR_FG_GREEN}

fi

if [ -e $HOME/bin/gitprompt ]; then
    PS1="\n$DEF_PROMPT_DATE_BG$DEF_PROMPT_DATE_FG \$(date) $DEF_PROMPT_UH_BG$DEF_PROMPT_UH_FG \u@\h $COLOR_RESET_ALL\n$DEF_PROMPT_GIT_FG\$(gitprompt) $DEF_PROMPT_DIR_FG\w \n\[$DEF_PROMPT_INDICATOR_FG\]\$ \[$DEF_PROMPT_TEXT_FG\]"
else
    PS1="\n$DEF_PROMPT_DATE_BG$DEF_PROMPT_DATE_FG \$(date) $DEF_PROMPT_UH_BG$DEF_PROMPT_UH_FG \u@\h $COLOR_RESET_ALL\n$DEF_PROMPT_DIR_FG\w \n\[$DEF_PROMPT_INDICATOR_FG\]\$ \[$DEF_PROMPT_TEXT_FG\]"
fi

export PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/opt/bin:/opt/sbin:$HOME/bin
