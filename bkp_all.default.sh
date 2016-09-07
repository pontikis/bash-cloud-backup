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

createlog "Filesystem backup is starting..."

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

createlog "Filesystem backup completed."

#echo -e "\n$log_separator" 2>&1 | $TEE -a $logfile
#createlog "Daily S3 plain backup is starting..."
#source ${scriptpath}s3-plain-sync.sh
#createlog "Daily S3 plain backup completed."

#echo -e "\n$log_separator" 2>&1 | $TEE -a $logfile
#source ${scriptpath}custom.sh
#-------------------------------------------------------------------------------