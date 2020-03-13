# .bash_profile
#
# File executed by bash(1) shell upon login
#
# tabs: 2. Convert tabs to spaces

# since this can be source'd we should only either use return OR exit
# depending on if it was sourced

export PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/opt/bin:/opt/sbin:$HOME/bin
export EDITOR=joe

if [[ "$0" != "$BASH_SOURCE" ]]; then
    ret=return
else
    ret=exit
fi

# The rest should be executed only in the interactive sessions.

if [[ ! -t 1 ]] ; then
  $ret 0    # non-interactive, exit
fi

if [ -e $HOME/.bash_aliases ]; then
    . $HOME/.bash_aliases
fi

if [ -e $HOME/.bash_local ]; then
    . $HOME/.bash_local
fi

if [ -e $HOME/.bash_colors ]; then
    . $HOME/.bash_colors
fi

if [[ -e $HOME/.bash_fzf ]] ; then
  . $HOME/.bash_fzf
fi

# see if line-editing is enabled, it may be useful

if [[ ${SHELLOPTS} =~ (vi|emacs) ]] ; then
   LINE_EDITING=1
else
   LINE_EDITING=0
fi

# if peco is installed, use it for Ctrl-R editing
#
# if peco-redis-backend is installed, store commands in it so they are shared
# across all workstation terminals/windows/tmux/screens
#

# unset PROMPT_COMMAND

PECO_HIST_SIZE=10000        # allow peco to access upto a 1000 commands
HISTSIZE=1000               # set bash history size in memory (lines)
HISTFILESIZE=${HISTSIZE}    # set bash history size in a file (lines)

# peco_history()
#
# dynamically handle a command line history lookup either
# using peco-redis-backend or using standard bash history.
#
# peco_history does nothing if peco cannot be ran on the system
#

function peco_history() {

  local peco_present
  local peco_backend
  local hist_buffer

  peco_present=$(which peco)

  # if there's no peco, do nothing

  if [[ "x$peco_present" == "x" ]] ; then
    return
  fi
  peco_backend=$(which peco-redis-backend)
  if [[ "x$peco_backend" == "x" ]] ; then
    hist_buffer=`history | sed 's/^[[:space:]]\+[[:digit:]]\+[[:space:]]\+//' | awk '!seen[$0]++' | tac`
  else
    hist_buffer=$(peco-redis-backend --redis-key=peco-backend --max-entries=${PECO_HIST_SIZE} --query)
  fi

  BUFFER=$(echo "${hist_buffer}" | peco --prompt "COMMAND LINE >> ")

  READLINE_LINE=${BUFFER}
  READLINE_POINT=${#READLINE_LINE}

}

# peco_update_history()
#
# function is called by the interactive prompt.
# if peco-redis-backend is present then the query is pushed into it.

function peco_update_history {
  local peco_backend
  local peco_present
  local need_skipline

  peco_backend=$(which peco-redis-backend)
  peco_present=$(which peco)
  need_skipline=1
  if [[ "x$peco_present" == "x" ]] ; then
    need_skipline=0
    echo
    echo -e "${COLOR_RESET_ALL}${COLOR_BG_RED} [peco fuzzy matcher is not accessible] ${COLOR_RESET_ALL}"
  fi
  if [[ "x$peco_backend" == "x" ]] ; then
    if [[ "$need_skipline" == "1" ]] ; then
      echo
    fi
    echo -e "${COLOR_RESET_ALL}${COLOR_BG_RED} [peco-redis-backend is not accessible] ${COLOR_RESET_ALL}"
    return
  fi
  history 1 | peco-redis-backend --redis-key=peco-backend --max-entries=${PECO_HIST_SIZE} --store
}

# execute peco_update_history every time the prompt is rendered

PROMPT_COMMAND=peco_update_history

# if LINE_EDITING is possible, bind Ctrl-R to peco_history.

if [[ $LINE_EDITING -eq "1" ]]; then
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
