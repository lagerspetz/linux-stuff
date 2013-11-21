#!/bin/bash
# Generate a list of manually installed dependencies on this system
# with parameter -a, mark them autoinstalled

if [ -n "$1" -a "$1" == "-a" ]; then
    deps=$( aptitude search "?installed?not(?automatic)?reverse-depends(?installed?not(?automatic))" -F "%p" )
    sudo aptitude markauto $deps
else
    aptitude search "?installed?not(?automatic)?reverse-depends(?installed?not(?automatic))"
fi
