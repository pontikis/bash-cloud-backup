bash-cloud-backup
=================

bash-cloud-backup is a bash script, which can be used to automate local and cloud backup in Linux/Unix machines.

RELEASE 2.1.8 (25 Nov 2017)

CHANGELOG https://github.com/pontikis/bash-cloud-backup/blob/master/CHANGELOG.md



    ATTENTION

Version 2.* is not compatible with previous (deprecated) version 1.*

Version 1 has its own branch (version1).

More at https://github.com/pontikis/bash-cloud-backup/blob/version1/README.md


Features
--------

* bash-cloud-backup keeps rotating compressed tarballs of certain directories/files or databases.
* supported databases 
    * MySQL (using ``mysqldump``) - http://linuxcommand.org/man_pages/mysqldump1.html
    * Postgresql (using ``pg_dump``) - https://www.postgresql.org/docs/current/static/app-pgdump.html
* it uses ``tar`` (for archiving) and ``gzip`` (for compression) or ``7z`` (for compression and AES256 encryption - RECOMMENDED).
* backup files are stored in specified directories and (optionally) deleted with rotation (14 days default).
* Amazon S3 sync: After local backup has been completed, the backup directory can be synchronized with Amazon S3, using ``aws s3 sync`` or ``s3cmd sync`` (optional but recommended).
* detailed logs, error reporting, email report
* option to use ``nice`` and ``ionice``
* option to use``trickle`` bandwidth shaper
* advanced customization using configuration files

(NOTE: ``7-zip`` does not store the owner/group of the file. On Linux/Unix, in order to backup directories keeping permissions you must use ``tar``.)

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

You may create and use custom scripts (see below - Configuration)


Logs
----

### main log file

bash-cloud-backup is keeping logs (as defined in ``global.conf``).

    logfilepath=/root/backup/log
    logfilename=bash-cloud-backup.log

The main log file is ``logfilepath/logfilename`` 

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

Leave blank **both** ``logfilepath`` and ``logfilename`` if you DO NOT WANT to keep the main log file.


### temporary log files

Inside ``tmp_path`` bash-cloud-backup is keeping temporary log files, in order to create current session log file. This will be sent by email if you set value to ``mail_to`` parameter.  
After current session finished, both the temporary path and its contents are deleted.

* logfile_tmp_header="$tmp_path/header.log"
* logfile_tmp_main="$tmp_path/main.log"
* logfile_tmp_errors="$tmp_path/errors.log"
* logfile_tmp_time_elapsed="$tmp_path/time_elapsed.log"
* logfile_tmp_whole_session="$tmp_path/whole_session.log"

Keep ``tmp_path`` outside backup root. 

If you do not set a value, the default value is applied:

    tmp_path=/tmp/bash-cloud-backup


External software
-----------------

* crudini: (**REQUIRED**) https://github.com/pixelb/crudini 
  
  Installation (for Debian):
   
        apt-get install crudini

  See also http://www.pixelbeat.org/programs/crudini/


* p7zip: (OPTIONAL but highly recommended) http://p7zip.sourceforge.net

   Installation (for Debian):

        apt-get install p7zip-full
  
  It is a port of 7za.exe for POSIX systems. 7z is an Excellent archiving software offering high compression ratio and Strong AES-256 encryption. See http://www.7-zip.org.

  7z man page http://linux.die.net/man/1/7z


* trickle bandwidth shaper: (OPTIONAL) https://linux.die.net/man/1/trickle

   Installation (for Debian):

        apt-get install trickle


* AWS Command Line Interface: (OPTIONAL) https://aws.amazon.com/cli/ 

   Installation (for Debian):

        apt-get install awscli

   Configure with
 
        aws configure  


* s3tools: (OPTIONAL) http://s3tools.org/ 

   Installation (for Debian):

        apt-get install s3cmd 

   Configure with
 
        s3cmd --configure  

   More at http://s3tools.org/s3cmd-howto


