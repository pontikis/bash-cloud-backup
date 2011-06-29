#!/bin/bash

scriptpath=`dirname "$0"`
if [ $scriptpath = "." ]; then scriptpath=''; else scriptpath=${scriptpath}/; fi

# include initialize script
source ${scriptpath}conf/initialize.sh s3_dup

# The source of your backup
SOURCE=/

# Select a unique name for your bucket below.
DEST=$s3_dup_path

# Delete any older than 1 month
$DUPLICITY remove-older-than $remove_older_than ${DEST}

# Make the regular backup
# Will be a full backup if past the older-than parameter
$DUPLICITY \
	--full-if-older-than $full_if_older_than \
	--include=$backuproot \
	--exclude=/** \
	${SOURCE} ${DEST}

export PASSPHRASE=
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
