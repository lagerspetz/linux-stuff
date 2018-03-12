# Linux Stuff by Lagerspetz

This repo contains useful linux scripts.
No guarantee that they work or warranty of
any kind is given. Some highlights:

## Saferm.sh
* `scripts/saferm.sh`: alias this to "rm". Moves files to your desktop environment's trash folder instead of permanently deleting files when you type "rm".

* `scripts/manually-installed.sh`: Shows the list of manually installed (deb) packages on the system. Useful for keeping track of what is installed.

* `scripts-manually-installed-deps.sh`: Shows which packages are manually installed, but do not need to be, because they are being pulled as dependencies by other packages. With the -a flag marks these manually installed dependencies as automatically installed.


## Metapackages
The metapackage folder contains metapackages aimed at Ubuntu based systems.
These depend on the essential system packages, tools, games, etc.
Installing them will allow you to keep a very short list of manually installed packages (only them) and easily keep track of new packages that you install on a system afterwards.
Build using `dpkg --build name-of-directory` in the metapackage folder.
