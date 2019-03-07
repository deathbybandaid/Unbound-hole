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

# location to implant root.hints file
CURRENTROOTS=/var/lib/unbound/root.hints

# Pi-hole installation detection
PIHOLEDIR=/etc/pihole
PIHOLECONF="${PIHOLEDIR}/setupVars.conf"

# Prompt user to install Pi-hole if not already
if [[ -d $PIHOLEDIR ]]
then
  echo "Pi-hole detected, proceding with the install!"
else
  echo "Pi-hole not detected, exitting."
  exit 1
fi

# Prompt user to install Pi-hole if not already
if [[ -f $PIHOLECONF ]]
then
  echo "Pi-hole config detected, proceding with the install!"
else
  echo "Pi-hole config not detected, exitting."
  exit 1
fi

# Pull Pi-hole setup vars
source $PIHOLECONF

# Install unbound
if which unbound >/dev/null;
then
  echo "Unbound is already installed"
else
  echo "Installing Unbound"
  apt-get install -y unbound
fi

# Install root.hints file
if [[ -f $CURRENTROOTS ]]
then
  echo "Checking existing file"
  SOURCEMODIFIEDLAST=$(curl --silent --head $ROOTSURL | awk -F: '/^Last-Modified/ { print $2 }')
  SOURCEMODIFIEDTIME=$(date --date="$SOURCEMODIFIEDLAST" +%s)
  LOCALFILEMODIFIEDLAST=$(stat -c %z "$CURRENTROOTS")
  LOCALFILEMODIFIEDTIME=$(date --date="$LOCALFILEMODIFIEDLAST" +%s)
  if [[ $LOCALFILEMODIFIEDTIME -lt $SOURCEMODIFIEDTIME ]]
  then
    DOWNLOADFRESH=true
    echo "File updated online"
  else
    echo "File not updated online"
  fi
else
  DOWNLOADFRESH=true
  echo "File Missing"
fi


if [[ $DOWNLOADFRESH = true ]]
then
  echo "Attempting to download file"
  wget -O $TEMPROOTS $ROOTSURL
  FETCHFILESIZE=$(stat -c%s $TEMPROOTS)
  if [[ $FETCHFILESIZE -gt 0 ]]
  then
     mv $TEMPROOTS $CURRENTROOTS
  else
    echo "File download failed"
  fi
else
  echo "Not downloading file"
fi
