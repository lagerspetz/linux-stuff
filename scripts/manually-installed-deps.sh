#!/bin/bash
# Generate a list of manually installed dependencies on this system
# with parameter -a, mark them autoinstalled

if [ -n "$1" -a "$1" == "-h" -o "$1" == "--help" ]; then
  echo "Usage: manually-installed-deps.sh [-a|-f]
    -a will mark automatically installed any package depending on a manually installed package.
    -f will mark automatically installed any package depending on an installed package.
"
elif [ -n "$1" -a "$1" == "-f" ]; then
    deps=$( aptitude search "?installed?not(?automatic)?reverse-depends(?installed)" -F "%p" )
    sudo aptitude markauto $deps
elif [ -n "$1" -a "$1" == "-a" ]; then
    deps=$( aptitude search "?installed?not(?automatic)?reverse-depends(?installed?not(?automatic))" -F "%p" )
    sudo aptitude markauto $deps
else
    aptitude search "?installed?not(?automatic)?reverse-depends(?installed?not(?automatic))"
fi
