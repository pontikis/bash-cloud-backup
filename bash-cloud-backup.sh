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
            createlog "FATAL ERROR: invalid options..."
            exit 1
            ;;
    esac
done

if [ ! -f "$global_conf" ]
then
    createlog "FATAL ERROR: global configuration file $global_conf does not exist..."
    exit 1
fi

if [ ! -f "$backup_conf" ]
then
    createlog "FATAL ERROR: backup configuration file $backup_conf does not exist..."
    exit 1
fi

# get version ------------------------------------------------------------------
version=`$CAT ${scriptpath}conf/VERSION`

# parse backup sections (SPACES NOT PERMITTED) ---------------------------------
sections=( $($SED 's/^[ ]*//g' $global_conf  | $GREP '^\[.*.\]$' |$TR  -d '^[]$') )
#sections=( $(crudini --get test.ini | sed 's/:.*//') )

# get global configuration -----------------------------------------------------
backuproot=$(crudini --get "$global_conf" '' backuproot)
logfilepath=$(crudini --get "$global_conf" '' logfilepath)
logfilename=$(crudini --get "$global_conf" '' logfilename)
log_separator=$(crudini --get "$global_conf" '' log_separator)
log_top_separator=$(crudini --get "$global_conf" '' log_top_separator)
tar_options=$(crudini --get "$global_conf" '' tar_options)
s3_sync=$(crudini --get "$global_conf" '' s3_sync)

# create log directory in case it does not exist
if [ ! -d "$logfilepath" ]; then $MKDIR -p $logfilepath; fi
# define log file
logfile="$logfilepath/$logfilename"

createlog "bash-cloud-backup (version $version) is starting..."

# perform backup ---------------------------------------------------------------
for (( i=0; i<${#sections[@]}; i++ ));

do

    section=${sections[i]};

    # get backup section properties
    type=$(crudini --get "$backup_conf" "$section" type)
    name=$(crudini --get "$backup_conf" "$section" name)
    path=$(crudini --get "$backup_conf" "$section" path)
    prefix=$(crudini --get "$backup_conf" "$section" prefix)
    fileset=$(crudini --get "$backup_conf" "$section" fileset)
    delimiter=$(crudini --get "$backup_conf" "$section" delimiter)
    starting_message=$(crudini --get "$backup_conf" "$section" starting_message)
    finish_message=$(crudini --get "$backup_conf" "$section" finish_message)

    tar_options_tmp=$(crudini --get "$backup_conf" "$section" tar_options_backup_file)
    if [ -n "$tar_options_tmp" ]; then tar_options_backup_file=$tar_options_tmp; else tar_options_backup_file=$tar_options; fi

    tar_options_tmp=$(crudini --get "$backup_conf" "$section" tar_options_backup_list)
    if [ -n "$tar_options_tmp" ]; then tar_options_backup_list=$tar_options_tmp; else tar_options_backup_list=$tar_options; fi

    if [ "$type" == 'files' ]; then

        echo -e "\n$log_separator" 2>&1 | $TEE -a $logfile
        createlog "$starting_message"

        currentdir="$backuproot/$path"
        if [ ! -d $currentdir ]; then $MKDIR -p $currentdir; fi

        # create temp dir to store backup_list
        tmpdir=$currentdir/tmp
        if [ -d $tmpdir ]; then $RM -rf $tmpdir; fi
        $MKDIR $tmpdir;

        # create backup list from file set
        IFS=$delimiter read -r -a afiles <<< "$fileset"
        for element in "${afiles[@]}"
        do
            $FIND $element -type f >> $tmpdir/backup_list
        done

        # tar files
        dt=`$DATE +%Y%m%d.%H%M%S`
        listfile=$currentdir/$prefix-$dt-list.tar
        bkpfile=$currentdir/$prefix-$dt.tar
        createlog "creating tar $bkpfile..."
        $TAR $tar_options_backup_list $listfile $tmpdir/backup_list > /dev/null
        $TAR $tar_options_backup_file $bkpfile -T $tmpdir/backup_list > /dev/null

        # compress (and encrypt) files
        zip_file $listfile
        zip_file $bkpfile

        # rotating delete
        rotate_delete $currentdir 2

        createlog "$finish_message"

    elif [ "$section_type" == 'mysql' ]; then

        createlog "--Daily backup of MySQL database '$db' is starting..."

        currentdir="$backuproot/$dir_mysql/$db"
        if [ ! -d $currentdir ]; then $MKDIR $currentdir; fi

        # export database with data using mysqldump
        createlog "---dump sql of MySQL database '$db' is starting..."
        dt=`$DATE +%Y%m%d.%H%M%S`
        bkpfile=$currentdir/$db-$dt.sql
        $MYSQLDUMP -u$mysql_user -p$mysql_password $db > $bkpfile

        # compress file
        zip_file $bkpfile

        # rotating delete
        rotate_delete $currentdir 1

        createlog "--Daily backup of MySQL database '$db' completed."

    else
       createlog "ERROR: Unknown backup type. $section is ingored..."
    fi

done

# Custom commands --------------------------------------------------------------
if [ -f "$backup_conf" ]; then source ${scriptpath}conf/custom.sh; fi

# Amazon S3 sync ---------------------------------------------------------------
if [ $s3sync -eq 1 ]; then

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

# Utility Functions ------------------------------------------------------------
function createlog {
      dt=`$DATE "+%Y-%m-%d %H:%M:%S"`
      logline="$dt | $1"
      echo -e $logline 2>&1 | $TEE -a $logfile
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
            $FIND $dir_to_find -mtime +$days_rotation | $SORT 2>&1 | $TEE -a $logfile

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