#!/bin/bash

scriptpath=`dirname "$0"`
if [ $scriptpath = "." ]; then scriptpath=''; else scriptpath=${scriptpath}/; fi

# include initialize script
source ${scriptpath}conf/initialize.sh s3_plain

# attention: / is important to copy only the contents of $backuproot
SOURCE="$backuproot/";
DEST=$s3_plain_path
ENCR=""
if [ $use_s3_server_encryption -eq 1 ]; then ENCR="--add-header=x-amz-server-side-encryption:AES256"; fi

$S3CMD sync $S3CMD_SYNC_params $ENCR $SOURCE $DEST

