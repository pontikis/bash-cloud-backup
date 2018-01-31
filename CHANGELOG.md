bash-cloud-backup
=================

bash-cloud-backup is a bash script, which can be used to automate local and cloud backup in Linux/Unix machines.

Copyright Christos Pontikis http://www.pontikis.gr

License MIT https://raw.github.com/pontikis/bash-cloud-backup/master/MIT_LICENSE

    ATTENTION

Version 2.* is not compatible with previous (deprecated) version 1.*

Version 1 has its own branch (version1).

More at https://github.com/pontikis/bash-cloud-backup/blob/version1/README.md


Release 2.1.9 (31 Jan 2018)
---------------------------

* Preserve directories permissions and ownership in tar archive #82


Release 2.1.8 (25 Nov 2017)
---------------------------

* option mail_only_summary #78


Release 2.1.7 (06 Oct 2016)
---------------------------

* option disable_report_summary #77


Release 2.1.6 (06 Oct 2016)
---------------------------

* BUG FIX - Do not try to create main log directory if logfile keeping is disabled #76


Release 2.1.5 (03 Oct 2016)
---------------------------

* Leave blank both ``logfilepath`` and ``logfilename`` if you DO NOT WANT to keep the main log file #75
* option ``export_session_log_to`` #74


Release 2.1.4 (02 Oct 2016)
---------------------------

* modify report to present results at the top of the page (additionally) - problem with scrolling in huge pages in mobile devices (no way to go bottom) #55
* bash-cloud-backup tmp folder


Release 2.1.3 (01 Oct 2016)
---------------------------

* Bug fix: ``aws`` cli produces output with some non printing characters, so ``mail`` assigns octet stream MIME-type to log report and sends an attachment <noname> #71


Release 2.1.2 (29 Sep 2016)
---------------------------

* option report_errors #59 
* option export_errors #62


Release 2.1.1 (29 Sep 2016)
---------------------------

* improve docs


Release 2.1.0 (27 Sep 2016)
---------------------------

* Support ``ionice`` and ``nice`` with commands ``tar``, ``7z``, ``gzip``, ``mysqldump``, ``pg_dump``, ``aws``, ``s3cmd`` #60
* Support ``trickle`` bandwith shaper (on S3 uploads) #64
* Support of AWS Command Line Interface (AWS cli) #65
* skip-after option (do not backup ceaselessly inactive projects) #57



Release 2.0.9 (18 Sep 2016)
---------------------------

* Hide root processes (protect passwords to be exposed in command line) #53
* Custom scripts (became four) #47

    You may create and use 
    
    * ``on_backup_started.sh`` - before backup started
    * ``on_backup_finished.sh`` - after backup finished (and before Amazon S3 sync)
    * ``on_s3_sync_finished.sh`` - after Amazon S3 sync
    * ``on_logfile_created.sh`` - after logfile created and main script finished
    
    (these scripts are git ignored)


Release 2.0.8 (17 Sep 2016)
---------------------------
* Log tar errors (without v option) #52


Release 2.0.7 (17 Sep 2016)
---------------------------
* Improve error reporting #48
* Security: avoid passing (MySQL, Postgresql) passwords in command line


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
