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
ROOTSTEMP=/tmp/root.hints

# location to implant root.hints file
ROOTSFILE=/var/lib/unbound/root.hints

# Pi-hole installation detection
PIHOLEDIR=/etc/pihole
PIHOLECONF="${PIHOLEDIR}/setupVars.conf"

# unbound config file
UNBOUNDHOLECONF=/etc/unbound/unbound.conf.d/pi-hole.conf
UNBOUNDHOLECONFTEMP=/tmp/pi-hole.conf
UNBOUNDHOLECONFURL=https://raw.githubusercontent.com/deathbybandaid/Unbound-hole/master/pi-hole.conf

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
echo "Installing root.hints file"
if [[ -f $ROOTSFILE ]]
then
  echo "Checking existing file"
  SOURCEMODIFIEDLAST=$(curl --silent --head $ROOTSURL | awk -F: '/^Last-Modified/ { print $2 }')
  SOURCEMODIFIEDTIME=$(date --date="$SOURCEMODIFIEDLAST" +%s)
  LOCALFILEMODIFIEDLAST=$(stat -c %z "$ROOTSFILE")
  LOCALFILEMODIFIEDTIME=$(date --date="$LOCALFILEMODIFIEDLAST" +%s)
  if [[ $LOCALFILEMODIFIEDTIME -lt $SOURCEMODIFIEDTIME ]]
  then
    DOWNLOADFRESHROOTS=true
    echo "File updated online"
  else
    echo "File not updated online"
  fi
else
  DOWNLOADFRESHROOTS=true
  echo "File Missing"
fi


if [[ $DOWNLOADFRESHROOTS = true ]]
then
  echo "Attempting to download file"
  wget -O $ROOTSTEMP $ROOTSURL
  FETCHFILESIZE=$(stat -c%s $ROOTSTEMP)
  if [[ $FETCHFILESIZE -gt 0 ]]
  then
     mv $ROOTSTEMP $ROOTSFILE
  else
    echo "File download failed"
  fi
else
  echo "Not downloading file"
fi

# Install unbound config file
echo "Installing config file"
if [[ -f $UNBOUNDHOLECONF ]]
then
  echo "Checking existing file"
  SOURCEMODIFIEDLAST=$(curl --silent --head $UNBOUNDHOLECONFURL | awk -F: '/^Last-Modified/ { print $2 }')
  SOURCEMODIFIEDTIME=$(date --date="$SOURCEMODIFIEDLAST" +%s)
  LOCALFILEMODIFIEDLAST=$(stat -c %z "$UNBOUNDHOLECONF")
  LOCALFILEMODIFIEDTIME=$(date --date="$LOCALFILEMODIFIEDLAST" +%s)
  if [[ $LOCALFILEMODIFIEDTIME -lt $SOURCEMODIFIEDTIME ]]
  then
    DOWNLOADFRESHCONF=true
    echo "File updated online"
  else
    echo "File not updated online"
  fi
else
  DOWNLOADFRESHCONF=true
  echo "File Missing"
fi


if [[ $DOWNLOADFRESHCONF = true ]]
then
  echo "Attempting to download file"
  wget -O $UNBOUNDHOLECONFTEMP $UNBOUNDHOLECONFURL
  FETCHFILESIZE=$(stat -c%s $UNBOUNDHOLECONFTEMP)
  if [[ $FETCHFILESIZE -gt 0 ]]
  then
     mv $UNBOUNDHOLECONFTEMP $UNBOUNDHOLECONF
  else
    echo "File download failed"
  fi
else
  echo "Not downloading file"
fi
