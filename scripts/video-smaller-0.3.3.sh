#!/bin/bash
size="320x240"
nomonitor="true" # workaround for unknown progress monitoring bug

function resizevideo () {
    n=$( basename -- "$1" ".avi" )
    d=$( dirname -- "$1" )
    logfile=$HOME/Desktop/$n-log.txt
    info=$( ffmpeg -i "$1" 2>&1 )
    aspect=$( echo "$info" | grep -oE "DAR [0-9]*:[0-9]*" | grep -oE "[0-9]*:[0-9]*" )
    bitrate=$( echo "$info" | grep -oE "bitrate: [0-9]*" | grep -oE "[0-9]*" )
    duration=$( echo "$info" | awk -F ':' '$0 ~ "Duration" {print $2*3600+$3*60+$4}' )
    if [ "$bitrate" -lt 200 ]; then
        let bitrate=$bitrate/2
    else 
        bitrate="200";
    fi
    echo "aspect ratio=$aspect
    target bitrate=$bitrate
    Total duration=$duration
    Full information of $1:" > "$logfile"
    echo "$info" >> "$logfile"

    if [ -f "$d/$n"_smaller.avi ]; then
        if ( zenity --question --title "Remove existing file?" --text "${n}_smaller.avi already exists. Do you want to replace it?" --ok-label="Yes" --cancel-label="No" ); then
            rm "$d/$n"_smaller.avi
        else
            zenity --info --title "Cancelled." --text "${n}_smaller.avi already existed and was not overwritten." 
        fi
    fi
    
    if [ -z "$aspect" ]; then
        aspect="4:3"
    fi
    
    if [ -z "${nomonitor}" ]; then
        echo "command=ffmpeg -i $1 -vcodec msmpeg4v2 -s $size -aspect $aspect -ac 2 -b ${bitrate}k $d/${n}_smaller.avi 2>&1 | tee -a $logfile" >> "$logfile"    
        ffmpeg -i "$1" -vcodec msmpeg4v2 -s "$size" \
    -aspect "$aspect" -ac 2 -b "$bitrate"k "$d/$n"_smaller.avi 2>&1 | tee -a "$logfile" &
    # tee to file on background
        sleep 1
        mypid=$$
        ffpid=$( ps -ef | grep $mypid | grep ffmpeg | awk '{ print $2}' )
     
    #awk -v duration=$duration 'BEGIN{FS="="} {while (0 == 0) { if (getline != 0){ if ($0 ~ "frame=" ) {temp=$6}}else{ printf("%d%\n",temp/duration*100);system("sleep 2"); getline }}}' )     
        ( cat "$logfile" | tr '\r' '\n' ) |\
        awk -v duration=$duration 'BEGIN{FS="="} {while (0 == 0) { if (getline != 0){ if ($0 ~ "frame=" ) {temp=$6}}else{ printf("%d%\n",temp/duration*100);system("sleep 2"); getline }}}' |\
        zenity --progress --auto-close --title "Compressing video" --text "Compressing video to divx, please wait."
        sleep 1;
        kill $ffpid
    else
        echo "command=ffmpeg -i $1 -vcodec msmpeg4v2 -s $size -aspect $aspect -ac 2 -b ${bitrate}k $d/${n}_smaller.avi 2>&1 | zenity --progress --auto-close --title \"Compressing video\" --text \"Compressing video to divx, please wait.\"" >> "${logfile}"
        ffmpeg -i "$1" -vcodec msmpeg4v2 -s "$size" \
    -aspect "$aspect" -ac 2 -b "$bitrate"k "$d/$n"_smaller.avi 2>&1 | tee -a "${logfile}" | zenity --progress --auto-close --title "Compressing video" --text "Compressing video to divx, please wait."
    fi
}

havezen=$( which zenity )

if [ -z "$havezen" ]; then
    echo "zenity is not installed. Installing zenity."
    gksudo -- apt-get -y install zenity
fi

havezen=$( which zenity )

if [ -z "$havezen" ]; then
    echo "Installing zenity failed. Cannot continue. Exiting."
    exit 1
fi

haveff=$( which ffmpeg )

if [ -z "$haveff" ]; then
    echo "ffmpeg is not installed. Installing ffmpeg."
    gksudo -- apt-get -y install ffmpeg
fi

haveff=$( which ffmpeg )

if [ -z "$haveff" ]; then
    echo "Installing ffmpeg failed. Cannot continue. Exiting."
    exit 1
fi

video=$(zenity --file-selection --title "Choose the video to make smaller.");
until [ "$?" -eq "0" ]; do
zenity --error --title "Cancelled" --text "video-smaller.sh Cancelled"
exit 0
done

echo "video=$video"
if [ -n "$video" ]; then
    resizevideo "$video"
fi
