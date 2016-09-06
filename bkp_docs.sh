#!/bin/bash

#----------------------------------------------------------------------------------
# SCRIPT.........: bkp_docs
# ACTION.........: Performs backup of selected documents (in conf/docs)
# COPYRIGHT......: Christos Pontikis - http://www.pontikis.gr
# LICENSE........: MIT (see https://opensource.org/licenses/MIT)
# DOCUMENTATION..: See README for instructions
# RESTRICTIONS...: Assumes that all scripts are in the same directory (scriptpath) and
#                  a conf directory exist for configuration files
#----------------------------------------------------------------------------------

scriptpath=`dirname "$0"`
if [ $scriptpath = "." ]; then scriptpath=''; else scriptpath=${scriptpath}/; fi

# include initialize script
source ${scriptpath}conf/initialize.sh docs

createlog "-Daily backup of DOCS is starting..."

currentdir="$backuproot/$dir_docs"
if [ ! -d $currentdir ]; then $MKDIR $currentdir; fi

# create temp dir to store backup_list
tmpdir=$currentdir/tmp
if [ -d $tmpdir ]; then $RM -rf $tmpdir; fi
$MKDIR $tmpdir;

for line in `cat ${scriptpath}conf/docs |grep ^/`
do
  $FIND $line -type f >> $tmpdir/backup_list
done

# tar site files
dt=`$DATE +%Y%m%d.%H%M%S`
listfile=$currentdir/docs-$dt-list.tar
bkpfile=$currentdir/docs-$dt.tar
createlog "---creating tar $bkpfile..."
$TAR cpfv $listfile $tmpdir/backup_list > /dev/null
$TAR cpfv $bkpfile -T $tmpdir/backup_list > /dev/null

if [ $use_7z -eq 1 ]; then
    createlog "---7zip $bkpfile..."
    $cmd_7z "$listfile.$filetype_7z" $listfile 2>&1 | $TEE -a $logfile
    $cmd_7z "$bkpfile.$filetype_7z" $bkpfile 2>&1 | $TEE -a $logfile
    $RM -f $listfile
    $RM -f $bkpfile
else
    createlog "---zip $bkpfile..."
    $GZIP -9 -f $listfile 2>&1 | $TEE -a $logfile
    $GZIP -9 -f $bkpfile 2>&1 | $TEE -a $logfile
fi

# rotating delete files of 7 days old
createlog "---rotating delete..."
$CHMOD a+rw $currentdir -R
$FIND $currentdir -mtime +$days_rotation -exec $RM {} -f \;

createlog "-Daily backup of DOCS completed."

