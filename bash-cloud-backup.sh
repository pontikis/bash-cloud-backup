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
CRUDINI="$(which crudini)"
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
AWS="$(which aws)"
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
backuproot=$($CRUDINI --get "$global_conf" '' backuproot)

hostname=$($CRUDINI --get "$global_conf" '' hostname)
if [ -z "$hostname" ]; then onhost=''; else onhost=" on $hostname"; fi

logfilepath=$($CRUDINI --get "$global_conf" '' logfilepath)
logfilename=$($CRUDINI --get "$global_conf" '' logfilename)

tmp_path=$($CRUDINI --get "$global_conf" '' tmp_path)
if [ -z "$tmp_path" ]; then tmp_path=/tmp/bash-cloud-backup; fi

log_separator=$($CRUDINI --get "$global_conf" '' log_separator)
log_top_separator=$($CRUDINI --get "$global_conf" '' log_top_separator)

log_filesize=$($CRUDINI --get "$global_conf" '' log_filesize)

use_compression=$($CRUDINI --get "$global_conf" '' use_compression)
if [ $use_compression != '7z' ] && [ $use_compression != 'gzip' ] && [ $use_compression != 'none' ]; then use_compression='none'; fi
if [ $use_compression == '7z' ]; then
    passwd_7z=$($CRUDINI --get "$global_conf" '' passwd_7z)
    filetype_7z=$($CRUDINI --get "$global_conf" '' filetype_7z)
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

days_rotation=$($CRUDINI --get "$global_conf" '' days_rotation)
min_backups_in_rotation_period=$($CRUDINI --get "$global_conf" '' min_backups_in_rotation_period)

s3_sync=$($CRUDINI --get "$global_conf" '' s3_sync)

mail_to=$($CRUDINI --get "$global_conf" '' mail_to)

export_session_log_to=$($CRUDINI --get "$global_conf" '' export_session_log_to)

disable_report_summary=$($CRUDINI --get "$global_conf" '' disable_report_summary)
if [ -z "$disable_report_summary" ]; then disable_report_summary=0; fi

# define nice ionice trickle
nice_params=$($CRUDINI --get "$global_conf" '' nice_params)
ionice_params=$($CRUDINI --get "$global_conf" '' ionice_params)
trickle_params=$($CRUDINI --get "$global_conf" '' trickle_params)

if [ -z "$nice_params" ]; then NICE=''; else NICE="$(which nice) $nice_params"; fi
if [ -z "$ionice_params" ]; then IONICE=''; else IONICE="$(which ionice) $ionice_params"; fi
if [ -z "$trickle_params" ]; then TRICKLE=''; else TRICKLE="$(which trickle) $trickle_params"; fi

# define main log file
if [ -n "$logfilepath" ] && [ -n "$logfilename" ]
then
    logfile="$logfilepath/$logfilename"
fi

# define temp log files
logfile_tmp_header="$tmp_path/header.log"
logfile_tmp_main="$tmp_path/main.log"
logfile_tmp_errors="$tmp_path/errors.log"
logfile_tmp_time_elapsed="$tmp_path/time_elapsed.log"
logfile_tmp_whole_session="$tmp_path/whole_session.log"
logfile_tmp_summary="$tmp_path/summary.log"

# Utility Functions ------------------------------------------------------------
function createlog {
    dt=`$DATE "+%Y-%m-%d %H:%M:%S"`
    if [ -z "$2" ]; then
        logline="$dt | $1"
    else
        if [ $2 -eq 0 ]; then logline="$1"; else logline="$dt | $1"; fi
    fi
    if [ -z "$3" ]; then logfile_to_write=$logfile_tmp_main; else logfile_to_write=$3; fi
    if [ -z "$4" ]; then
        $ECHO -e $logline 2>&1 | $TEE -a $logfile_to_write
    else
        if [ $4 -eq 0 ]; then
            $ECHO -e $logline 2>&1
        elif [ $4 -eq 1 ]; then
            $ECHO -e $logline >> $logfile_to_write
        else
            $ECHO -e $logline 2>&1 | $TEE -a $logfile_to_write
        fi
    fi
}

function report_error {
    ((errors++))
    err[$errors]=$1
    createlog "$1"
}

