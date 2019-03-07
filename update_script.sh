#!/bin/bash

ROOTSURL=https://www.internic.net/domain/named.root
CURRENTFILE=/var/lib/unbound/root.hints
TEMPFILE=/tmp/root.hints
DOWNLOADFRESH=false

if [[ -f $CURRENTFILE ]]
then
  echo "Checking existing file"
  SOURCEMODIFIEDLAST=$(curl --silent --head $ROOTSURL | awk -F: '/^Last-Modified/ { print $2 }')
  SOURCEMODIFIEDTIME=$(date --date="$SOURCEMODIFIEDLAST" +%s)
  LOCALFILEMODIFIEDLAST=$(stat -c %z "$CURRENTFILE")
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
  wget -O $TEMPFILE $ROOTSURL
  FETCHFILESIZE=$(stat -c%s $TEMPFILE)
  if [[ $FETCHFILESIZE -gt 0 ]]
  then
     mv $TEMPFILE $CURRENTFILE
  else
    echo "File download failed"
  fi
else
  echo "Not downloading file"
fi