**NOTE**: to select which AWS front-end you will use, set value to parameter ``amazon_front_end`` in ``global.conf``.


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

You may create and use 

* ``on_backup_started.sh`` - before backup started
* ``on_backup_finished.sh`` - after backup finished (and before Amazon S3 sync)
* ``on_s3_sync_finished.sh`` - after Amazon S3 sync
* ``on_logfile_created.sh`` - after logfile created and main script finished

(these scripts are git ignored)


Security
--------

### About MySQL password

DO NOT expose ``root`` password to create backups. Create a 'read only' user for backup purposes.
In most cases the following commands are enough:

    GRANT SELECT,RELOAD,FILE,SUPER,LOCK TABLES,SHOW VIEW ON *.*
    TO 'bkpadm'@'localhost' IDENTIFIED BY 'bkpadm_password_here'
    WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;
    flush privileges;

Create ``.my.cnf`` file in home folder and add

    [client]
    password="bkpadm_password_here"

or

    [mysqldump]
    password="bkpadm_password_here"

(double quotes are permitted in this file and in some cases of special characters in password are necessary)

then

    chmod 600 .my.cnf

**So YOU DO NOT NEED TO PROVIDE mysql_password**

More at http://dev.mysql.com/doc/refman/5.7/en/password-security-user.html


### About Postgresql password

DO NOT expose ``postgres`` password to create backups. Create a 'read only' user for backup purposes.
In most cases the following commands are enough:

    CREATE USER bkpadm SUPERUSER  password 'password';
    ALTER USER bkpadm set default_transaction_read_only = on;

In Postgresql you may use ``.pgpass`` file (similar to MySQL ``.my.cnf``, but more advanced)

More https://www.postgresql.org/docs/9.5/static/libpq-pgpass.html

**So YOU DO NOT NEED TO PROVIDE pg_password**

However, providing a password in ``bash-cloud-backup`` configuration files is quite secure, as ``PGPASSWORD`` ENVIRONMENTAL VARIABLE is used.


### About 7z password

It would be nice if ``7z`` could use enviromental variables or text fies for password retrieving. Not an easy way to do it. Alternatively, use ``hidepid`` to hide root processes to other users - see below.


### How to protect passwords to be exposed in command line

When a 7z (or any other) process is running, all command line arguments (including password) can be exposed to other users using programs like ``ps``, ``top``,  ``htop`` etc. You may prevent this remounting ``/proc`` with ``hideid=2`` option.

**Linux kernel version 3.2+ is required.** 
 
See here https://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/commit/?id=0499680a42141d86417a8fbaa8c8db806bea1201

You may set this option permanently (using ``/etc/fstab``)

To find with which options ``/proc`` has been mounted in your system, use 

    cat /proc/mounts

(in this example ``/proc`` had been mounted with options ``rw,nosuid,nodev,noexec,relatime``)

With ``bash-cloud-backup`` you may use custom scripts

    nano on_backup_started.sh

Set ``hidepid=2`` option

    /bin/mount -o remount,rw,nosuid,nodev,noexec,relatime,hidepid=2 /proc

After script finished return to previous status

    nano on_s3_sync_finished.sh

Set ``hidepid=0`` option

    /bin/mount -o remount,rw,nosuid,nodev,noexec,relatime,hidepid=0 /proc

**So, while ``bash-cloud-backup`` is running, nobody can see running procesess (eg mysql, postgres, 7z etc) except their owner of course, usually ``root``**


A WORKAROUND FOR OLDER SYSTEMS

In older systems (Linux kernel version < 3.2) you may change mod of ``ps``, ``top``, ``htop`` etc

at the beginning of the script

    chmod 700 /bin/ps
      
return to original status at the end of the script.

    chmod 755 /bin/ps


### Secure files permissions

It is recommended all executable (*.sh) to be mod 700 and text files 600:

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
    0 1 * * * /root/scripts/bash-cloud-backup/bash-cloud-backup.sh #Daily Backup

(in this example, every night at 01:00)
