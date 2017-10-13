#!/bin/bash
##
## saferm.sh
## Safely remove files, moving them to GNOME/KDE trash instead of deleting.
## Made by Eemil Lagerspetz
## Login   <vermind@drache>
## 
## Started on  Mon Aug 11 22:00:58 2008 Eemil Lagerspetz
## Last update Sat Aug 16 23:49:18 2008 Eemil Lagerspetz
##

version="1.16";

## flags (change these to change default behaviour)
recursive="" # do not recurse into directories by default
verbose="true" # set verbose by default for inexperienced users.
force="" #disallow deleting special files by default
unsafe="" # do not behave like regular rm by default

## possible flags (recursive, verbose, force, unsafe)
# don't touch this unless you want to create/destroy flags
flaglist="r v f u q"

# Colours
blue='\e[1;34m'
red='\e[1;31m'
norm='\e[0m'

## trashbin definitions
# this is the same for newer KDE and GNOME:
trash_desktops="$HOME/.local/share/Trash/files"
# if neither is running:
trash_fallback="$HOME/Trash"

# use .local/share/Trash?
use_desktop=$( ps -U $USER | grep -E "gnome-settings|startkde|mate-session|mate-settings|mate-panel|gnome-shell|lxsession|unity" )

# mounted filesystems, for avoiding cross-device move on safe delete
filesystems=$( mount | awk '{print $3; }' )

if [ -n "$use_desktop" ]; then
    trash="${trash_desktops}"
    infodir="${trash}/../info";
    for k in "${trash}" "${infodir}"; do
        if [ ! -d "${k}" ]; then mkdir -p "${k}"; fi
    done
else
    trash="${trash_fallback}"
fi

usagemessage() {
	echo -e "This is ${blue}saferm.sh$norm $version. LXDE and Gnome3 detection.
    Will ask to unsafe-delete instead of cross-fs move. Allows unsafe (regular rm) delete (ignores trashinfo).
    Creates trash and trashinfo directories if they do not exist. Handles symbolic link deletion.
    Does not complain about different user any more.\n";
	echo -e "Usage: ${blue}/path/to/saferm.sh$norm [${blue}OPTIONS$norm] [$blue--$norm] ${blue}files and dirs to safely remove$norm"
	echo -e "${blue}OPTIONS$norm:"
	echo -e "$blue-r$norm      allows recursively removing directories."
	echo -e "$blue-f$norm      Allow deleting special files (devices, ...)."
  echo -e "$blue-u$norm      Unsafe mode, bypass trash and delete files permanently."
	echo -e "$blue-v$norm      Verbose, prints more messages. Default in this version."
  echo -e "$blue-q$norm      Quiet mode. Opposite of verbose."
	echo "";
}

