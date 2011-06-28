#!/bin/bash

if [ $# -lt 4 ]; then echo "Usage $0 <s3+http://bucket_name/path/to/duplicity_archives/> <date> <file> <restore-to>"; exit; fi

scriptpath=`dirname "$0"`
if [ $scriptpath = "." ]; then scriptpath=''; else scriptpath=${scriptpath}/; fi

# include initialize script
source ${scriptpath}conf/initialize.sh s3_dup

echo "Getting $3 $2 from $1 at $4..."

# Select a unique name for your bucket below.
DEST=$1

$DUPLICITY \
    --file-to-restore $3 \
    --restore-time $2 \
    ${DEST} $4

export PASSPHRASE=
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
