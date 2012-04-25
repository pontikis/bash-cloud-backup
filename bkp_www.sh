#!/bin/bash

#----------------------------------------------------------------------------------
# SCRIPT.........: bkp_www
# ACTION.........: Performs backup of selected web sites (in conf/sites)
# CREATED BY.....: Christos Pontikis (http://www.medisign.gr)
# DATE...........: 2006-05-13
# VERSION........: 1.0
# COPYRIGHT......: MediSign SA (http://www.medisign.gr)
# LICENSE........: GNU General Public License (see http://www.gnu.org/copyleft/gpl.html)
# DOCUMENTATION..: See README for instructions
# RESTRICTIONS...: Assumes that all scripts are in the same directory (scriptpath) and
#                  a conf directory exist for configuration files
#----------------------------------------------------------------------------------

scriptpath=`dirname "$0"`
if [ $scriptpath = "." ]; then scriptpath=''; else scriptpath=${scriptpath}/; fi

# include initialize script
source ${scriptpath}conf/initialize.sh www

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
    $TAR cfv $bkpfile $wwwroot/$wwwpath > /dev/null

    if [ $use_7z -eq 1 ]; then
        createlog "---7zip $bkpfile..."
        $cmd_7z "$bkpfile.zip" $bkpfile
        $RM -f $bkpfile
    else
        createlog "---zip $bkpfile..."
        $GZIP -9 -f $bkpfile
    fi

    # rotating delete files of 7 days old
    createlog "---rotating delete..."
    $CHMOD a+rw $currentdir -R
    $FIND $currentdir -mtime +$days_rotation -exec $RM {} -f \;

    createlog "--Daily backup of WWW site '$wwwpath' completed."
done

createlog "-Daily backup of WWW sites completed."
