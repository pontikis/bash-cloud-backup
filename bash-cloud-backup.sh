#!/usr/bin/env bash
#-------------------------------------------------------------------------------
# SCRIPT.........: bash-cloud-backup.sh
# ACTION.........: bash-cloud-backup is a bash script, which can be used to automate local and cloud backup in Linux/Unix machines.
# COPYRIGHT......: Christos Pontikis - http://www.pontikis.gr
# LICENSE........: MIT (see https://opensource.org/licenses/MIT)
# PROJECT PAGE...: https://github.com/pontikis/bash-cloud-backup
# DOCUMENTATION..: See README.md for instructions
#                  See /conf.default for sample configuration files
#-------------------------------------------------------------------------------

# Linux commands ---------------------------------------------------------------
FIND="$(which find)"
TAR="$(which tar)"
CMD7Z="$(which 7z)"
GZIP="$(which gzip)"
DATE="$(which date)"
CHMOD="$(which chmod)"
MKDIR="$(which mkdir)"
RM="$(which rm)"
TEE="$(which tee)"
WC="$(which wc)"
SORT="$(which sort)"
SED="$(which sed)"
GREP="$(which grep)"
TR="$(which tr)"
MYSQLDUMP="$(which mysqldump)"
S3CMD="$(which s3cmd)"
CAT="$(which cat)"

# Get start time ---------------------------------------------------------------
START=$($DATE +"%s")

# Script path ------------------------------------------------------------------
scriptpath=`dirname "$0"`
if [ $scriptpath = "." ]; then scriptpath=''; else scriptpath=${scriptpath}/; fi

# Initialize configuration files -----------------------------------------------
global_conf="/etc/bash-cloud-backup/global.conf"
backup_conf="/etc/bash-cloud-backup/backup.conf"

while getopts ":g:b:" opt; do
    case "$opt" in
        g)
            global_conf=$OPTARG
            ;;
        b)
            backup_conf=$OPTARG
            ;;
        '?')
            echo "FATAL ERROR: invalid options..."
            exit 1
            ;;
    esac
done

if [ ! -f "$global_conf" ]
then
    echo "FATAL ERROR: global configuration file $global_conf does not exist..."
    exit 1
fi

if [ ! -f "$backup_conf" ]
then
    echo "FATAL ERROR: backup configuration file $backup_conf does not exist..."
    exit 1
fi

# get version ------------------------------------------------------------------
version=`$CAT ${scriptpath}VERSION`

# parse backup sections (SPACES NOT PERMITTED) ---------------------------------
sections=( $($SED 's/^[ ]*//g' $backup_conf  | $GREP '^\[.*.\]$' |$TR  -d '^[]$') )

# get global configuration -----------------------------------------------------
backuproot=$(crudini --get "$global_conf" '' backuproot)
hostname=$(crudini --get "$global_conf" '' hostname)
logfilepath=$(crudini --get "$global_conf" '' logfilepath)
logfilename=$(crudini --get "$global_conf" '' logfilename)
log_separator=$(crudini --get "$global_conf" '' log_separator)
log_top_separator=$(crudini --get "$global_conf" '' log_top_separator)

use_7z=$(crudini --get "$global_conf" '' use_7z)
if [ $use_7z -eq 1 ]; then
    passwd_7z=$(crudini --get "$global_conf" '' passwd_7z)
    filetype_7z=$(crudini --get "$global_conf" '' filetype_7z)
    if [ "$filetype_7z" == '7z' ]; then
        cmd_7z="$CMD7Z a -p$passwd_7z -mx=9 -mhe -t7z"
    elif [ "$filetype_7z" == 'zip' ]; then
        cmd_7z="$CMD7Z a -p$passwd_7z -mx=9 -mm=Deflate -mem=AES256 -tzip"
    else
        use_7z=0
    fi
fi

days_rotation=$(crudini --get "$global_conf" '' days_rotation)
min_backups_in_rotation_period=$(crudini --get "$global_conf" '' min_backups_in_rotation_period)

s3_sync=$(crudini --get "$global_conf" '' s3_sync)
s3_path=$(crudini --get "$global_conf" '' s3_path)
s3cmd_sync_params=$(crudini --get "$global_conf" '' s3cmd_sync_params)

