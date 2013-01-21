#!/bin/bash
TMPFILE=`tempfile`
PTH="$2"
wget "$1" -O $TMPFILE
unzip  -n -d $PTH $TMPFILE
rm $TMPFILE