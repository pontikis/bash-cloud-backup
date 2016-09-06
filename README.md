bash-cloud-backup
=================

bash-cloud-backup is a set of bash scripts, which can be used to automate local and cloud backup in Linux/Unix machines.

RELEASE 1.0.4 (06 Sep 2016)

CHANGELOG https://github.com/pontikis/bash-cloud-backup/blob/master/CHANGELOG.md

LOCAL FILESYSTEM BACKUP
-----------------------

* bash-cloud-backup keeps rotating compressed tarballs or certain directories or files or MySQL databases.
* tar (for archiving) and gzip (for compression) or 7z (for compression and encryption - RECOMMENDED) are being used.
* Backup files are stored in specified directories and are deleted using rotating (14 days default).
* AMAZON S3 SYNC: After local filesystem backup has been completed, the backup directory can be synchronized with Amazon S3, using ``s3cmd sync`` (optional but highly recommended).

COPYRIGHT
---------
Christos Pontikis (pontikis@gmail.com -  http://www.pontikis.gr)

LICENSE
-------
MIT (see https://opensource.org/licenses/MIT)

CONF FILES included in bash-cloud-backup
----------------------------------------

* conf/initialize.sh: main configuration script
* conf/db-mysql: mysql databases to backup
* conf/sites: web server directories to backup
* conf/scripts: scripts to backup
* conf/conf-files: configuration files to backup
* conf/docs: documents to backup


SCRIPTS included in bash-cloud-backup
-------------------------------------

* bkp_all.sh: the main script

* bkp_mysql.sh: Performs backup of selected mysql databases (in conf/db-mysql).
* bkp_www.sh: Performs backup of selected web server directoties (in conf/sites).
* bkp_conf.sh: Rerforms backup of selected system configuration files (in conf/conf-files).
* bkp_scripts.sh: Performs backup of selected scripts (in conf/scripts).
* bkp_docs.sh: Performs backup of selected documents (in conf/docs).

* s3-plain-sync.sh: backup directory is synchronized with Amazon S3, using s3cmd sync

* custom.sh: custom commands


LOGS
----
bash-cloud-backup is keeping logs (define log directory in ``initialize.sh``).

You should take care for logfile rotation.

EXTERNAL SOFTWARE
-----------------

* s3tools: http://s3tools.org/ (for Debian: ``apt-get install s3cmd``) Start with ``s3cmd --configure``  http://s3tools.org/s3cmd-howto
* p7zip: a port of 7za.exe for POSIX systems (http://p7zip.sourceforge.net). 7z is an Excellent archiving software offering high compression ratio and Strong AES-256 encryption. See http://www.7-zip.org. For Debian: ``apt-get install p7zip-full``. 

AMAZON S3 ACCOUNT
-----------------

For cloud backup, an Amazon S3 account is needed (http://aws.amazon.com/s3/)

SETUP USING GIT (recommended)
-----------------------------
# setup (using git)
    cd /root/scripts
    git clone https://github.com/pontikis/bash-cloud-backup.git

# get updates (using git)
    cd /root/scripts
    git fetch
    git merge origin

SETUP by download
-----------------
If ``git`` is not available, download the source:

https://github.com/pontikis/bash-cloud-backup/archive/master.zip

CONFIGURATION
-------------

IMPORTANT SECURITY ISSUE: Ensure that all executable (*.sh) and directories are mod 700 and text files 600:

    cd /path/to/scripts
    chown -R root:root bash-cloud-backup
    ch bash-cloud-backup
    chmod 700 *.sh
    cd conf.default
    chmod 600 *
    chmod 700 initialize.sh

edit conf/initialize.sh (parameters and Amazon S3 credentials)

    cp -R conf.default conf
    cd conf
    nano initialize.sh
    
edit bkp_all.sh (uncomment procedures to be executed)    

    cp bkp_all.default.sh bkp_all.sh 
    nano bkp_all.sh 

configure custom.sh (optional)

    cp custom.default.sh custom.sh 
    nano custom.sh

RUN
---

To perform backup, call ``bkp_all.sh`` (you may use CRON for automation).

Each one of ``bkp_*`` or ``s3_*`` can run as stand-alone script.

CRON AUTOMATION
---------------

    su -l root
    crontab -e
    0 1 * * * /usr/bin/nice -n19 /root/scripts/bash-cloud-backup/bkp_all.sh | mail -s "Daily backup" admin@yourdomain.com #Daily Backup

(every night at 01:00)