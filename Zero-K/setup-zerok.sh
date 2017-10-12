#!/bin/bash
installdir=$( dirname "${0}" )

# User install folders
lshare="$HOME/.local/share"

# Where to place .desktop file
apps="${lshare}/applications"
# Where to place icon
icons="${lshare}/icons"

# Setup dependencies ...
pkgmanager=$( which apt-get )
pkx=$( which pkexec )
if [ -n "${pkgmanager}" -a -n "${pkx}" ]
then
  ${pkx} ${pkgmanager} -y install mono-complete libsdl2-2.0-0 libopenal1 libcurl3 zenity libgdiplus
fi

# Setup ZK...
cd ${installdir}
installdir=$PWD
wget -N https://zero-k.info/lobby/Chobby.exe 2>&1 | tee /dev/stderr | sed -u "s/^ *[0-9]*K[ .]*\([0-9]*%\).*/\1/" | zenity --progress --text "Downloading Zero-K Lobby..." --title "Downloading Zero-K" --auto-close --auto-kill --no-cancel
chmod +x Chobby.exe

# Create .desktop file for launching Zero-K from the menu
echo "[Desktop Entry]
Type=Application
Version=1.0-5
Name=Zero-K
Keywords=game;strategy;
Icon=Zero-K
Path=${installdir}
Exec=mono ${installdir}/Chobby.exe
Terminal=false
StartupNotify=false
Categories=Game;StrategyGame;
Comment=Free real time strategy (RTS) game
" > "${installdir}/Zero-K.desktop"
chmod +x "${installdir}/Zero-K.desktop"

# Verify local folders exist
if [ ! -d "$apps" ]
then
  mkdir "$apps"
fi

if [ ! -d "$icons" ]
then
  mkdir "$icons"
fi

mv "${installdir}/Zero-K.desktop" "${apps}/."

mv "${installdir}/Zero-K.png" "${icons}/."

# Delete itself
zenity --info --title "Done\!" --text "Zero-K is now installed\! You can find it in your applications menu."
rm "${0}"

