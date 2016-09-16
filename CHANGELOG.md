bash-cloud-backup
=================

bash-cloud-backup is a bash script, which can be used to automate local and cloud backup in Linux/Unix machines.

Copyright Christos Pontikis http://www.pontikis.gr

License MIT https://raw.github.com/pontikis/bash-cloud-backup/master/MIT_LICENSE

Release 2.0.7 (16 Sep 2016)
---------------------------
* Improve error reporting #48


    ATTENTION

Version 2.* is not compatible with previous (deprecated) version 1.*

Version 1 has its own branch (version1).

More at https://github.com/pontikis/bash-cloud-backup/blob/version1/README.md


Release 2.0.6 (15 Sep 2016)
---------------------------
* Simple error reporting #48


Release 2.0.5 (15 Sep 2016)
---------------------------
* Postgresql support #12
* Custom scripts #47
    You may create and use 
    
    * ``custom1.sh`` - after backup finished and before Amazon S3 sync
    * ``custom2.sh`` - after Amazon S3 sync
    * ``custom3.sh`` - after logfile created and main script finished
    
    (these scripts are git ignored)

Release 2.0.4 (14 Sep 2016)
---------------------------

* Log filesize of backup file #45 (bug fix)


Release 2.0.3 (14 Sep 2016)
---------------------------

* Log filesize of backup file #45


Release 2.0.2 (14 Sep 2016)
---------------------------

* send mail report #46

Release 2.0.1 (11 Sep 2016)
---------------------------

* use_7z option replaced by use_compression option #41
* mysqldump_options added to backup section #37


Release 2.0.0 (11 Sep 2016)
---------------------------

* **Consolidation of all scripts to one script: bash-cloud-backup.sh** #30
* use crudini (https://github.com/pixelb/crudini) to manipulate config files
* Display elapsed time #34


Release 1.1.3 (09 Sep 2016)
---------------------------

* improve rotate delete 

Release 1.1.2 (08 Sep 2016)
---------------------------

* tar options as parameter #13

Release 1.1.1 (08 Sep 2016)
---------------------------

* zip_file() function to init.sh #28
* Log file beautified #27

Release 1.1.0 (08 Sep 2016)
---------------------------

* rotate delete became more flexible:
   * setting ``days_rotation`` to 0 is disabled
   * with ``min_backups_in_rotation_period`` a number of backups can be kept, independently of their age

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
