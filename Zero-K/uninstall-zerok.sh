#!/bin/bash

installdir=$( dirname "${0}" )

cd ${installdir}
installdir=$PWD

rm "$installdir/Chobby.exe" "$HOME/.local/share/applications/Zero-K.desktop" "$HOME/.local/share/icons/Zero-K.png"

# Setup dependencies ...
pkgmanager=$( which apt-mark )
pkx=$( which pkexec )
if [ -n "${pkgmanager}" -a -n "${pkx}" ]
then
  ${pkx} ${pkgmanager} auto mono-complete libsdl2-2.0-0 libopenal1 libcurl3 zenity libgdiplus
fi

# Delete itself
zenity --info --title "Done\!" --text "Zero-K has now been uninstalled. To remove unused dependencies, you can run $pkx $pkmanager autoremove."
rm "${0}"

