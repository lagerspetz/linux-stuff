#!/bin/bash
## backup-drache.sh
##
## Backs up important places on my computer
## to my USB hard drive. To be run weekly by cron as root.
## Copied, simplified and improved by Eemil Lagerspetz
## from Backup Manager, 
## Copyright © 2005-2006 Alexis Sukrieh.
## This script is distributed under the GPL.
##
## Started on  Wed May 21 10:35:36 2008 Eemil Lagerspetz
## Last update Wed May 13 14:02:36 2009 Eemil Lagerspetz
##

## User assignable parameters:
REPOSITORY_ROOT="/media/backup/backup/drache"
REPOSITORY_CHMOD="750"
USER="$( whoami )"
GROUP="users"
ARCHIVE_CHMOD="660"
ARCHIVE_PREFIX="${HOSTNAME}"
TARBALL_FILETYPE="tar.gz"
# -S handle sparsed files efficiently
# -P absolute file names
# -p preserve perms
# -s same order
# --ignore-failed-read do not abort archival on unreadable files
TARCMD="tar czpsPS --ignore-failed-read"
TARGETS="/etc /home /opt /project /var/www"
IGNORE_PREFIXES=",, ++ .gvfs" # ignore Gnome virtual FS and tla (arch) removables
NOTIFY="sudo -u ${USER} DISPLAY=:0 notify-send -i tar"

# Do we have notify support?
if [ -n $( which notify-send ) ]; then DO_NOTIFY="true"; fi

## Generated variables:
TODAY=$( date +%Y-%m-%d )
UPREF=${ARCHIVE_PREFIX}-${TODAY}
LNAME=${UPREF}.log
SUMNAME=${UPREF}.md5

## Add excludes to tar command:
for k in ${IGNORE_PREFIXES}; do
    TARCMD+=" --exclude=\"${k}*\""
done
TARCMD+=" -f" # -f must precede the target file

## common functionality:
## message logging
function log {
    echo "$1" >> "${LNAME}"
    if [ -n "${DO_NOTIFY}" ]; then ${NOTIFY} "$2" "$1"; fi # If there is no $2, collapses to $1
}

## Set credentials
function creds {
    chmod ${ARCHIVE_CHMOD} "$1"
    chown ${USER}:${GROUP} "$1"
}

## create repository, chmod and chown it:
if [ ! -d ${REPOSITORY_ROOT} ]; then
    mkdir -p ${REPOSITORY_ROOT}
fi
chmod ${REPOSITORY_CHMOD} ${REPOSITORY_ROOT}
chown ${USER}:${GROUP} ${REPOSITORY_ROOT}

## enter repository
cd ${REPOSITORY_ROOT}

## remove old log and md5sum file, create and chmod & chown
for logfile in "${LNAME}" "${SUMNAME}"; do
    if [ -f "${logfile}" ]; then rm "${logfile}"; fi
    touch "${logfile}"
    creds "${logfile}"
done

## do the work
log "Starting backup run. Targets: ${TARGETS}" "Starting backup run."
for k in ${TARGETS}; do
    ANAME=${UPREF}${k////-}.${TARBALL_FILETYPE} # archive name
    log "Archiving ${k} to ${REPOSITORY_ROOT}/${ANAME}" "Archiving ${k}"
    nice -n 19 ${TARCMD} "${ANAME}" "${k}" >> "${LNAME}" 2>&1 # tar with low priority
    md5sum "${ANAME}" >> "${SUMNAME}" # checksum archive
    creds "${ANAME}" # set permissions
done

