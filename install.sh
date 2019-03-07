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
  echo "File already exists"
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
     echo "File download success"
  else
    echo "File download failed"
    exit 1
  fi
else
  echo "Not downloading file"
fi

if [[ $DOWNLOADFRESHCONF = true ]]
then
  # adapt the configuration
  echo "adjusting config based on Pi-hole"


  if [[ $IPV4_ADDRESS ]]
  then
    echo "IPv4 is setup"
  else
    echo "IPv4 is not setup"
    sed -i s/do-ip4\:[[:space:]]yes/do-ip4\:[[:space:]]no/ $UNBOUNDHOLECONFTEMP
  fi


  if [[ $IPV6_ADDRESS ]]
  then
    echo "IPv6 is setup"
    sed -i s/do-ip4\:[[:space:]]no/do-ip4\:[[:space:]]yes/ $UNBOUNDHOLECONFTEMP
  else
    echo "IPv6 is not setup"
  fi

  # move config file
  mv $UNBOUNDHOLECONFTEMP $UNBOUNDHOLECONF
fi

echo "Starting Unbound with Pi-hole Config"
service unbound stop
service unbound start

# Test Config on IPv4
if [[ $IPV4_ADDRESS  ]]
then
  echo "Testing IPv4 configuration"
fi


# Test Config on IPv6
if [[ $IPV6_ADDRESS  ]]
then
  echo "Testing IPv6 configuration"
fi

