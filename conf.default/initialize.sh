#!/bin/bash

#-------------------------------------
# SCRIPT.........: initialize
# ACTION.........: Initialize variables for backup scripts
# CREATED BY.....: Christos Pontikis (http://www.medisign.gr)
# COPYRIGHT......: MediSign SA (http://www.medisign.gr)
# LICENSE........: GNU General Public License (see http://www.gnu.org/copyleft/gpl.html)
# DOCUMENTATION..: See README for instructions
#-------------------------------------

FIND="$(which find)"
TAR="$(which tar)"
GZIP="$(which gzip)"
DATE="$(which date)"
CHMOD="$(which chmod)"
MKDIR="$(which mkdir)"
RM="$(which rm)"

cmd_7z="$(which 7z) a -pYOUR_PASSWORD_HERE -mx=9 -mm=Deflate -mem=AES256 -tzip"
use_7z=1

MYSQLDUMP="$(which mysqldump)"

S3CMD="$(which s3cmd)"
DUPLICITY="$(which duplicity)"

# !!! P L E A S E  C O M P L E T E  Y O U R  O W N  D A T A!

days_rotation=14
backuproot='/root/backup'

# make backup directories in case they do not exist
if [ ! -d "$backuproot" ]; then $MKDIR -p $backuproot; fi

# define variables 
logfile="$backuproot/log/backup.log"

# make backup directories in case they do not exist
if [ ! -d "$backuproot/log" ]; then $MKDIR $backuproot/log; fi


case $1 in
www)
    # define variables 
    dir_www='www'
    all_prefix_www='www'
    wwwroot='/var/www/'

    # make backup directories in case they do not exist
    if [ ! -d "$backuproot/$dir_www" ]; then $MKDIR $backuproot/$dir_www; fi
  ;;
mysql)
    # define variables 
    dir_mysql='mysql'
    all_prefix_mysql='mysql'
    mysql_user='username_here'
    mysql_password='password_here'

    # make backup directories in case they do not exist
    if [ ! -d "$backuproot/$dir_mysql" ]; then $MKDIR $backuproot/$dir_mysql; fi
  ;;
conf)
    # define variables 
    dir_conf='conf'

    # make backup directories in case they do not exist
    if [ ! -d "$backuproot/$dir_conf" ]; then $MKDIR $backuproot/$dir_conf; fi
  ;;
scripts)
    # define variables 
    dir_scripts='scripts'

    # make backup directories in case they do not exist
    if [ ! -d "$backuproot/$dir_scripts" ]; then $MKDIR $backuproot/$dir_scripts; fi
  ;;
svn)
    # define variables
    dir_svn='svn'
    all_prefix_svn='svn'
    svn_path='/usr/local/svn'
    svn_hot_backup_py_path='/usr/share/doc/subversion-1.2.3/tools/backup'

    # make backup directories in case they do not exist
    if [ ! -d "$backuproot/$dir_svn" ]; then $MKDIR $backuproot/$dir_svn; fi
  ;;
otrs)
    # define variables
    dir_otrs='otrs'

    otrs_internal_bkp='/opt/otrs/scripts/backup.pl'

    # make backup directories in case they do not exist
    if [ ! -d "$backuproot/$dir_otrs" ]; then $MKDIR $backuproot/$dir_otrs; fi
  ;;
s3_plain)
    # define variables
    use_s3_server_encryption=1
    s3_plain_path='s3://bucket_name/path/to/plain_backup/'
  ;;
s3_dup)
    # define variables
    s3_dup_path='s3+http://bucket_name/path/to/duplicity_backup/'

    remove_older_than='1M';
    full_if_older_than='14D';

    export PASSPHRASE="YOUR_PASSPHRASE"
    export AWS_ACCESS_KEY_ID=YOUR_AWS_ACCESS_KEY_ID
    export AWS_SECRET_ACCESS_KEY=YOUR_AWS_SECRET_ACCESS_KEY

  ;;
esac

# GET START TIME
if [ ${#start} -eq 0 ]; then    # var start has no value
  start=`$DATE "+%Y-%m-%d %H:%M:%S"`
fi

# UDF .............................................
function createlog {
      dt=`$DATE "+%Y-%m-%d %H:%M:%S"`
      logline="$start | $dt | $1"
      echo -e $logline; echo -e $logline >> $logfile
}