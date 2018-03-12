#!/bin/bash
size="1024x1024"
#border="10x10"
dir="resized"
extra=""

if [ ! -d "${dir}" ]; then mkdir "${dir}"; fi

count=0
i=0
for k in *.[Jj][Pp][Gg]; do
    if [ ! -f "$k" ]; then continue; fi
    let count++
done

havezen=$( which zenity )

if [ -n "$havezen" ]; then
    zencmd="zenity";
    zenparams="--progress --auto-close --auto-kill --text ";
    if [ -n "${border}" ]; then
        ztext="Resizing to $size and adding a $border border to $count images and rotating if needed";
    else
        ztext="Resizing $count images to $size and rotating if needed";
    fi
    zt="--title";
    ztitle="Resizing images";
else
    zencmd="sed -e s/\$/%/ -- -"
    echo "Notice: Install zenity for a graphical progress bar."
    echo "Resizing to $size and adding a $border border to $count images."
fi


for k in *.[Jj][Pp][Gg]; do
    if [ ! -f "$k" ]; then continue; fi
    small=$( echo "$k" | tr "[:upper:]" "[:lower:]" )
    # Do we need to rotate?
    rotatedeg=$( exiftool $k | grep "Orientation" | grep -oE "[0-9]*")
    if [ -n "${rotatedeg}" ]; then
        extra="-rotate ${rotatedeg}"
    else
        extra=""
    fi
    if [ -n "${border}" ]; then
        convert "${k}" -scale "${size}" -bordercolor black -border "${border}" $extra "${dir}/${small}"
    else
        convert "${k}" -scale "${size}" $extra "${dir}/${small}"
    fi
    let i++
    let pcent="${i}"*100/"${count}" # i / count / 100 = i / count * 100 = i * 100 / count
    #echo "$i of $count done"
    echo "${pcent}"
done | $zencmd ${zenparams} "${ztext}" ${zt} "${ztitle}" 2>/dev/null


