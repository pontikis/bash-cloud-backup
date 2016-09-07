#!/bin/bash
#-------------------------------------------------------------------------------
# SCRIPT.........: bkp_db_mysql.sh
# ACTION.........: Performs backup of selected mysql databases (in conf/db-mysql)
# COPYRIGHT......: Christos Pontikis - http://www.pontikis.gr
# LICENSE........: MIT (see https://opensource.org/licenses/MIT)
# DOCUMENTATION..: See README for instructions
#-------------------------------------------------------------------------------

scriptpath=`dirname "$0"`
if [ $scriptpath = "." ]; then scriptpath=''; else scriptpath=${scriptpath}/; fi

# include config script
source ${scriptpath}conf/config.sh
# include init script
source ${scriptpath}common/init.sh

createlog "-Daily backup of MySQL databases is starting..."

for db in `cat ${scriptpath}conf/db-mysql`
do
    createlog "--Daily backup of MySQL database '$db' is starting..."

    currentdir="$backuproot/$dir_mysql/$db"
    if [ ! -d $currentdir ]; then $MKDIR $currentdir; fi
    
    # export database with data using mysqldump
    createlog "---dump sql of MySQL database '$db' is starting..."
    dt=`$DATE +%Y%m%d.%H%M%S`
    bkpfile=$currentdir/$db-$dt.sql
    $MYSQLDUMP -u$mysql_user -p$mysql_password $db > $bkpfile

    if [ $use_7z -eq 1 ]; then
        createlog "---7zip $bkpfile..."
        $cmd_7z "$bkpfile.$filetype_7z" $bkpfile 2>&1 | $TEE -a $logfile
        $RM -f $bkpfile
    else
        createlog "---zip $bkpfile..."
        $GZIP -9 -f $bkpfile 2>&1 | $TEE -a $logfile
    fi

    # rotating delete
    rotate_delete $currentdir 1

    createlog "--Daily backup of MySQL database '$db' completed."
done

createlog "-Daily backup of MySQL databases completed."