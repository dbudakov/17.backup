#!/usr/bin/env bash
LOGFILE=$(date +%Y-%m-%d_%H:%M:%S)
LOCKFILE=/tmp/lockfile
if [ -e ${LOCKFILE} ] && kill -0 `cat ${LOCKFILE}`; then
echo "already running"
exit
fi

# Make sure the lockfile is removed when we exit and then claim it
trap "rm -f ${LOCKFILE}; exit" INT TERM EXIT
echo $$ > ${LOCKFILE}

# Configure backup
export BORG_PASSPHRASE=1234
#export BORG_PASSCOMMAND=1234
BACKUP_HOST='backup'
BACKUP_USER='postgres'
BACKUP_REPO=$(hostname)-sql

echo $BACKUP_REPO > /var/log/backup-sql/sql_backup-${LOGFILE}

## Before backup
#pg_dumpall -U postgres -f /tmp/dump.sql
echo 1234 | su postgres -c 'pg_dump -f /tmp/dump.sql'

# Make backup
borg create \
--stats --progress --show-rc \
${BACKUP_USER}@${BACKUP_HOST}:${BACKUP_REPO}::sql-${LOGFILE} \
/tmp/dump.sql 2>>/var/log/backup-sql/sql_backup-${LOGFILE}


# Prune backup
borg prune \
-v --list --show-rc \
${BACKUP_USER}@${BACKUP_HOST}:${BACKUP_REPO} \
--keep-daily=7 \
--keep-weekly=4 2>>/var/log/backup-sql/sql_backup-${LOGFILE}
## сохраняет по последнему бэкапу за последние 7 дней сохраняет по последнему бэкапу за последние 4 недели

# Delete lockfile
rm -f ${LOCKFILE}