# create log directory in case it does not exist
if [ ! -d "$logfilepath" ]; then $MKDIR -p $logfilepath; fi
# define log file
logfile="$logfilepath/$logfilename"

# Utility Functions ------------------------------------------------------------
function createlog {
      dt=`$DATE "+%Y-%m-%d %H:%M:%S"`
      logline="$dt | $1"
      echo -e $logline 2>&1 | $TEE -a $logfile
}

function zip_file {

    file_to_zip=$1;

    if [ $use_7z -eq 1 ]; then
        createlog "7zip $file_to_zip..."
        $cmd_7z "$file_to_zip.$filetype_7z" $file_to_zip 2>&1 | $TEE -a $logfile
        $RM -f $file_to_zip
    else
        createlog "gzip $file_to_zip..."
        $GZIP -9 -f $file_to_zip 2>&1 | $TEE -a $logfile
    fi

}

function rotate_delete {

    dir_to_find=$1;
    files_per_backup=$2;

    if [ $days_rotation -le 0 ]; then
        msg="Rotating delete IS DISABLED..."
        do_rotate_delete=0
    else
        if [ $min_backups_in_rotation_period -eq 0 ] || [ $min_backups_in_rotation_period -gt $days_rotation ]; then
            msg="Rotating delete (without checking number of recent backups):"
            do_rotate_delete=1
        else
            total_backups=`$FIND $dir_to_find -maxdepth 1 -type f | $WC -l`
            total_backups=$(( $total_backups/$files_per_backup ))
            if [ $total_backups -le $days_rotation ]; then
                msg="Not enough backups ($total_backups) - no time for rotating delete..."
                do_rotate_delete=0
            else
                backups_in_rotation_period=`$FIND $dir_to_find -maxdepth 1 -type f -mtime -$days_rotation | $WC -l`
                backups_in_rotation_period=$(( $backups_in_rotation_period/$files_per_backup ))
                if [ $backups_in_rotation_period -ge $min_backups_in_rotation_period ]; then
                    msg="Rotating delete..."
                    do_rotate_delete=1
                else
                    msg="Not enough recent backups ($backups_in_rotation_period) - rotating delete IS ABORTED..."
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
            $FIND $dir_to_find -mtime +$days_rotation | $SORT 2>&1 | $TEE -a $logfile

            # proceed to deletion
            $FIND $dir_to_find -mtime +$days_rotation -exec $RM {} -f \;
            if [ $? -eq 0 ]
            then
                createlog "Rotating delete completed successfully."
            else
                createlog "ERROR: rotating delete failed..."
            fi
        else
            createlog "No backups will ne deleted."
        fi

    fi

}

# perform backup ---------------------------------------------------------------
if [ -z "$hostname" ]; then onhost=''; else onhost=" on $hostname"; fi
createlog "bash-cloud-backup (version $version)$onhost is starting..."

