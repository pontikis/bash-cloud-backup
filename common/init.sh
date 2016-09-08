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
if [ -n "$dir_www" ]; then
if [ ! -d "$backuproot/$dir_www" ]; then $MKDIR $backuproot/$dir_www; fi
fi
if [ -n "$dir_mysql" ]; then
if [ ! -d "$backuproot/$dir_mysql" ]; then $MKDIR $backuproot/$dir_mysql; fi
fi
if [ -n "$dir_conf" ]; then
if [ ! -d "$backuproot/$dir_conf" ]; then $MKDIR $backuproot/$dir_conf; fi
fi
if [ -n "$dir_scripts" ]; then
if [ ! -d "$backuproot/$dir_scripts" ]; then $MKDIR $backuproot/$dir_scripts; fi
fi
if [ -n "$dir_docs" ]; then
if [ ! -d "$backuproot/$dir_docs" ]; then $MKDIR $backuproot/$dir_docs; fi
fi

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

function zip_file {

    file_to_zip=$1;

    if [ $use_7z -eq 1 ]; then
        createlog "---7zip $file_to_zip..."
        $cmd_7z "$file_to_zip.$filetype_7z" $file_to_zip 2>&1 | $TEE -a $logfile
        $RM -f $file_to_zip
    else
        createlog "---zip $file_to_zip..."
        $GZIP -9 -f $file_to_zip 2>&1 | $TEE -a $logfile
    fi

}

function rotate_delete {

    dir_to_find=$1;
    files_per_backup=$2;

    if [ $days_rotation -le 0 ]; then
        msg="---rotating delete IS DISABLED..."
        do_rotate_delete=0
    else
        if [ $min_backups_in_rotation_period -eq 0 ] || [ $min_backups_in_rotation_period -gt $days_rotation ]; then
            msg="---rotating delete (without checking number of recent backups):"
            do_rotate_delete=1
        else
            total_backups=`$FIND $dir_to_find -maxdepth 1 -type f | $WC -l`
            total_backups=$(( $total_backups/$files_per_backup ))
            if [ $total_backups -le $days_rotation ]; then
                msg="---not enough backups ($total_backups) - no time for rotating delete..."
                do_rotate_delete=0
            else
                backups_in_rotation_period=`$FIND $dir_to_find -maxdepth 1 -type f -mtime -$days_rotation | $WC -l`
                backups_in_rotation_period=$(( $backups_in_rotation_period/$files_per_backup ))
                if [ $backups_in_rotation_period -ge $min_backups_in_rotation_period ]; then
                    msg="---rotating delete..."
                    do_rotate_delete=1
                else
                    msg="---not enough recent backups ($backups_in_rotation_period) - rotating delete IS ABORTED..."
                    do_rotate_delete=0
                fi
            fi
        fi
    fi

    createlog "$msg"
    if [ $do_rotate_delete -eq 1 ]; then

        backups_to_delete=`$FIND $dir_to_find -maxdepth 1 -type f -mtime +$days_rotation | $WC -l`
        backups_to_delete=$(( $backups_to_delete/$files_per_backup ))

        if [ $backups_to_delete -gt 0 ]; then
            createlog "$backups_to_delete backups will ne deleted:"
            2del_out=$($FIND $dir_to_find -mtime +$days_rotation 2>&1 | $SORT)
            echo $2del_out 2>&1 | $TEE -a $logfile
            # proceed to deletion
            $FIND $dir_to_find -mtime +$days_rotation -exec $RM {} -f \;
            if [ $? -eq 0 ]
            then
                createlog "---Rotating delete completed successfully."
            else
                createlog "---ERROR: rotating delete failed..."
            fi
        else
            createlog "No backups will ne deleted."
        fi

    fi

}