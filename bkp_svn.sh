#!/bin/bash

#----------------------------------------------------------------------------------
# SCRIPT.........: bkp_svn
# ACTION.........: Performs backup of selected SVN repos (in conf/svn-repos)
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
source ${scriptpath}conf/initialize.sh svn

createlog "-Daily backup of SVN Repositories is starting..."

for repo in `cat ${scriptpath}conf/svn-repos`
do
    createlog "--Daily backup of SVN Repository '$repo' is starting..."
    
    currentdir="$backuproot/$dir_svn/$repo"
    if [ ! -d $currentdir ]; then $MKDIR $currentdir; fi
    
    # create temp dir to store repo hot backup
    tmpdir=$currentdir/tmp
    if [ -d $tmpdir ]; then $RM -rf $tmpdir; fi
    $MKDIR $tmpdir
    
    # hot backup repo using hot-backup.py script
    createlog "---hot backup of SVN Repository '$repo' is starting..."
    $svn_hot_backup_py_path/hot-backup.py $svn_path/$repo $tmpdir
    
    # tar repo files
    dt=`$DATE +%Y%m%d.%H%M%S`
    bkpfile=$currentdir/$repo-$dt.tar
    createlog "---creating tar $bkpfile..."
    $TAR cfv $bkpfile $tmpdir > /dev/null

    # compress repo files tar
    createlog "---zip $bkpfile..."
    $GZIP -9 -f $bkpfile

    # delete tmp dir
    if [ -d $tmpdir ]; then $RM -rf $tmpdir; fi

    # rotating delete files of 7 days old
    createlog "---rotating delete..."
    $CHMOD a+rw $currentdir -R
    $FIND $currentdir -mtime +$days_rotation -exec $RM {} -f \;

    createlog "--Daily backup of SVN Repository '$repo' completed."
done

createlog "-Daily backup of SVN Repositories completed."
