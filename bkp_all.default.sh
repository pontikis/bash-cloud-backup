#!/bin/bash
#-------------------------------------------------------------------------------
# SCRIPT.........: bkp_all.default.sh
# ACTION.........: Defines which backup operations will be performed
# COPYRIGHT......: Christos Pontikis - http://www.pontikis.gr
# LICENSE........: MIT (see https://opensource.org/licenses/MIT)
# DOCUMENTATION..: See README for instructions
#-------------------------------------------------------------------------------

# ##############################################################################
# ATTENTION
#
# DO NOT EDIT THIS SCRIPT - copy it to bkp_all.sh and edit this file instead
# ##############################################################################

scriptpath=`dirname "$0"`
if [ $scriptpath = "." ]; then scriptpath=''; else scriptpath=${scriptpath}/; fi

# include config script
source ${scriptpath}conf/config.sh
# include init script
source ${scriptpath}common/init.sh

echo -e "\n$log_top_separator" 2>&1 | $TEE -a $logfile

createlog "bash-cloud-backup is starting..."

# include www backup script
#echo -e "\n$log_separator" 2>&1 | $TEE -a $logfile
#source ${scriptpath}bkp_www.sh

# include mysql backup script
#echo -e "\n$log_separator" 2>&1 | $TEE -a $logfile
#source ${scriptpath}bkp_db_mysql.sh

# include conf backup script
#echo -e "\n$log_separator" 2>&1 | $TEE -a $logfile
#source ${scriptpath}bkp_conf.sh

# include scripts backup script
#echo -e "\n$log_separator" 2>&1 | $TEE -a $logfile
#source ${scriptpath}bkp_scripts.sh

# include docs backup script
#echo -e "\n$log_separator" 2>&1 | $TEE -a $logfile
#source ${scriptpath}bkp_docs.sh

# include Amazon S3 sync script
#echo -e "\n$log_separator" 2>&1 | $TEE -a $logfile
#source ${scriptpath}s3-plain-sync.sh

# include custom script
#echo -e "\n$log_separator" 2>&1 | $TEE -a $logfile
#source ${scriptpath}custom.sh

createlog "bash-cloud-backup completed."
#-------------------------------------------------------------------------------