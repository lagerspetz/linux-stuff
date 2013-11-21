#!/bin/bash
# Generate a list of manually installed pkgs on this system.
aptitude search "?installed?not(?automatic)" | awk '{ print $2, "install" }'
