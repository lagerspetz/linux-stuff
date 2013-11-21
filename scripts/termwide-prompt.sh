#!/bin/bash

#   termwide prompt
#      by Giles - created 2 November 98
#      Edited by Eemil Lagerspetz 27 Oct 11
#         -Moved date to upper line, fixed truncated directory display
#       
#
#   The idea here is to have the upper line of this two line prompt 
#   always be the width of your term.  Do this by calculating the
#   width of the text elements, and putting in fill as appropriate
#   or left-truncating $PWD.
#



function prompt_command {
dt=$(date "+%a,%d %b %y")

TERMWIDTH=${COLUMNS}

#   Calculate the width of the prompt:

hostnam=$(echo -n $HOSTNAME | sed -e "s/[\.].*//")
#   "whoami" and "pwd" include a trailing newline
usernam=$(whoami)
#let usersize=$(echo -n $usernam | wc -c )
newPWD="${PWD/$HOME/~}"
let pwdsize=$(echo -n ${newPWD} | wc -c )
let pwdsize2=${#newPWD}
let pwdsize=${pwdsize}-${pwdsize2}
# 16 bit char penalty must be halved
let penalty=${pwdsize}/2
# character length + 16 bit char penalty
if [ "${penalty}" -lt 0 ]; then
  let penalty=0
fi

  let pwdsize=${pwdsize2}+${penalty}
#   Add all the accessories below ...
pmpt="${usernam}@${hostnam} ${dt} ${newPWD}"
let promptsize=${#pmpt}+$penalty
let fillsize=${TERMWIDTH}-${promptsize}

fill=""
while [ "$fillsize" -gt "0" ] 
do 
   fill="${fill} "
   let fillsize--
done

if [ "$fill" == "" ]
then
  pwdWidth=${TERMWIDTH}
  let nopwd=${promptsize}-${pwdsize}
  let pwdWidth=${pwdWidth}-${nopwd}

  if [ "$pwdWidth" -gt "6" ]; then
    let pwdWidth=${pwdWidth}-3
    dots="..."
  else
    dots=""
  fi


  # Add chars from the end of newPWD one by one until length is reached.
  # In chase of overshoot, go one step back in the end.
  let pwdLen=0
  let realLen=0
  temp=""

  while [ "${realLen}" -lt "${pwdWidth}" ]; do
    let pwdLen++
    temp=$( echo -n "$newPWD" | grep -oE ".{$pwdLen}\$" )
    realLen=$(echo -n "${temp}" | wc -c )
    let realLen2=${#temp}
    let realLen=${realLen}-${realLen2}
    # 16 bit char penalty must be halved
    let penalty=${realLen}/2
    if [ "$penalty" -lt 0 ]; then let penalty=0; fi
    # character length + 16 bit char penalty
    let realLen=${realLen2}+${penalty}
  done
  if [ "${realLen}" -gt "${pwdWidth}" ]; then
    let pwdLen--;
    temp=$( echo -n "$newPWD" | grep -oE ".{$pwdLen}\$" )
  fi

  newPWD="${dots}${temp}"
fi

termwide
}


function termwide {
local _dred="\[\033[31m\]"
local _dgre="\[\033[1;32m\]"
local _bgre="\[\033[1;32m\]"

local GRAY="\[\033[30m\]"
local LIGHT_GRAY="\[\033[37m\]"
local WHITE="\[\033[37m\]"
local NO_COLOUR="\[\033[0m\]"

local LIGHT_BLUE="\[\033[1;34m\]"
local YELLOW="\[\033[1;33m\]"

case $TERM in
    xterm*)
        TITLEBAR='\[\033]0;\u@\h:\w\007\]'
        ;;
    *)
        TITLEBAR=""
        ;;
esac

PS1="$TITLEBAR\
$_dgre\${usernam}$LIGHT_BLUE@$_dgre\${hostnam}\
${_dgre} ${LIGHT_BLUE}\${dt} \${fill}\
$_bgre\${newPWD}\n\
$YELLOW\$(date \"+%H${LIGHT_BLUE}:${YELLOW}%M\" ) ${_dgre}\$$NO_COLOUR "

PS2="$LIGHT_BLUE $NO_COLOUR"

}

PROMPT_COMMAND=prompt_command

