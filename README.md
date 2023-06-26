# Linux Stuff by Lagerspetz

This repo contains useful linux scripts.
No guarantee that they work or warranty of
any kind is given. Some highlights:

## Saferm.sh
* `scripts/saferm.sh`: alias this to "rm". Moves files to your desktop environment's trash folder instead of permanently deleting files when you type "rm". To use with sudo, bash users can add an additional `alias sudo='sudo '` which will cause anything that follows sudo to be also checked for aliases, including `rm`.

* `scripts/manually-installed.sh`: Shows the list of manually installed (deb) packages on the system. Useful for keeping track of what is installed.

* `scripts-manually-installed-deps.sh`: Shows which packages are manually installed, but do not need to be, because they are being pulled as dependencies by other packages. With the -a flag marks these manually installed dependencies as automatically installed.


## Metapackages (OUTDATED, may be updated at an unspecified date in the future)
The metapackage folder contains metapackages aimed at Ubuntu based systems.
These depend on the essential system packages, tools, games, etc.
Installing them will allow you to keep a very short list of manually installed packages (only them) and easily keep track of new packages that you install on a system afterwards.
Example of output from `scripts/manually-installed.sh` on my system (Ubuntu 17.10 with GNOME):
```
bleachbit
dconf-editor
lagerspetz-meta-desktop
lagerspetz-meta-games
lagerspetz-meta-tools
netext73
python3-pip
python3-tables
```
Build these metapackages using `dpkg --build name-of-directory` in the metapackage folder.
