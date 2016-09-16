bash-cloud-backup
=================

bash-cloud-backup is a bash script, which can be used to automate local and cloud backup in Linux/Unix machines.

RELEASE 2.0.7 (16 Sep 2016)

CHANGELOG https://github.com/pontikis/bash-cloud-backup/blob/master/CHANGELOG.md

    ATTENTION

Version 2.* is not compatible with previous (deprecated) version 1.*

Version 1 has its own branch (version1).

More at https://github.com/pontikis/bash-cloud-backup/blob/version1/README.md

Features
--------

* bash-cloud-backup keeps rotating compressed tarballs of certain directories/files or databases.
* supported databases MySQL (using ``mysqldump``), Postgresql (using ``pg_dump``)
* it uses ``tar`` (for archiving) and ``gzip`` (for compression) or ``7z`` (for compression and encryption - RECOMMENDED).
* backup files are stored in specified directories and (optionally) deleted with rotation (14 days default).
* Amazon S3 sync: After local filesystem backup has been completed, the backup directory can be synchronized with Amazon S3, using ``s3cmd sync`` (optional but recommended).
* detailed logs, error reporting, email report
* advanced customization using configuration files

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

You may create and use 

* ``custom1.sh`` - after backup finished and before Amazon S3 sync
* ``custom2.sh`` - after Amazon S3 sync
* ``custom3.sh`` - after logfile created and main script finished

(these scripts are git ignored)

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

### Edit ``global.conf`` (global parameters) 

    cp conf.default/global.conf /etc/bash-cloud-backup/global.conf
    nano /etc/bash-cloud-backup/global.conf

For instructions, see sample ``conf.default/global.conf`` 

https://github.com/pontikis/bash-cloud-backup/blob/master/conf.default/global.conf

**ATTENTION**: remember to configure properly ``global.conf`` after each update


### Edit ``backup.conf`` (create your own backup set)

    cp conf.default/backup.conf /etc/bash-cloud-backup/backup.conf
    nano /etc/bash-cloud-backup/backup.conf

For instructions, see sample ``conf.default/backup.conf`` 

https://github.com/pontikis/bash-cloud-backup/blob/master/conf.default/backup.conf

**ATTENTION**: remember to configure properly ``backup.conf`` after each update


### Directories

``bash-cloud-backup`` will create all directories you define in configuration files (assuming it has the required permissions)


### You may add custom commands (optional)

    nano custom1.sh
    nano custom2.sh
    nano custom3.sh


### SECURITY NOTICE

#### About MySQL password

DO NOT expose ``root`` password to create backups. Create a 'read only' user for backup purposes.
In most cases the following commands are enough:

    GRANT SELECT,RELOAD,FILE,SUPER,LOCK TABLES,SHOW VIEW ON *.*
    TO 'bkpadm'@'localhost' IDENTIFIED BY 'bkpadm_password_here'
    WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;
    flush privileges;

Create ``.my.cnf`` file in home folder and add

    [client]
    password=bkpadm_password_here

then

    chmod 600 .my.cnf

**So YOU DO NOT NEED TO PROVIDE mysql_password**

More at http://dev.mysql.com/doc/refman/5.7/en/password-security-user.html



#### Secure files permissions

It is recommended that all executable (*.sh) are mod 700 and text files 600:

    chown root:root bash-cloud-backup.sh
    chmod 700 bash-cloud-backup.sh
    
    chown root:root /etc/bash-cloud-backup/*.conf
    chmod 600 /etc/bash-cloud-backup/*.conf


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