bash-cloud-backup
=================

bash-cloud-backup is a bash script, which can be used to automate local and cloud backup in Linux/Unix machines.

RELEASE 2.0.0 (11 Sep 2016)

CHANGELOG https://github.com/pontikis/bash-cloud-backup/blob/master/CHANGELOG.md

    ATTENTION

Version 2.* is not compatible with previous (deprecated) version 1.*

Version 1 has its own branch (version1).

More at https://github.com/pontikis/bash-cloud-backup/blob/version1/README.md

Features
--------

* bash-cloud-backup keeps rotating compressed tarballs or certain directories or files or databases.
* it uses ``tar`` (for archiving) and ``gzip`` (for compression) or ``7z`` (for compression and encryption - RECOMMENDED).
* Backup files are stored in specified directories and (optionally) deleted with rotation (14 days default).
* Amazon S3 sync: After local filesystem backup has been completed, the backup directory can be synchronized with Amazon S3, using ``s3cmd sync`` (optional but recommended).

Copyright
---------
Christos Pontikis (http://www.pontikis.gr)

License
-------
MIT (see https://opensource.org/licenses/MIT)

Configuration files
-------------------

* ``conf.default/global.conf``: global options (sample file)
* ``conf.default/backup.conf``: configuration of a backup set (sample file)

Scripts
-------

* ``bash-cloud-backup.sh``: the main script
* ``custom.sh``: custom commands (you may create it, if needed)

Logs
----
bash-cloud-backup is keeping logs (define log directory in ``global.conf``).

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


External software
-----------------

* crudini: (**REQUIRED**) https://github.com/pixelb/crudini (for Debian: ``apt-get install crudini``). See also http://www.pixelbeat.org/programs/crudini/
* p7zip: (OPTIONAL but highly recommended) http://p7zip.sourceforge.net (for Debian: ``apt-get install p7zip-full``) a port of 7za.exe for POSIX systems. 7z is an Excellent archiving software offering high compression ratio and Strong AES-256 encryption. See http://www.7-zip.org.
* s3tools: (OPTIONAL) http://s3tools.org/ (for Debian: ``apt-get install s3cmd``) Start with ``s3cmd --configure``  http://s3tools.org/s3cmd-howto


Amazon S3 account
-----------------

For cloud backup, an Amazon S3 account is needed (http://aws.amazon.com/s3/)

Setup using git (recommended)
-----------------------------
### installation

    cd /path/to/scripts
    git clone https://github.com/pontikis/bash-cloud-backup.git

### get updates

    cd /path/to/scripts/bash-cloud-backup
    git fetch
    git merge origin


If you are interested on (deprecated) version 1

### installation

    cd /path/to/scripts
    git clone https://github.com/pontikis/bash-cloud-backup.git
    cd /path/to/scripts/bash-cloud-backup
    git checkout -b version1 origin/version1

### get updates

    cd /path/to/scripts/bash-cloud-backup
    git fetch
    git merge origin/version1


Setup by download
-----------------

If ``git`` is not available, download the source:

https://github.com/pontikis/bash-cloud-backup/archive/master.zip

If you are interested on (deprecated) version 1

https://github.com/pontikis/bash-cloud-backup/archive/version1.zip

Configuration
-------------

``bash-cloud-backup`` uses two configuration files (samples available in ``/conf.default`` folder):

* ``global.conf`` which defines global parameters
* ``backup.conf`` which defines which files or databases will be backed up (a backup set)

By default, bash-cloud-backup expects these files to be 

* ``/etc/bash-cloud-backup/global.conf``
* ``/etc/bash-cloud-backup/backup.conf``

You may define your own ``global.conf`` and as many ``backup.conf`` you like. So:

### Edit ``backup.conf`` (global parameters) 

**ATTENTION**: remember to configure properly ``global.conf`` after each update

    cp conf.default/global.conf /etc/bash-cloud-backup/global.conf
    nano /etc/bash-cloud-backup/global.conf

### Directories

``bash-cloud-backup`` will create all directories you define in configuration files (assuming it has the required permissions)
    
### Edit ``backup.conf`` (create your own backup set)

**ATTENTION**: remember to configure properly ``backup.conf`` after each update

    cp conf.default/backup.conf /etc/bash-cloud-backup/backup.conf
    nano /etc/bash-cloud-backup/backup.conf

### You may add custom commands at ``custom.sh`` (optional)

    nano custom.sh


### **SECURITY NOTE**

Ensure that all executable (*.sh) and directories are mod 700 and text files 600:

    chown root:root bash-cloud-backup.sh
    chmod 700 bash-cloud-backup.sh
    
    chown root:root conf/global.conf
    chmod 600 conf/global.conf
    chown root:root conf/backup.conf
    chmod 600 conf/backup.conf

Run
---

To perform backup, call (as ``root`` in most cases)

    bash-cloud-backup.sh

You may use your own ``global.conf`` and as many ``backup.conf`` you like. In this case, use:

    bash-cloud-backup.sh -g /path/to/myglobal.conf -b /path/to/mybackup.conf


Cron automation
---------------

    su -l root
    crontab -e
    0 1 * * * /usr/bin/nice -n19 /root/scripts/bash-cloud-backup.sh | mail -s "Daily backup" admin@yourdomain.com #Daily Backup

(in this example, every night at 01:00)