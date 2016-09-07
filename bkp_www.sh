#!/bin/bash

#----------------------------------------------------------------------------------
# SCRIPT.........: bkp_www.sh
# ACTION.........: Performs backup of selected web sites (in conf/sites)
# DATE...........: 2006-05-13
# VERSION........: 1.0
# COPYRIGHT......: Christos Pontikis - http://www.pontikis.gr
# LICENSE........: MIT (see https://opensource.org/licenses/MIT)
# DOCUMENTATION..: See README for instructions
# RESTRICTIONS...: Assumes that all scripts are in the same directory (scriptpath) and
#                  a conf directory exist for configuration files
#----------------------------------------------------------------------------------

scriptpath=`dirname "$0"`
if [ $scriptpath = "." ]; then scriptpath=''; else scriptpath=${scriptpath}/; fi

# include config script
source ${scriptpath}conf/config.sh
# include init script
source ${scriptpath}common/init.sh

createlog "-Daily backup of WWW sites is starting..."

for line in `cat ${scriptpath}conf/sites`
do
    pos=`expr index "$line" \|`
    site=${line:0:$pos-1}
    wwwpath=${line:$pos}

    createlog "--Daily backup of WWW site '$wwwpath' is starting..."
    
    currentdir="$backuproot/$dir_www/$site"
    if [ ! -d $currentdir ]; then $MKDIR $currentdir; fi

    # tar site files
    dt=`$DATE +%Y%m%d.%H%M%S`
    bkpfile=$currentdir/$site-$dt.tar
    createlog "---creating tar $bkpfile..."
    $TAR cpfv $bkpfile $wwwroot/$wwwpath > /dev/null

    if [ $use_7z -eq 1 ]; then
        createlog "---7zip $bkpfile..."
        $cmd_7z "$bkpfile.$filetype_7z" $bkpfile 2>&1 | $TEE -a $logfile
        $RM -f $bkpfile
    else
        createlog "---zip $bkpfile..."
        $GZIP -9 -f $bkpfile 2>&1 | $TEE -a $logfile
    fi

    # rotating delete files of 7 days old
    createlog "---rotating delete..."
    $CHMOD a+rw $currentdir -R
    $FIND $currentdir -mtime +$days_rotation -exec $RM {} -f \;

    createlog "--Daily backup of WWW site '$wwwpath' completed."
done

createlog "-Daily backup of WWW sites completed."
