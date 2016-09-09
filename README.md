bash-cloud-backup
=================

bash-cloud-backup is a set of bash scripts, which can be used to automate local and cloud backup in Linux/Unix machines.

RELEASE 1.1.3 (09 Sep 2016)

CHANGELOG https://github.com/pontikis/bash-cloud-backup/blob/master/CHANGELOG.md

Features
--------

* bash-cloud-backup keeps rotating compressed tarballs or certain directories or files or MySQL databases.
* it uses ``tar`` (for archiving) and ``gzip`` (for compression) or ``7z`` (for compression and encryption - RECOMMENDED).
* Backup files are stored in specified directories and deleted with rotation (14 days default).
* Amazon S3 sync: After local filesystem backup has been completed, the backup directory can be synchronized with Amazon S3, using ``s3cmd sync`` (optional but recommended).

Copyright
---------
Christos Pontikis (http://www.pontikis.gr)

License
-------
MIT (see https://opensource.org/licenses/MIT)

Configuration files
-------------------

* conf/config.sh: main configuration script

* conf/db-mysql: mysql databases to backup
* conf/sites: web server directories to backup
* conf/sites_tar_options: tar options for each site (optional)
* conf/scripts: scripts to backup
* conf/conf-files: configuration files to backup
* conf/docs: documents to backup


Scripts
-------

* bkp_all.sh: the main script

* bkp_mysql.sh: Performs backup of selected mysql databases (in conf/db-mysql).
* bkp_www.sh: Performs backup of selected web server directoties (in conf/sites).
* bkp_conf.sh: Rerforms backup of selected system configuration files (in conf/conf-files).
* bkp_scripts.sh: Performs backup of selected scripts (in conf/scripts).
* bkp_docs.sh: Performs backup of selected documents (in conf/docs).

* s3-plain-sync.sh: backup directory is synchronized with Amazon S3, using s3cmd sync

* common/init.sh: common tasks and utility functions

* custom.sh: custom commands


Logs
----
bash-cloud-backup is keeping logs (define log directory in ``config.sh``).

You should take care for logfile rotation.

    nano /etc/logrotate.d/bash-cloud-backup
    
Add something like
    
    /path/to/backup.log {
        weekly
        missingok
        rotate 14
        notifempty
        create
    }


External software (optional)
----------------------------

* s3tools: http://s3tools.org/ (for Debian: ``apt-get install s3cmd``) Start with ``s3cmd --configure``  http://s3tools.org/s3cmd-howto
* p7zip: http://p7zip.sourceforge.net (for Debian: ``apt-get install p7zip-full``) a port of 7za.exe for POSIX systems. 7z is an Excellent archiving software offering high compression ratio and Strong AES-256 encryption. See http://www.7-zip.org.

Amazon S3 account
-----------------

For cloud backup, an Amazon S3 account is needed (http://aws.amazon.com/s3/)

Setup using git (recommended)
-----------------------------
### installation
    cd /path/to/scripts
    git clone https://github.com/pontikis/bash-cloud-backup.git

### get updates
    cd /path/to/bash-cloud-backup
    git fetch
    git merge origin

Setup by download
-----------------

If ``git`` is not available, download the source:

https://github.com/pontikis/bash-cloud-backup/archive/master.zip

Configuration
-------------

**SECURITY NOTE**: Ensure that all executable (*.sh) and directories are mod 700 and text files 600:

    cd /path/to/scripts
    chown -R root:root bash-cloud-backup
    cd bash-cloud-backup
    chmod 700 *.sh
    cd conf.default
    chmod 600 *
    chmod 700 config.sh

edit ``conf/config.sh`` (parameters) - **ATTENTION**: remember to configure properly ``config.sh`` after each update

    cp -R conf.default conf
    cd conf
    nano config.sh
    
edit ``bkp_all.sh`` (uncomment procedures to be executed) - **ATTENTION**: remember to configure properly ``bkp_all.sh`` after each update

    cp bkp_all.default.sh bkp_all.sh 
    nano bkp_all.sh 

configure ``custom.sh`` (optional)

    cp custom.default.sh custom.sh 
    nano custom.sh

Run
---

To perform backup, call ``bkp_all.sh`` as root (in most cases)

Each one of ``bkp_*`` or ``s3_*`` can run as stand-alone script.

Cron automation
---------------

    su -l root
    crontab -e
    0 1 * * * /usr/bin/nice -n19 /root/scripts/bash-cloud-backup/bkp_all.sh | mail -s "Daily backup" admin@yourdomain.com #Daily Backup

(in this example, every night at 01:00)
