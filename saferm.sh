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

version="1.12";

## flags (change these to change default behaviour)
recursive="" # do not recurse into directories by default
verbose="true" # set verbose by default for inexperienced users.
force="" #disallow deleting special files by default
unsafe="" # do not behave like regular rm by default

## possible flags (recursive, verbose, force, unsafe)
# don't touch this unless you want to create/destroy flags
flaglist="r v f u"

# Colours
blue='\e[1;34m'
red='\e[1;31m'
norm='\e[0m'

## trashbin definitions
# this is the same for newer KDE and GNOME:
trash_desktops="$HOME/.local/share/Trash/files"
# if neither is running:
trash_fallback="$HOME/Trash"

# which trashbin?
use_gnome=$( ps -U $USER | grep gnome-settings )
use_kde=$( ps -U $USER | grep startkde )

# mounted filesystems, for avoiding cross-device move on safe delete
filesystems=$( mount | awk '{print $3; }' )

if [ -n "$use_gnome" -o -n "$use_kde" ]; then
    trash="${trash_desktops}"
    infodir="${trash}/../info";
    for k in "${trash}" "${infodir}"; do
        if [ ! -d "${k}" ]; then mkdir -p "${k}"; fi
    done
else
    trash="${trash_fallback}"
fi

function usagemessage {
	echo -e "This is ${blue}saferm.sh$norm $version. Will ask to unsafe-delete instead of cross-fs
    move. Allows unsafe (regular rm) delete (ignores trashinfo).
Detects gnome better. Creates trash and trashinfo directories if they do not exist.
Handles symbolic link deletion. Does not complain about different user any more.\n";
	echo -e "Usage: ${blue}/path/to/saferm.sh$norm [${blue}OPTIONS$norm] [$blue--$norm] ${blue}files and dirs to safely remove$norm"
	echo -e "$blueOPTIONS$norm:"
	echo -e "$blue-r$norm      allows recursively removing directories."
	echo -e "$blue-f$norm      Allow deleting special files (devices, ...)."
    echo -e "$blue-u$norm      Unsafe mode, bypass trash and delete files permanently."
	echo -e "$blue-v$norm      Verbose, prints more messages. Default in this version."
	echo "";
}

function detect {
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


function trashinfo {
#gnome: generate trashinfo:
	bname=$( basename -- "$1" )
    fname="${trash}/../info/${bname}.trashinfo"
    cat <<EOF > "${fname}"
[Trash Info]
Path=$PWD/${1}
DeletionDate=$( date +%Y-%m-%dT%H:%M:%S )
EOF
}

function setflags {
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
	fi
    done
}

function deletefiles {
    for k in "$@"; do
	fdesc="$blue$k$norm";
    	act="";
    	msg="";
    	if [ ! -e "$k" -a ! -L "$k" ]; then # does not exist
    	    msg="File does not exist:"
    	elif [ ! -w "$k" -a ! -L "$k" ]; then # not writable
    	    msg="File is not writable:"
    	#elif [ ! -O "$k" ]; then # not owned by us
    		#if [ -n "$force" ]; then
    			#act="true" # delete only if forced
    		#else
    	    	#msg="File is not owned by $USER (use -f to override):"
    	    #fi
    	elif [ ! -f "$k" -a ! -d "$k" ]; then # Special or sth else.
    	    if [ -n "$force" ]; then 
	        	act="true" # delete only if forced.
    	    else
	        	msg="Is not a regular file or directory (and -f not specified):"
    	    fi
    	elif [ -f "$k" ]; then # is a file
	        act="true" # operate on files by default
    	elif [ -d "$k" ]; then # is a dir
    	    if [ -n "${recursive}" ]; then
    			act="true" # operate on dirs if r specified
    		else
    			msg="Is a directory (and -r not specified):"
    		fi
		else
			# not file or dir. This branch should not be reached.
			msg="No such file or directory:";
    	fi
    
    	#actual action:    
    	if [ -n "$act" ]; then # if we can delete
			if [ -n "$verbose" ]; then # print if requested
			    if [ -n "$unsafe" ]; then 
	    		    echo -e "Deleting $red$k$norm"
	    		else
                    detect "$PWD/$k"
                    if [ "${fs}" == "${tfs}" ]; then
        	    		echo -e "Moving $blue$k$norm to $red${trash}$norm"
                    else
                        unset answer;
                        until [ "$answer" == "y" -o "$answer" == "n" ]; do
                            echo -e "$blue$k$norm is on $blue${fs}$norm. Unsafe delete (y/n)?"
                            read -n 1 answer;
                        done
                        if [ "$answer" == "y" ]; then
                            unsafe="yes"
        	    		    echo -e "Deleting $red$k$norm"
                        else
        	    		    echo -e "Moving $blue$k$norm to $red${trash}$norm"
                        fi
                    fi
    	    	fi
	    	fi
			# "delete" = move to trash
			if [ -n "$unsafe" ]; then
			    #UNSAFE: permanently remove files.
			    rm -rf -- "$k"
			else
			    mv -b -- "$k" "${trash}" # moves and backs up old files
			    if [ -n "$use_gnome" -o -n "$use_kde" ]; then
		    	        # generate trashinfo for desktop environments
	    		        trashinfo "$k"
			    fi
			fi
		else
			# not acting, instead print error message:
			echo -e "$msg $fdesc.";
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

