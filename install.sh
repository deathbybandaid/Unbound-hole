#!/usr/bin/env bash
# shellcheck disable=SC1090

# Unbound-hole: A plugin for Pi-hole
# Take Additional control of your DNS

# Please donate to the Pi-hole project at pi-hole.net/donate
#
# Pi-hole can be installed by running:
# curl -sSL https://install.pi-hole.net | bash

######## VARIABLES #########

# URL to download root.hints file from internic
ROOTSURL=https://www.internic.net/domain/named.root

# temporary download location for root.hints
TEMPROOTS=/tmp/root.hints

# Pi-hole installation detection
PIHOLEDIR=

# Prompt user to install Pi-hole if not already
if [[ -f $PIHOLEDIR ]]
then
  echo "Pi-hole detected, proceding with the install!"
else
  echo "grr"
fi

CURRENTFILE=/var/lib/unbound/root.hints
TEMPFILE=/tmp/root.hints

sudo apt install unbound

wget -O root.hints https://www.internic.net/domain/named.root
sudo mv root.hints /var/lib/unbound/

/etc/unbound/unbound.conf.d/pi-hole.conf

sudo service unbound start
