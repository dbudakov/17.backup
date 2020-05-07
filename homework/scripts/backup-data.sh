#!/usr/bin/env bash
LOGFILE=$(date +%Y-%m-%d_%H:%M:%S)

LOCKFILE=/tmp/lockfile
if [ -e ${LOCKFILE} ] && kill -0 `cat ${LOCKFILE}`; then
  echo "already running"
  exit
fi

# Make sure the lockfile is removed when we exit and then claim it
trap "rm -f ${LOCKFILE};" INT TERM EXIT
echo $$ > ${LOCKFILE}

# Configure backup
export BORG_PASSPHRASE=1234
#export BORG_PASSCOMMAND=1234
BACKUP_HOST='backup'
BACKUP_USER='borg'
BACKUP_REPO=$(hostname)-etc

echo $BACKUP_REPO > /var/log/backup-etc/etc_backup-${LOGFILE}

# Make backup
borg create \
  --stats --progress --show-rc \
  ${BACKUP_USER}@${BACKUP_HOST}:${BACKUP_REPO}::etc-${LOGFILE} \
  /etc 2>>/var/log/backup-etc/etc_backup-${LOGFILE}

# Prune backup
borg prune \
  -v --list --show-rc \
  --keep-within=30d \
  --keep-monthly=2 \
  ${BACKUP_USER}@${BACKUP_HOST}:${BACKUP_REPO} 2>>/var/log/backup-etc/etc_backup-${LOGFILE}

# Delete lockfile
rm -f ${LOCKFILE}
