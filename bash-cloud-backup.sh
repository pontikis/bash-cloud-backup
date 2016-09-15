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
ECHO="$(which echo)"
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
CAT="$(which cat)"
MAIL="$(which mail)"
DU="$(which du)"
AWK="$(which awk)"
MYSQLDUMP="$(which mysqldump)"
PG_DUMP="$(which pg_dump)"
CMD7Z="$(which 7z)"
S3CMD="$(which s3cmd)"

# Get start time ---------------------------------------------------------------
START=$($DATE +"%s")

# errors counter ---------------------------------------------------------------
errors=-1

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
            $ECHO "FATAL ERROR: invalid options..."
            exit 1
            ;;
    esac
done

if [ ! -f "$global_conf" ]
then
    $ECHO "FATAL ERROR: global configuration file $global_conf does not exist..."
    exit 1
fi

if [ ! -f "$backup_conf" ]
then
    $ECHO "FATAL ERROR: backup configuration file $backup_conf does not exist..."
    exit 1
fi

# get version ------------------------------------------------------------------
version=`$CAT ${scriptpath}VERSION`

# parse backup sections (SPACES NOT PERMITTED) ---------------------------------
sections=( $($SED 's/^[ ]*//g' $backup_conf  | $GREP '^\[.*.\]$' |$TR  -d '^[]$') )

# get global configuration -----------------------------------------------------
backuproot=$(crudini --get "$global_conf" '' backuproot)

hostname=$(crudini --get "$global_conf" '' hostname)
if [ -z "$hostname" ]; then onhost=''; else onhost=" on $hostname"; fi

logfilepath=$(crudini --get "$global_conf" '' logfilepath)
logfilename=$(crudini --get "$global_conf" '' logfilename)
logfilename_tmp=$(crudini --get "$global_conf" '' logfilename_tmp)
log_separator=$(crudini --get "$global_conf" '' log_separator)
log_top_separator=$(crudini --get "$global_conf" '' log_top_separator)

log_filesize=$(crudini --get "$global_conf" '' log_filesize)

use_compression=$(crudini --get "$global_conf" '' use_compression)
if [ $use_compression != '7z' ] && [ $use_compression != 'gzip' ] && [ $use_compression != 'none' ]; then use_compression='none'; fi
if [ $use_compression == '7z' ]; then
    passwd_7z=$(crudini --get "$global_conf" '' passwd_7z)
    filetype_7z=$(crudini --get "$global_conf" '' filetype_7z)
    if [ "$filetype_7z" == '7z' ]; then
        if [ -z "$passwd_7z" ]
        then
            cmd_7z="$CMD7Z a -mx=9 -mhe -t7z"
        else
            cmd_7z="$CMD7Z a -p$passwd_7z -mx=9 -mhe -t7z"
        fi
    elif [ "$filetype_7z" == 'zip' ]; then
        if [ -z "$passwd_7z" ]
        then
            cmd_7z="$CMD7Z a -mx=9 -mm=Deflate -mem=AES256 -tzip"
        else
            cmd_7z="$CMD7Z a -p$passwd_7z -mx=9 -mm=Deflate -mem=AES256 -tzip"
        fi
    else
        use_7z=0
    fi
fi

days_rotation=$(crudini --get "$global_conf" '' days_rotation)
min_backups_in_rotation_period=$(crudini --get "$global_conf" '' min_backups_in_rotation_period)

s3_sync=$(crudini --get "$global_conf" '' s3_sync)
s3_path=$(crudini --get "$global_conf" '' s3_path)
s3cmd_sync_params=$(crudini --get "$global_conf" '' s3cmd_sync_params)

mail_to=$(crudini --get "$global_conf" '' mail_to)

# create log directory in case it does not exist
if [ ! -d "$logfilepath" ]; then $MKDIR -p $logfilepath; fi
# define log files
logfile="$logfilepath/$logfilename"
logfile_tmp="$logfilepath/$logfilename_tmp"

# initialize tmp backup log
$CAT /dev/null > $logfile_tmp

# Utility Functions ------------------------------------------------------------
function createlog {
      dt=`$DATE "+%Y-%m-%d %H:%M:%S"`
      logline="$dt | $1"
      $ECHO -e $logline 2>&1 | $TEE -a $logfile_tmp
}

function report_error {
    ((errors++))
    err[$errors]=$1
    createlog "$1"
}