function create_directory {
    if [ ! -d "$1" ]; then
        $MKDIR -p $1 2>&1 | $TEE -a $logfile_tmp_main
        if [ ${PIPESTATUS[0]} -eq 0 ]
        then
            createlog "Directory $1 created successfully."
        else
            report_error "ERROR: Directory $1 creation failed..."
        fi
    fi
}

function get_filesize {
    if [ $log_filesize -eq 1 ]
    then
        filesize=$($DU -h "$1" | $AWK '{print $1}')
        createlog "\nFilesize: $filesize\n" 0
    fi
}

function zip_file {

    file_to_zip=$1;

    if [ $use_compression == '7z' ]; then
        if [ -z "$passwd_7z" ]; then aes=''; else aes=" (using AES encryption)"; fi
        createlog "7zip$aes $file_to_zip..."
        $NICE $IONICE $cmd_7z "$file_to_zip.$filetype_7z" $file_to_zip 2>&1 | $TEE -a $logfile_tmp_main
        if [ ${PIPESTATUS[0]} -eq 0 ]
        then
            createlog "File compression completed successfully."
        else
            report_error "ERROR: Section [$section]. $file_to_zip 7z compression failed..."
        fi
        $RM -f $file_to_zip
        get_filesize "$file_to_zip.$filetype_7z"
    elif [ $use_compression == 'gzip' ]; then
        createlog "gzip $file_to_zip..."
        $NICE $IONICE $GZIP -9 -f $file_to_zip 2>&1 | $TEE -a $logfile_tmp_main
        if [ ${PIPESTATUS[0]} -eq 0 ]
        then
            createlog "File compression completed successfully."
        else
            report_error "ERROR: Section [$section]. $file_to_zip gzip compression failed..."
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
            $FIND $dir_to_find -mtime +$days_rotation | $SORT 2>&1 | $TEE -a $logfile_tmp_main

            # proceed to deletion
            $FIND $dir_to_find -mtime +$days_rotation -exec $RM {} -f \;
            if [ $? -eq 0 ]
            then
                createlog "Rotating delete completed successfully."
            else
                report_error "ERROR: Section [$section]. Rotating delete failed..."
            fi
        else
            createlog "No backups will ne deleted."
        fi

    fi

}

# Start ------------------------------------------------------------------------
# create temp directory
create_directory "$tmp_path"

# create log directory in case it does not exist
if [ -n "$logfilepath" ]; then create_directory "$logfilepath"; fi

# initialize tmp backup log
$CAT /dev/null > $logfile_tmp_header
$CAT /dev/null > $logfile_tmp_main
$CAT /dev/null > $logfile_tmp_errors
$CAT /dev/null > $logfile_tmp_time_elapsed
$CAT /dev/null > $logfile_tmp_whole_session
$CAT /dev/null > $logfile_tmp_summary

if [ $disable_report_summary -eq 0 ]; then
    createlog "AT A GLANCE" 0 $logfile_tmp_header 1
    createlog "$log_separator" 0 $logfile_tmp_header 1
    createlog "bash-cloud-backup (version $version)$onhost started..." 1 $logfile_tmp_header 1

    createlog "\n\nIN DETAILS" 0 $logfile_tmp_main 1
fi

createlog "$log_separator" 0 $logfile_tmp_main 1
createlog "bash-cloud-backup (version $version)$onhost is starting..."

# Custom script ----------------------------------------------------------------
custom_script=${scriptpath}on_backup_started.sh
if [ -f "$custom_script" ]; then source $custom_script; fi

