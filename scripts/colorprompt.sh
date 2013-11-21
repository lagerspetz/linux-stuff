#!/bin/bash
# change color on unsuccessful execution,
# show bash history line number (for !num exec) and color prompt

# dark red and green
export _dred="\[\033[31m\]"
export _dgre="\[\033[32m\]"

export PROMPT_COMMAND='_bash_history_sync;
if [[ $? == "0" ]]; then _color=$_dgre; else _color=$_dred; fi;
if [ ${#PWD} -gt 30 ]; then _wd=\\W; else _wd=\\w; fi;
if [[ `whoami` = \"root\" ]]; then _prompt=\"${_dred}\\#\";
else _prompt=\$; fi;
PS1="${_color}\u@\h ${_wd} ${_prompt}\[\033[00m\] "'

# explanation of the above:
# green for exit status 0, red for nonzero
# user at host, shorten long directory paths
# use red # for root and (prompt coloured) $ for users in the end of the prompt
# yellow bash history number in the beginning of PS1
# reset color to normal in the end and add a space


