#!/bin/bash

export BORG_PASSPHRASE=1234
a=$(su borg -c "borg list backup:files-etc"|awk 'NR ==1 {print $1}')
chmod 777 /mnt
su borg -c "borg mount backup:files-etc::$a /mnt"
su borg -c "ls -l /mnt"

#/bin/bash /root/scripts/borg_mount.sh