detect() {
    if [ ! -e "$1" ]; then fs=""; return; fi
    path=$(readlink -f "$1")
    for det in $filesystems; do
        match=$( echo "$path" | grep -oE "^$det" )
        if [ -n "$match" ]; then
            if [ ${#det} -gt ${#fs} ]; then
                fs="$det"
            fi
        fi
    done
}


trashinfo() {
#gnome: generate trashinfo:
	bname=$( basename -- "$1" )
    fname="${trash}/../info/${bname}.trashinfo"
    cat <<EOF > "${fname}"
[Trash Info]
Path=$PWD/${1}
DeletionDate=$( date +%Y-%m-%dT%H:%M:%S )
EOF
}

setflags() {
    for k in $flaglist; do
	reduced=$( echo "$1" | sed "s/$k//" )
	if [ "$reduced" != "$1" ]; then
	    flags_set="$flags_set $k"
	fi
    done
  for k in $flags_set; do
	if [ "$k" == "v" ]; then
	    verbose="true"
	elif [ "$k" == "r" ]; then 
	    recursive="true"
	elif [ "$k" == "f" ]; then 
	    force="true"
	elif [ "$k" == "u" ]; then 
	    unsafe="true"
	elif [ "$k" == "q" ]; then 
    unset verbose
	fi
  done
}

performdelete() {
			# "delete" = move to trash
			if [ -n "$unsafe" ]
			then
			  if [ -n "$verbose" ];then echo -e "Deleting $red$1$norm"; fi
		    #UNSAFE: permanently remove files.
		    rm -rf -- "$1"
			else
			  if [ -n "$verbose" ];then echo -e "Moving $blue$k$norm to $red${trash}$norm"; fi
		    mv -b -- "$1" "${trash}" # moves and backs up old files
			fi
}

askfs() {
  detect "$1"
  if [ "${fs}" != "${tfs}" ]; then
    unset answer;
    until [ "$answer" == "y" -o "$answer" == "n" ]; do
      echo -e "$blue$1$norm is on $blue${fs}$norm. Unsafe delete (y/n)?"
      read -n 1 answer;
    done
    if [ "$answer" == "y" ]; then
      unsafe="yes"
    fi
  fi
}

complain() {
  msg=""
  if [ ! -e "$1" -a ! -L "$1" ]; then # does not exist
    msg="File does not exist:"
	elif [ ! -w "$1" -a ! -L "$1" ]; then # not writable
    msg="File is not writable:"
	elif [ ! -f "$1" -a ! -d "$1" -a -z "$force" ]; then # Special or sth else.
    	msg="Is not a regular file or directory (and -f not specified):"
	elif [ -f "$1" ]; then # is a file
    act="true" # operate on files by default
	elif [ -d "$1" -a -n "$recursive" ]; then # is a directory and recursive is enabled
    act="true"
	elif [ -d "$1" -a -z "${recursive}" ]; then
		msg="Is a directory (and -r not specified):"
	else
		# not file or dir. This branch should not be reached.
		msg="No such file or directory:"
	fi
}

asknobackup() {
  unset answer
	until [ "$answer" == "y" -o "$answer" == "n" ]; do
	  echo -e "$blue$k$norm could not be moved to trash. Unsafe delete (y/n)?"
	  read -n 1 answer
	done
	if [ "$answer" == "y" ]
	then
	  unsafe="yes"
	  performdelete "${k}"
	  ret=$?
		# Reset temporary unsafe flag
	  unset unsafe
	  unset answer
	else
	  unset answer
	fi
}

deletefiles() {
  for k in "$@"; do
	  fdesc="$blue$k$norm";
	  complain "${k}"
	  if [ -n "$msg" ]
	  then
		  echo -e "$msg $fdesc."
    else
    	#actual action:
    	if [ -z "$unsafe" ]; then
    	  askfs "${k}"
    	fi
		  performdelete "${k}"
		  ret=$?
		  # Reset temporary unsafe flag
		  if [ "$answer" == "y" ]; then unset unsafe; unset answer; fi
      #echo "MV exit status: $ret"
      if [ ! "$ret" -eq 0 ]
      then 
        asknobackup "${k}"
      fi
      if [ -n "$use_desktop" ]; then
          # generate trashinfo for desktop environments
        trashinfo "${k}"
      fi
    fi
	done
}

# Make trash if it doesn't exist
if [ ! -d "${trash}" ]; then
    mkdir "${trash}";
fi

# find out which flags were given
afteropts=""; # boolean for end-of-options reached
for k in "$@"; do
	# if starts with dash and before end of options marker (--)
	if [ "${k:0:1}" == "-" -a -z "$afteropts" ]; then
		if [ "${k:1:2}" == "-" ]; then # if end of options marker
			afteropts="true"
		else # option(s)
    		    setflags "$k" # set flags
    	        fi
	else # not starting with dash, or after end-of-opts
		files[++i]="$k"
	fi
done

if [ -z "${files[1]}" ]; then # no parameters?
	usagemessage # tell them how to use this
	exit 0;
fi

# Which fs is trash on?
detect "${trash}"
tfs="$fs"

# do the work
deletefiles "${files[@]}"

