#!/bin/bash
# Generate a list of manually installed pkgs on this system.
aptitude search "?installed?not(?automatic)" -F "%p" | awk '{ print $1, "install" }'
