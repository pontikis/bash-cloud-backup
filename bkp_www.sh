#!/bin/bash
#-------------------------------------------------------------------------------
# SCRIPT.........: bkp_www.sh
# ACTION.........: Performs backup of selected web sites (in conf/sites)
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

    # compress file
    zip_file $bkpfile

    # rotating delete
    rotate_delete $currentdir 1

    createlog "--Daily backup of WWW site '$wwwpath' completed."
done

createlog "-Daily backup of WWW sites completed."