function get_filesize {
    if [ $log_filesize -eq 1 ]
    then
        filesize=$($DU -h "$1" | $AWK '{print $1}')
        $ECHO -e "\nFilesize: $filesize\n" 2>&1 | $TEE -a $logfile_tmp
    fi
}

function zip_file {

    file_to_zip=$1;

    if [ $use_compression == '7z' ]; then
        if [ -z "$passwd_7z" ]; then aes=''; else aes=" (using AES encryption)"; fi
        createlog "7zip$aes $file_to_zip..."
        $cmd_7z "$file_to_zip.$filetype_7z" $file_to_zip 2>&1 | $TEE -a $logfile_tmp
        if [ ${PIPESTATUS[0]} -eq 0 ]
        then
            createlog "File compression completed successfully."
        else
            report_error "ERROR: $file_to_zip 7z compression failed..."
        fi
        $RM -f $file_to_zip
        get_filesize "$file_to_zip.$filetype_7z"
    elif [ $use_compression == 'gzip' ]; then
        createlog "gzip $file_to_zip..."
        $GZIP -9 -f $file_to_zip 2>&1 | $TEE -a $logfile_tmp
        if [ ${PIPESTATUS[0]} -eq 0 ]
        then
            createlog "File compression completed successfully."
        else
            report_error "ERROR: $file_to_zip gzip compression failed..."
        fi
        get_filesize "$file_to_zip.gz"
    else
        createlog "No compression selected for $file_to_zip..."
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
            $FIND $dir_to_find -mtime +$days_rotation | $SORT 2>&1 | $TEE -a $logfile_tmp

            # proceed to deletion
            $FIND $dir_to_find -mtime +$days_rotation -exec $RM {} -f \;
            if [ $? -eq 0 ]
            then
                createlog "Rotating delete completed successfully."
            else
                report_error "ERROR: rotating delete failed..."
            fi
        else
            createlog "No backups will ne deleted."
        fi

    fi

}

# perform backup ---------------------------------------------------------------
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

    use_compression=$(crudini --get "$backup_conf" "$section" use_compression)
    if [ -z "$use_compression" ]; then use_compression=$(crudini --get "$global_conf" '' use_compression); fi
    if [ $use_compression != '7z' ] && [ $use_compression != 'gzip' ] && [ $use_compression != 'none' ]; then use_compression='none'; fi

    $ECHO -e "\n$log_separator" 2>&1 | $TEE -a $logfile_tmp
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
        createlog "tar options: $tar_options_backup_list"
        createlog "Creating tar $listfile..."
        $TAR $tar_options_backup_list $listfile $tmpdir/backup_list > /dev/null
        get_filesize $listfile
        createlog "tar options: $tar_options_backup_file"
        createlog "Creating tar $bkpfile..."
        $TAR $tar_options_backup_file $bkpfile -T $tmpdir/backup_list > /dev/null
        get_filesize $bkpfile

        # compress (and encrypt) files
        zip_file $listfile
        zip_file $bkpfile

        # rotating delete
        rotate_delete $currentdir 2

    elif [ "$type" == 'mysql' ]; then

        # get specific properties of section with type = 'mysql'
        database=$(crudini --get "$backup_conf" "$section" database)
        mysqldump_options=$(crudini --get "$backup_conf" "$section" mysqldump_options)

        mysql_user=$(crudini --get "$backup_conf" "$section" mysql_user)
        if [ -z "$mysql_user" ]; then mysql_user=$(crudini --get "$global_conf" '' mysql_user); fi

        mysql_password=$(crudini --get "$backup_conf" "$section" mysql_password)
        if [ -z "$mysql_password" ]; then mysql_password=$(crudini --get "$global_conf" '' mysql_password); fi

        # export mysql object(s) using mysqldump
        dt=`$DATE +%Y%m%d.%H%M%S`
        bkpfile=$currentdir/$prefix-$dt.sql
        createlog "mysqldump $bkpfile..."
        $MYSQLDUMP -u$mysql_user -p$mysql_password $mysqldump_options $database > $bkpfile
        if [ $? -eq 0 ]; then
            createlog "mysqldump completed successfully."
        else
            report_error "ERROR: $bkpfile mysqldump failed..."
        fi
        get_filesize $bkpfile

        # compress file
        zip_file $bkpfile

        # rotating delete
        rotate_delete $currentdir 1

    elif [ "$type" == 'postgresql' ]; then

        # get specific properties of section with type = 'postgresql'
        database=$(crudini --get "$backup_conf" "$section" database)
        pg_dump_options=$(crudini --get "$backup_conf" "$section" pg_dump_options)

        pg_user=$(crudini --get "$backup_conf" "$section" pg_user)
        if [ -z "$pg_user" ]; then $pg_user=$(crudini --get "$global_conf" '' pg_user); fi

        pg_password=$(crudini --get "$backup_conf" "$section" pg_password)
        if [ -z "$pg_password" ]; then pg_password=$(crudini --get "$global_conf" '' pg_password); fi

        # export postgresql object(s) using pg_dump
        dt=`$DATE +%Y%m%d.%H%M%S`
        bkpfile=$currentdir/$prefix-$dt.sql
        createlog "pg_dump $bkpfile..."
        if [ -n "$pg_password" ]; then export PGPASSWORD=$pg_password; fi
        $PG_DUMP -U $pg_user $pg_dump_options $database > $bkpfile
        if [ $? -eq 0 ]; then
            createlog "pg_dump completed successfully."
        else
            report_error "ERROR: $bkpfile pg_dump failed..."
        fi
        if [ -n "$pg_password" ]; then unset PGPASSWORD; fi
        get_filesize $bkpfile

        # compress file
        zip_file $bkpfile

        # rotating delete
        rotate_delete $currentdir 1

    else
        $ECHO -e "\n$log_separator" 2>&1 | $TEE -a $logfile_tmp
        report_error "ERROR: Unknown backup type. $section is ingored..."
    fi

    createlog "$finish_message"