for (( i=0; i<${#sections[@]}; i++ ));

do

    section=${sections[i]}

    # get section type
    type=$($CRUDINI --get "$backup_conf" "$section" type)
    if [ "$type" != "files" ] && [ "$type" != "mysql" ] && [ "$type" != "postgresql" ]; then
        createlog "\n$log_separator" 0
        report_error "ERROR: Section [$section]. Unknown backup type <$type>. Section is ingored..."
        continue
    fi

    # get section path
    path=$($CRUDINI --get "$backup_conf" "$section" path)
    currentdir="$backuproot/$path"
    create_directory "$currentdir"

    # get section number_of_files_per_backup
    number_of_files_per_backup=$($CRUDINI --get "$backup_conf" "$section" number_of_files_per_backup)
    if [ -z "$number_of_files_per_backup" ]; then
        if [ "$type" == 'files' ]; then
            number_of_files_per_backup=2
        elif [ "$type" == 'mysql' ]; then
            number_of_files_per_backup=1
        elif [ "$type" == 'postgresql' ]; then
            number_of_files_per_backup=1
        fi
    fi

    # check if section has to be skipped
    skip_after=$($CRUDINI --get "$backup_conf" "$section" skip_after)
    if [ -n "$skip_after" ]; then
        backups=`$FIND $currentdir -maxdepth 1 -type f | $WC -l`
        backups=$(( $backups/$number_of_files_per_backup ))
        if [ $backups -ge $skip_after ]; then
            skip_message=$($CRUDINI --get "$backup_conf" "$section" skip_message)
            createlog "\n$log_separator" 0
            createlog "$skip_message"
            createlog "$backups total backups found."
            continue
        fi
    fi

    # get backup section properties (common for all types)
    prefix=$($CRUDINI --get "$backup_conf" "$section" prefix)
    starting_message=$($CRUDINI --get "$backup_conf" "$section" starting_message)
    finish_message=$($CRUDINI --get "$backup_conf" "$section" finish_message)

    use_compression=$($CRUDINI --get "$backup_conf" "$section" use_compression)
    if [ -z "$use_compression" ]; then use_compression=$($CRUDINI --get "$global_conf" '' use_compression); fi
    if [ $use_compression != '7z' ] && [ $use_compression != 'gzip' ] && [ $use_compression != 'none' ]; then use_compression='none'; fi

    createlog "\n$log_separator" 0
    createlog "$starting_message"

    if [ "$type" == 'files' ]; then

        # get specific properties of section with type = 'files'
        fileset=$($CRUDINI --get "$backup_conf" "$section" fileset)
        delimiter=$($CRUDINI --get "$backup_conf" "$section" delimiter)

        tar_options_backup_list=$($CRUDINI --get "$backup_conf" "$section" tar_options_backup_list)
        if [ -z "$tar_options_backup_list" ]; then tar_options_backup_list=$($CRUDINI --get "$global_conf" '' tar_options_backup_list); fi

        tar_options_backup_file=$($CRUDINI --get "$backup_conf" "$section" tar_options_backup_file)
        if [ -z "$tar_options_backup_file" ]; then tar_options_backup_file=$($CRUDINI --get "$global_conf" '' tar_options_backup_file); fi

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

        # tar backup list
        dt=`$DATE +%Y%m%d.%H%M%S`
        listfile=$currentdir/$prefix-$dt-list.tar
        bkpfile=$currentdir/$prefix-$dt.tar
        createlog "Creating tar $listfile..."
        createlog "tar options: $tar_options_backup_list"
        $NICE $IONICE $TAR $tar_options_backup_list $listfile $tmpdir/backup_list 2>&1 | $TEE -a $logfile_tmp_main
        if [ ${PIPESTATUS[0]} -eq 0 ]; then
            createlog "tar of backup list completed successfully."
        else
            report_error "ERROR: Section [$section]. $listfile tar failed..."
        fi
        get_filesize $listfile

        # tar backup file using backup list
        createlog "Creating tar $bkpfile..."
        createlog "tar options: $tar_options_backup_file"
        files_to_tar="${fileset//$delimiter/ }"
        $NICE $IONICE $TAR $tar_options_backup_file $bkpfile $files_to_tar 2>&1 | $TEE -a $logfile_tmp_main
        if [ ${PIPESTATUS[0]} -eq 0 ]; then
            createlog "tar of backup file completed successfully."
        else
            report_error "ERROR: Section [$section]. $bkpfile tar failed..."
        fi
        get_filesize $bkpfile

        # compress (and encrypt) files
        zip_file $listfile
        zip_file $bkpfile

        # rotating delete
        rotate_delete $currentdir $number_of_files_per_backup

    elif [ "$type" == 'mysql' ]; then

        # get specific properties of section with type = 'mysql'
        database=$($CRUDINI --get "$backup_conf" "$section" database)
        mysqldump_options=$($CRUDINI --get "$backup_conf" "$section" mysqldump_options)

        mysql_user=$($CRUDINI --get "$backup_conf" "$section" mysql_user)
        if [ -z "$mysql_user" ]; then mysql_user=$($CRUDINI --get "$global_conf" '' mysql_user); fi

        mysql_password=$($CRUDINI --get "$backup_conf" "$section" mysql_password)
        if [ -z "$mysql_password" ]; then mysql_password=$($CRUDINI --get "$global_conf" '' mysql_password); fi

        # export mysql object(s) using mysqldump
        dt=`$DATE +%Y%m%d.%H%M%S`
        bkpfile=$currentdir/$prefix-$dt.sql
        createlog "mysqldump $bkpfile..."
        if [ -n "$mysql_password" ]
        then
            $NICE $IONICE $MYSQLDUMP -u$mysql_user -p$mysql_password --result-file=$bkpfile $mysqldump_options $database 2>&1 | $TEE -a $logfile_tmp_main
        else
            $NICE $IONICE $MYSQLDUMP -u$mysql_user --result-file=$bkpfile $mysqldump_options $database 2>&1 | $TEE -a $logfile_tmp_main
        fi
        if [ ${PIPESTATUS[0]} -eq 0 ]; then
            createlog "mysqldump completed successfully."
        else
            report_error "ERROR: Section [$section]. $bkpfile mysqldump failed..."
        fi
        get_filesize $bkpfile

        # compress file
        zip_file $bkpfile

        # rotating delete
        rotate_delete $currentdir $number_of_files_per_backup

    elif [ "$type" == 'postgresql' ]; then

        # get specific properties of section with type = 'postgresql'
        database=$($CRUDINI --get "$backup_conf" "$section" database)
        pg_dump_options=$($CRUDINI --get "$backup_conf" "$section" pg_dump_options)

        pg_user=$($CRUDINI --get "$backup_conf" "$section" pg_user)
        if [ -z "$pg_user" ]; then $pg_user=$($CRUDINI --get "$global_conf" '' pg_user); fi

        pg_password=$($CRUDINI --get "$backup_conf" "$section" pg_password)
        if [ -z "$pg_password" ]; then pg_password=$($CRUDINI --get "$global_conf" '' pg_password); fi

        # export postgresql object(s) using pg_dump
        dt=`$DATE +%Y%m%d.%H%M%S`
        bkpfile=$currentdir/$prefix-$dt.sql
        createlog "pg_dump $bkpfile..."
        if [ -n "$pg_password" ]; then export PGPASSWORD=$pg_password; fi
        $NICE $IONICE $PG_DUMP --username=$pg_user --file=$bkpfile $pg_dump_options $database 2>&1 | $TEE -a $logfile_tmp_main
        if [ ${PIPESTATUS[0]} -eq 0 ]; then
            createlog "pg_dump completed successfully."
        else
            report_error "ERROR: Section [$section]. $bkpfile pg_dump failed..."
        fi
        if [ -n "$pg_password" ]; then unset PGPASSWORD; fi
        get_filesize $bkpfile

        # compress file
        zip_file $bkpfile

        # rotating delete
        rotate_delete $currentdir $number_of_files_per_backup

    fi

    createlog "$finish_message"
done

# Custom script ----------------------------------------------------------------
custom_script=${scriptpath}on_backup_finished.sh
if [ -f "$custom_script" ]; then source $custom_script; fi

# Amazon S3 sync ---------------------------------------------------------------
if [ $s3_sync -eq 1 ]; then

    createlog "\n$log_separator" 0
    createlog "Amazon S3 sync is starting..."

    # attention: / is important to copy only the contents of $backuproot
    S3_SOURCE="$backuproot/"
    S3_DEST=$($CRUDINI --get "$global_conf" '' s3_path)
    amazon_front_end=$($CRUDINI --get "$global_conf" '' amazon_front_end)

    if [ "$amazon_front_end" == "awscli" ]; then
        awscli_params=$($CRUDINI --get "$global_conf" '' awscli_params)
        $NICE $IONICE $TRICKLE \
        $AWS s3 sync $awscli_params \
        $S3_SOURCE $S3_DEST 2>&1 | $TEE -a $logfile_tmp_main
    elif [ "$amazon_front_end" == "s3cmd" ]; then
        s3cmd_sync_params=$($CRUDINI --get "$global_conf" '' s3cmd_sync_params)
        $NICE $IONICE $TRICKLE \
        $S3CMD sync $s3cmd_sync_params \
        $S3_SOURCE $S3_DEST 2>&1 | $TEE -a $logfile_tmp_main
    fi

    if [ ${PIPESTATUS[0]} -eq 0 ]
    then
        createlog "Amazon S3 sync completed."
    else
        report_error "ERROR: Amazon S3 sync failed..."
    fi

fi

# Custom script ----------------------------------------------------------------
custom_script=${scriptpath}on_s3_sync_finished.sh
if [ -f "$custom_script" ]; then source $custom_script; fi

# Finish -----------------------------------------------------------------------
if [ $disable_report_summary -eq 0 ]; then
    createlog "\n$log_separator" 0 $logfile_tmp_header 1
    createlog "bash-cloud-backup (version $version) completed." 1 $logfile_tmp_header 1
fi

createlog "\n$log_separator" 0
createlog "bash-cloud-backup (version $version) completed."

# report errors
report_errors=$($CRUDINI --get "$global_conf" '' report_errors)
export_errors_to=$($CRUDINI --get "$global_conf" '' export_errors_to)
if [ -z "$report_errors" ]; then report_errors=1; fi
if [ -n "$export_errors_to" ]; then $CAT /dev/null > $export_errors_to; fi

createlog "\n$log_separator" 0 $logfile_tmp_errors
if [ $errors -eq -1 ]; then
    if [ $report_errors -eq 1 ]; then createlog "No errors encountered." 0 $logfile_tmp_errors; fi
else
    if [ $report_errors -eq 1 ]; then createlog "${#err[@]} ERRORS encountered..." 0 $logfile_tmp_errors; fi
    counter=1
    for (( i=0; i<${#err[@]}; i++ ));
    do
        err_msg=${err[i]}
        if [ $report_errors -eq 1 ]; then createlog "$counter) $err_msg" 0 $logfile_tmp_errors; fi
        if [ -n "$export_errors_to" ]; then $ECHO -e "$err_msg" >> $export_errors_to; fi
        ((counter++))
    done
fi

# report time elapsed
createlog "\n$log_separator" 0 $logfile_tmp_time_elapsed
END=$($DATE +"%s")
DIFF=$(($END-$START))
ELAPSED="$(($DIFF / 60)) minutes and $(($DIFF % 60)) seconds elapsed."
createlog "$ELAPSED" 0 $logfile_tmp_time_elapsed

# create logs summary from parts
if [ $report_errors -eq 1 ]
then
    $CAT $logfile_tmp_header $logfile_tmp_errors $logfile_tmp_time_elapsed > $logfile_tmp_summary
else
    $CAT $logfile_tmp_header $logfile_tmp_time_elapsed > $logfile_tmp_summary
fi

# create whole session logs from parts
if [ $report_errors -eq 1 ]
then
    if [ $disable_report_summary -eq 0 ]; then
        $CAT $logfile_tmp_summary $logfile_tmp_main $logfile_tmp_errors $logfile_tmp_time_elapsed > $logfile_tmp_whole_session
    else
        $CAT $logfile_tmp_main $logfile_tmp_errors $logfile_tmp_time_elapsed > $logfile_tmp_whole_session
    fi
else
    if [ $disable_report_summary -eq 0 ]; then
        $CAT $logfile_tmp_summary $logfile_tmp_main $logfile_tmp_time_elapsed > $logfile_tmp_whole_session
    else
        $CAT $logfile_tmp_main $logfile_tmp_time_elapsed > $logfile_tmp_whole_session
    fi
fi

# update main logfile
if [ -n "$logfile" ]; then
    $CAT $logfile_tmp_whole_session >> $logfile
    $ECHO - e "\n$log_top_separator\n" >> $logfile
fi

# export session log
if [ -n "$export_session_log_to" ]; then
    $CAT $logfile_tmp_whole_session > $export_session_log_to
fi

# send mail report -------------------------------------------------------------
if [ -n "$mail_to" ]; then
    cat_params_in_mail_command=$($CRUDINI --get "$global_conf" '' cat_params_in_mail_command)
    mail_only_summary=$($CRUDINI --get "$global_conf" '' mail_only_summary)
    if [ $mail_only_summary -eq 1 ]
    then
        $CAT $cat_params_in_mail_command $logfile_tmp_summary| $MAIL -s "bash-cloud-backup$onhost" $mail_to
    else
        $CAT $cat_params_in_mail_command $logfile_tmp_whole_session | $MAIL -s "bash-cloud-backup$onhost" $mail_to
    fi
fi

# DELETE temp directory (and its contents)
$RM -rf "$tmp_path"

# Custom script ----------------------------------------------------------------
custom_script=${scriptpath}on_logfile_created.sh
if [ -f "$custom_script" ]; then source $custom_script; fi