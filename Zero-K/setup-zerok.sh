#!/bin/bash
installdir=$( dirname "${0}" )

# Setup dependencies ...
pkexec apt-get -y install mono-complete libsdl2-2.0-0 libopenal1 libcurl3 zenity libgdiplus

# Setup ZK...
cd ${installdir}
installdir=$PWD
wget -N https://zero-k.info/lobby/Chobby.exe 2>&1 | tee /dev/stderr | sed -u "s/^ *[0-9]*K[ .]*\([0-9]*%\).*/\1/" | zenity --progress --text "Downloading Zero-K Lobby..." --title "Downloading Zero-K" --auto-close --auto-kill --no-cancel
chmod +x Chobby.exe

echo "[Desktop Entry]
Version=1.0
Name=Zero-K
Exec=mono ${installdir}/Chobby.exe
Path=${installdir}
Icon=Zero-K
Terminal=false
Type=Application
Categories=Application;Game;ArcadeGame;
" > "${installdir}/Zero-K.desktop"
chmod +x "${installdir}/Zero-K.desktop"

if [ ! -d "$HOME/.local/share/applications" ]
then
  mkdir "$HOME/.local/share/applications"
fi

if [ ! -d "$HOME/.local/share/pixmaps" ]
then
  mkdir "$HOME/.local/share/pixmaps"
fi

mv "${installdir}/Zero-K.desktop" "$HOME/.local/share/applications/."

mv "${installdir}/Zero-K.png" "$HOME/.local/share/pixmaps/."

# Delete itself
zenity --info --title "Done\!" --text "Setup complete! Please click the \"Zero-K\" file to run the game."
rm "${0}"

