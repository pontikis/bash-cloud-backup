#!/bin/bash

scriptpath=`dirname "$0"`
if [ $scriptpath = "." ]; then scriptpath=''; else scriptpath=${scriptpath}/; fi

# include initialize script
source ${scriptpath}conf/initialize.sh s3_plain

# attention: / is important to copy only the contents of $backuproot
SOURCE="$backuproot/";
DEST=$s3_plain_path

$S3CMD sync $S3CMD_SYNC_PARAMS $SOURCE $DEST 2>&1 | $TEE -a $logfile
