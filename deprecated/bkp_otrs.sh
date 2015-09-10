#!/bin/bash

#-------------------------------------------------------------------------------
# SCRIPT.........: bkp_otrs
# ACTION.........: Performs OTRS backup (application, data)
# COPYRIGHT......: Christos Pontikis - http://www.pontikis.gr
# LICENSE........: GNU General Public License 
#                  (see http://www.gnu.org/copyleft/gpl.html)
# DOCUMENTATION..: See README for instructions
# RESTRICTIONS...: Assumes that all scripts are in the same directory
#                  (scriptpath) and a conf directory exist 
#                  for configuration files
#-------------------------------------------------------------------------------

scriptpath=`dirname "$0"`
if [ $scriptpath = "." ]; then scriptpath=''; else scriptpath=${scriptpath}/; fi

# include initialize script
source ${scriptpath}conf/initialize.sh otrs

createlog "-Daily backup of OTRS is starting..."

currentdir="$backuproot/$dir_otrs"
if [ ! -d $currentdir ]; then $MKDIR $currentdir; fi

# create temp dir to store backup files created 
# from OTRS /opt/otrs/scripts/backup.pl 
tmpdir=$currentdir/tmp
if [ -d $tmpdir ]; then $RM -rf $tmpdir; fi
$MKDIR $tmpdir;

# create backup using OTRS internal procedure 
# (/opt/otrs/scripts/backup.pl) 
$otrs_internal_bkp -d $tmpdir

# tar and compress OTRS files
dt=`$DATE +%Y%m%d.%H%M%S`
bkpdir=$tmpdir
bkpfile=$currentdir/otrs-$dt.tar.gz
createlog "---creating tar.gz $bkpfile..."
$TAR cfvz $bkpfile $bkpdir

# delete OTRS files
$RM -rf $tmpdir

# rotating delete files of 7 days old
createlog "---rotating delete..."
$CHMOD a+rw $currentdir -R
$FIND $currentdir -mtime +$days_rotation -exec $RM {} -f \;

createlog "-Daily OTRS backup completed."
