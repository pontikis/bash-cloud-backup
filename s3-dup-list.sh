#!/bin/bash

if [ $# -lt 1 ]; then echo "Usage $0 <s3-url>"; exit; fi

scriptpath=`dirname "$0"`
if [ $scriptpath = "." ]; then scriptpath=''; else scriptpath=${scriptpath}/; fi

# include initialize script
source ${scriptpath}conf/initialize.sh s3_dup

echo "Waiting for $1..."

$DUPLICITY list-current-files $1

export PASSPHRASE=
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=