done

# Custom script 1 --------------------------------------------------------------
custom_script=${scriptpath}custom1.sh
if [ -f "$custom_script" ]; then source $custom_script; fi

# Amazon S3 sync ---------------------------------------------------------------
if [ $s3_sync -eq 1 ]; then

    s3_path=$(crudini --get "$global_conf" '' s3_path)
    s3cmd_sync_params=$(crudini --get "$global_conf" '' s3cmd_sync_params)

    $ECHO -e "\n$log_separator" 2>&1 | $TEE -a $logfile_tmp
    createlog "Amazon S3 sync is starting..."

    # attention: / is important to copy only the contents of $backuproot
    S3_SOURCE="$backuproot/"
    S3_DEST=$s3_path

    $S3CMD sync $s3cmd_sync_params $S3_SOURCE $S3_DEST 2>&1 | $TEE -a $logfile_tmp
    if [ ${PIPESTATUS[0]} -eq 0 ]
    then
        createlog "Amazon S3 sync completed."
    else
        report_error "ERROR: Amazon S3 sync failed..."
    fi

fi

# Custom script 2 --------------------------------------------------------------
custom_script=${scriptpath}custom2.sh
if [ -f "$custom_script" ]; then source $custom_script; fi

# Finish -----------------------------------------------------------------------
$ECHO -e "\n$log_separator" 2>&1 | $TEE -a $logfile_tmp
createlog "bash-cloud-backup (version $version) completed."

# report errors
$ECHO -e "\n$log_separator" 2>&1 | $TEE -a $logfile_tmp
if [ $errors -eq 0 ]; then
    $ECHO -e "No errors detected." 2>&1 | $TEE -a $logfile_tmp
else
    $ECHO -e "$errors ERRORS detected..." 2>&1 | $TEE -a $logfile_tmp
    counter=1
    for (( i=0; i<${#err[@]}; i++ ));
    do
        err_msg=${err[i]};
        $ECHO -e "$counter) $err_msg" 2>&1 | $TEE -a $logfile_tmp
        ((counter++))
    done
fi

# report tome elapsed
$ECHO -e "\n$log_separator" 2>&1 | $TEE -a $logfile_tmp
END=$($DATE +"%s")
DIFF=$(($END-$START))
ELAPSED="$(($DIFF / 60)) minutes and $(($DIFF % 60)) seconds elapsed."
$ECHO "$ELAPSED"  2>&1 | $TEE -a $logfile_tmp

$ECHO -e "\n$log_top_separator\n" 2>&1 | $TEE -a $logfile_tmp

# update main logfile
$CAT $logfile_tmp >> $logfile

# send mail report -------------------------------------------------------------
if [ -n "$mail_to" ]; then $MAIL -s "bash-cloud-backup$onhost" $mail_to  < $logfile_tmp; fi

# Custom script 3 --------------------------------------------------------------
custom_script=${scriptpath}custom3.sh
if [ -f "$custom_script" ]; then source $custom_script; fi