#!/usr/bin/env bash
# shellcheck disable=SC1090

# Unbound-hole: A plugin for Pi-hole
# Take Additional control of your DNS

# Please donate to the Pi-hole project at pi-hole.net/donate
#
# Pi-hole can be installed by running:
# curl -sSL https://install.pi-hole.net | bash

# error handling
set -e

######## VARIABLES #########

# URL to download root.hints file from internic
ROOTSURL=https://www.internic.net/domain/named.root

# temporary download location for root.hints
TEMPROOTS=/tmp/root.hints

# Pi-hole installation detection
PIHOLEDIR=/etc/pihole

# Prompt user to install Pi-hole if not already
if [[ -d $PIHOLEDIR ]]
then
  echo "Pi-hole detected, proceding with the install!"
else
  echo "Pi-hole not detected, exitting."
  exit 1
fi
