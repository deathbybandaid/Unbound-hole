#!/bin/bash

SOURCEURL=https://www.internic.net/domain/named.root

CURRENTFILE=/var/lib/unbound/root.hints
TEMPFILE=/home/root.hints


SOURCEMODIFIEDLAST=$(curl --silent --head $SOURCEURL | awk -F: '/^Last-Modified/ { print $2 }')
SOURCEMODIFIEDTIME=$(date --date="$SOURCEMODIFIEDLAST" +%s)

LOCALFILEMODIFIEDLAST=$(stat -c %z "$CURRENTFILE")
LOCALFILEMODIFIEDTIME=$(date --date="$LOCALFILEMODIFIEDLAST" +%s)

if [[ $LOCALFILEMODIFIEDTIME -lt $SOURCEMODIFIEDTIME ]]
then
  wget -O $TEMPFILE $SOURCEURL
  FETCHFILESIZE=$(stat -c%s $TEMPFILE)
  if [[ $FETCHFILESIZE -gt 0 ]]
  then
     mv $TEMPFILE $CURRENTFILE
  fi
fi
