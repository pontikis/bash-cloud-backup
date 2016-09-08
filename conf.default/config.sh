#!/bin/bash
#-------------------------------------------------------------------------------
# SCRIPT.........: config.sh
# ACTION.........: bash-cloud-backup configuration file
# COPYRIGHT......: Christos Pontikis - http://www.pontikis.gr
# LICENSE........: MIT (see https://opensource.org/licenses/MIT)
# DOCUMENTATION..: See README for instructions
#-------------------------------------------------------------------------------

# ##############################################################################
# CONFIGURE the following parameters
#
# NOTE: do not configure parameters for a section you will not use
# ##############################################################################

# ------------------------------------------------------------------------------
# Linux commands paths (probably you do not want to change them) ---------------
# PLEASE CHECK that all these commands are available to your system (probably they are)
FIND="$(which find)"
TAR="$(which tar)"
GZIP="$(which gzip)"
DATE="$(which date)"
CHMOD="$(which chmod)"
MKDIR="$(which mkdir)"
RM="$(which rm)"
TEE="$(which tee)"
WC="$(which wc)"
SORT="$(which sort)"

# ------------------------------------------------------------------------------
# where to backup --------------------------------------------------------------
backuproot='/root/backup'

# ------------------------------------------------------------------------------
# web server (sites to backup) -------------------------------------------------
# path relative to backuproot - SET TO '' IF NOT USED
dir_www='www'
# web server document root
wwwroot='/var/www/'

# ------------------------------------------------------------------------------
# mysql (databases to backup) --------------------------------------------------
# path relative to backuproot - SET TO '' IF NOT USED
dir_mysql='mysql'

mysql_user='username_here'
mysql_password='password_here'

MYSQLDUMP="$(which mysqldump)"

# ------------------------------------------------------------------------------
# configuration files (to backup) ----------------------------------------------
# path relative to backuproot - SET TO '' IF NOT USED
dir_conf='conf'

# ------------------------------------------------------------------------------
# scripts (to backup) ----------------------------------------------------------
# path relative to backuproot - SET TO '' IF NOT USED
dir_scripts='scripts'

# ------------------------------------------------------------------------------
# documents (to backup) --------------------------------------------------------
# path relative to backuproot - SET TO '' IF NOT USED
dir_docs='docs'

# ------------------------------------------------------------------------------
# logs -------------------------------------------------------------------------
# ATTENTION do not set / at the end
logfilepath='/root/backup/log'

logfilename='backup.log'

log_top_separator="################################################################################"
log_separator="--------------------------------------------------------------------------------"

# ------------------------------------------------------------------------------
# 7z compression and encryption (RECOMMENDED) ----------------------------------
# if you set value other than 1, gzip compression will be used (no encryption in this case)
use_7z=1

# ATTENTION --------------------------------------------------------------------
#Enclosing characters in double quotes preserves the literal value of all characters within the quotes,
#with the exception of $, `, \, and, when history expansion is enabled, !.
#...so if you escape those (and the quote itself, of course) you're probably okay.
# http://stackoverflow.com/questions/15783701/which-characters-need-to-be-escaped-in-bash-how-do-we-know-it
passwd_7z="YOUR_PASSWORD_HERE"

cmd_7z="$(which 7z) a -p$passwd_7z -mx=9 -mhe -t7z"
filetype_7z=7z
# you may use the following (NOT recommended) ----------------------------------
# cmd_7z="$(which 7z) a -p$passwd_7z -mx=9 -mm=Deflate -mem=AES256 -tzip"
# filetype_7z=zip

# ------------------------------------------------------------------------------
# rotating delete --------------------------------------------------------------
# delete backups older than
days_rotation=14
# number of backups to be kept, independently of their age
backups_to_keep_at_least=7

# ------------------------------------------------------------------------------
# Amazon S3 --------------------------------------------------------------------
# S3 path to sync local backup - ATTENTION must end with /
s3_plain_path='s3://bucket_name/path/to/plain_backup/'

S3CMD="$(which s3cmd)"
S3CMD_SYNC_PARAMS="--verbose --config /root/.s3cfg --delete-removed --server-side-encryption"
# ATTENTION --------------------------------------------------------------------
# s3cmd versions < 0.9 ---------------------------------------------------------
# add server side encryption using "--add-header=x-amz-server-side-encryption:AES256"
# s3cmd latest version ---------------------------------------------------------
# add server side encryption using"--server-side-encryption"

# ##############################################################################
# END
# ##############################################################################