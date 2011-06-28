#!/bin/bash

#----------------------------------------------------------------------------------
# SCRIPT.........: bkp_mysql
# ACTION.........: Performs backup of selected mysql databases (in conf/db-mysql)
# CREATED BY.....: Christos Pontikis (http://www.medisign.gr)
# COPYRIGHT......: MediSign SA (http://www.medisign.gr)
# LICENSE........: GNU General Public License (see http://www.gnu.org/copyleft/gpl.html)
# DOCUMENTATION..: See README for instructions
# RESTRICTIONS...: Assumes that all scripts are in the same directory (scriptpath) and
#                  a conf directory exist for configuration files
#----------------------------------------------------------------------------------

scriptpath=`dirname "$0"`
if [ $scriptpath = "." ]; then scriptpath=''; else scriptpath=${scriptpath}/; fi

# include initialize script
source ${scriptpath}conf/initialize.sh mysql

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
    
    # compress sql file
    createlog "---zip $bkpfile..."
    $GZIP -9 -f $bkpfile

    # rotating delete files of 7 days old
    createlog "---rotating delete..."
    $CHMOD a+rw $currentdir -R
    $FIND $currentdir -mtime +$days_rotation -exec $RM {} -f \;

    createlog "--Daily backup of MySQL database '$db' completed."
done

createlog "-Daily backup of MySQL databases completed."
