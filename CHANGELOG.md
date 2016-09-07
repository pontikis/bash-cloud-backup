bash-cloud-backup
=================

bash-cloud-backup is a set of bash scripts, which can be used to automate local and cloud backup in Linux/Unix machines.

Copyright Christos Pontikis http://www.pontikis.gr

License MIT https://raw.github.com/pontikis/bash-cloud-backup/master/MIT_LICENSE

Release 1.1.0 (08 Sep 2016)
---------------------------

* rotate delete became more flexible:
   * setting ``days_rotation`` to 0 is disabled
   * with ``backups_to_keep_at_least`` a number of backups can be kept, independently of their age

* conf/initialize.sh reorganized and renamed to conf/config.sh
* common/init.sh added with common tasks and utility functions

Release 1.0.5 (06 Sep 2016)
---------------------------

* Remove deprecated scripts #23
* Redirect gzip output to log file #22
* Redirect 7z output to log file #21
* Redirect s3cmd sync output to log file #20

Release 1.0.4 (06 Sep 2016)
---------------------------
* Guidelines to escape special characters in passwords #17
* BUG FIX error parsing 7z_filetype variable name #18
* Script with custom commands at the end of the backup procedure #19

Release 1.0.3 (01 Sep 2016)
---------------------------
* change default CMD_7z to create 7z package (not zip) #15

Release 1.0.2 (01 Sep 2016)
---------------------------
* MIT LICENSE
* S3CMD_SYNC_PARAMS user defined (including server side encryption) 
* use_s3_server_encryption deprecated (included in S3CMD_SYNC_PARAMS)
* 7z compression added

Release 1.0.1 (28 Jun 2011)
---------------------------
* minor changes

Release 1.0.0 (28 Jun 2011)
---------------------------
* Basic functionality
