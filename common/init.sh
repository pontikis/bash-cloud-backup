#!/bin/bash
#-------------------------------------------------------------------------------
# SCRIPT.........: init.sh
# ACTION.........: bash-cloud-backup common tasks and utility functions
# COPYRIGHT......: Christos Pontikis - http://www.pontikis.gr
# LICENSE........: MIT (see https://opensource.org/licenses/MIT)
# DOCUMENTATION..: See README for instructions
#-------------------------------------------------------------------------------

# create backup directories in case they do not exist
if [ ! -d "$backuproot" ]; then $MKDIR -p $backuproot; fi
if [ ! -d "$backuproot/$dir_www" ]; then $MKDIR $backuproot/$dir_www; fi
if [ ! -d "$backuproot/$dir_mysql" ]; then $MKDIR $backuproot/$dir_mysql; fi
if [ ! -d "$backuproot/$dir_conf" ]; then $MKDIR $backuproot/$dir_conf; fi
if [ ! -d "$backuproot/$dir_scripts" ]; then $MKDIR $backuproot/$dir_scripts; fi
if [ ! -d "$backuproot/$dir_docs" ]; then $MKDIR $backuproot/$dir_docs; fi

# define log file
logfile="$logfilepath/$logfilename"

# create log directory in case it does not exist
if [ ! -d "$logfilepath" ]; then $MKDIR -p $logfilepath; fi

# Utility Functions ------------------------------------------------------------
function createlog {
      dt=`$DATE "+%Y-%m-%d %H:%M:%S"`
      logline="$dt | $1"
      echo -e $logline;
      echo -e $logline >> $logfile
}


function rotate_delete {

    dir_to_find=$1;
    files_per_backup=$2;

    if [ $days_rotation -le 0 ]; then
        createlog "---rotating delete IS DISABLED..."
    else
        total_backups=`$FIND $dir_to_find -maxdepth 1 -type f | $WC -l`
        total_backups=$(( $total_backups/$files_per_backup ))
        if [ $total_backups -lt $days_rotation ]; then
            createlog "---not enough backups ($total_backups) - no time for rotating delete..."
        else
            backups_to_keep=`$FIND $dir_to_find -maxdepth 1 -type f  -mtime -$days_rotation  | $WC -l`
            backups_to_keep=$(( $backups_to_keep/$files_per_backup ))

            if [ $backups_to_keep -ge $backups_to_keep_at_least ]; then
                createlog "---rotating delete..."
                $FIND $currentdir -mtime +$days_rotation -exec $RM {} -f \;
            else
                createlog "---not enough recent backups ($backups_to_keep) - rotating delete IS ABORTED..."
            fi
        fi
    fi
}