for (( i=0; i<${#sections[@]}; i++ ));

do

    section=${sections[i]};

    # get backup section properties (common for all types)
    type=$(crudini --get "$backup_conf" "$section" type)
    path=$(crudini --get "$backup_conf" "$section" path)
    prefix=$(crudini --get "$backup_conf" "$section" prefix)
    starting_message=$(crudini --get "$backup_conf" "$section" starting_message)
    finish_message=$(crudini --get "$backup_conf" "$section" finish_message)

    echo -e "\n$log_separator" 2>&1 | $TEE -a $logfile
    createlog "$starting_message"

    currentdir="$backuproot/$path"
    if [ ! -d $currentdir ]; then $MKDIR -p $currentdir; fi

    if [ "$type" == 'files' ]; then

        # get specific properties of section with type = 'files'
        fileset=$(crudini --get "$backup_conf" "$section" fileset)
        delimiter=$(crudini --get "$backup_conf" "$section" delimiter)

        tar_options_backup_list=$(crudini --get "$backup_conf" "$section" tar_options_backup_list)
        if [ -z "$tar_options_backup_list" ]; then tar_options_backup_list=$(crudini --get "$global_conf" '' tar_options_backup_list); fi

        tar_options_backup_file=$(crudini --get "$backup_conf" "$section" tar_options_backup_file)
        if [ -z "$tar_options_backup_file" ]; then tar_options_backup_file=$(crudini --get "$global_conf" '' tar_options_backup_file); fi

        # create temp dir to store backup_list
        tmpdir=$currentdir/tmp
        if [ -d $tmpdir ]; then $RM -rf $tmpdir; fi
        $MKDIR $tmpdir;

        # create backup list from file set
        createlog "Creating backup list..."
        IFS=$delimiter read -r -a afiles <<< "$fileset"
        for element in "${afiles[@]}"
        do
            $FIND $element -type f >> $tmpdir/backup_list
        done

        # tar files
        dt=`$DATE +%Y%m%d.%H%M%S`
        listfile=$currentdir/$prefix-$dt-list.tar
        bkpfile=$currentdir/$prefix-$dt.tar
        createlog "Creating tar $listfile..."
        createlog "tar options: $tar_options_backup_list..."
        $TAR $tar_options_backup_list $listfile $tmpdir/backup_list > /dev/null
        createlog "Creating tar $bkpfile..."
        createlog "tar options: $tar_options_backup_file..."
        $TAR $tar_options_backup_file $bkpfile -T $tmpdir/backup_list > /dev/null

        # compress (and encrypt) files
        zip_file $listfile
        zip_file $bkpfile

        # rotating delete
        rotate_delete $currentdir 2

    elif [ "$section_type" == 'mysql' ]; then

        # get specific properties of section with type = 'files'
        database=$(crudini --get "$backup_conf" "$section" database)

        mysql_user=$(crudini --get "$backup_conf" "$section" mysql_user)
        if [ -z "$mysql_user" ]; then mysql_user=$(crudini --get "$global_conf" '' mysql_user); fi

        mysql_password=$(crudini --get "$backup_conf" "$section" mysql_password)
        if [ -z "$mysql_password" ]; then mysql_password=$(crudini --get "$global_conf" '' mysql_password); fi

        # export mysql database with data using mysqldump
        dt=`$DATE +%Y%m%d.%H%M%S`
        bkpfile=$currentdir/$prefix-$dt.sql
        createlog "mysqldump $bkpfile..."
        $MYSQLDUMP -u$mysql_user -p$mysql_password $database > $bkpfile

        # compress file
        zip_file $bkpfile

        # rotating delete
        rotate_delete $currentdir 1

    else
        echo -e "\n$log_separator" 2>&1 | $TEE -a $logfile
        createlog "ERROR: Unknown backup type. $section is ingored..."
    fi

    createlog "$finish_message"
done

# Custom commands --------------------------------------------------------------
custom_script=${scriptpath}custom.sh
if [ -f "$custom_script" ]; then source $custom_script; fi

# Amazon S3 sync ---------------------------------------------------------------
if [ $s3_sync -eq 1 ]; then

    s3_path=$(crudini --get "$global_conf" '' s3_path)
    s3cmd_sync_params=$(crudini --get "$global_conf" '' s3cmd_sync_params)

    echo -e "\n$log_separator" 2>&1 | $TEE -a $logfile
    createlog "Amazon S3 sync is starting..."

    # attention: / is important to copy only the contents of $backuproot
    S3_SOURCE="$backuproot/"
    S3_DEST=$s3_path

    $S3CMD sync $s3cmd_sync_params $S3_SOURCE $S3_DEST 2>&1 | $TEE -a $logfile

    createlog "Amazon S3 sync completed."
fi

# Finish -----------------------------------------------------------------------
END=$($DATE +"%s")
DIFF=$(($END-$START))
ELAPSED="$(($DIFF / 60)) minutes and $(($DIFF % 60)) seconds elapsed."

echo -e "\n$log_separator" 2>&1 | $TEE -a $logfile
createlog "bash-cloud-backup (version $version) completed."
echo "$ELAPSED"  2>&1 | $TEE -a $logfile
echo -e "\n$log_top_separator\n" 2>&1 | $TEE -a $logfile