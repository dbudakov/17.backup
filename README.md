## Домашнее задание
Настраиваем бэкапы с помощью BorgBackup  
Настроить стенд Vagrant с двумя виртуальными машинами server и backup.  
  
Настроить политику бэкапа директории /etc с клиента (server) на бекап сервер (backup):  
1) Бекап делаем раз в час  
2) Политика хранения бекапов: храним все за последние 30 дней, и по одному за предыдущие два месяца.  
3) Настроить логирование процесса бекапа в /var/log/ - название файла на ваше усмотрение  
4) Восстановить из бекапа директорию /etc с помощью опции Borg mount  
  
Результатом должен быть скрипт резервного копирования (политику хранения можно реализовать в нем же), а так же вывод команд терминала записанный с помощью script (или другой подобной утилиты)  
  
\* Настроить репозиторий для резервных копий с шифрованием ключом.  
  
** Настроить резервирование логического бекапа базы данных ( база на ваш выбор ) с помощью BorgBackup  

## Решение 
Задание выполнено с использованием `ansible`, для запуска скрипта ([backup-data.sh](https://github.com/dbudakov/17.backup/blob/master/homework/scripts/backup-data.sh)) используются юниты `systemctl`(можно посмотреть здесь [service](https://github.com/dbudakov/17.backup/blob/master/homework/roles/templates/borg_backup.service) и [timer](https://github.com/dbudakov/17.backup/blob/master/homework/roles/templates/borg_backup.timer)). Cкрипты во время деплоя кладутся в `/root/scripts/`, логи собирают вывод результата работы скрипов и кладутся в каталоги `/var/log/backup-etc` и `/var/log/backup-sql`, имена логов аналогичны именам бэкапов и завися от даты  
Для проверки на восстановление из бэкапа через `borg mount`, необходимо запустить скрипт([borg_mount.sh](https://github.com/dbudakov/17.backup/blob/master/homework/scripts/borg_mount.sh)) с сервера `files`:  
```
/bin/bash /root/scripts/borg_mount.sh
## ВНИМАНИЕ: скрипт может не отработать, из-за активности `borg`, необходимо запустить скрипт повторно!   
```
В результате будет показан список файлов из смонтированного бэкапа в директорию /mnt, но работать с этой дирректорией нужно от пользователся borg, т.к. на него завязана вся работа с бэкапами.   

Для `psql` снимается дамп и аналогично отправляется на backup'сервер репозиторий `backup:file-sql`    
Репозитории зашифрованы, через `repokey-blake2`, и для работы с ними нужны сгенерированные ключи помимо passphrase   
Требуемая политика хранения бэкапов соблюдена через атрибуты  `--keep-within=30d` и `--keep-monthly=2`  
```
borg prune \
  -v --list --show-rc \
  --keep-within=30d \
  --keep-monthly=2 \ 
  ${BACKUP_USER}@${BACKUP_HOST}:${BACKUP_REPO} 2>>/var/log/backup-etc/etc_backup-${LOGFILE}
```

Все созданные пользователи, а это `borg/postgres`, имеют пароль `vagrant`    
passphrase для работы с репозиториями `1234`    

### Дополнительная информация
При выполнении задания использовались следующие источники  
borg init --encryption [здесь](https://borgbackup.readthedocs.io/en/stable/usage/init.html)  
borg prune [здесь](https://borgbackup.readthedocs.io/en/stable/usage/prune.html)    
systemd (Русский)/Timers (Русский)[здесь](https://wiki.archlinux.org/index.php/Systemd_(%D0%A0%D1%83%D1%81%D1%81%D0%BA%D0%B8%D0%B9)/Timers_(%D0%A0%D1%83%D1%81%D1%81%D0%BA%D0%B8%D0%B9))  
pg_dump](https://postgrespro.ru/docs/postgresql/11/app-pgdump)  
Установка и запуск PostgreSQL на CentOS 7[здесь](https://www.dmosk.ru/miniinstruktions.php?mini=postgresql-install)    
lineinfile ansible [здесь](https://docs.ansible.com/ansible/latest/modules/lineinfile_module.html)    
assemble ansible [здесь](https://docs.ansible.com/ansible/latest/modules/assemble_module.html)   
Запустить команду от другого пользователя в Unix/Linux [здесь](https://linux-notes.org/zapustit-komandu-ot-drugogo-pol-zovatelya-v-unix-linux/)  
Как прописывать SSH-ключ пользователя для Ansible[здесь](https://webhamster.ru/mytetrashare/index/mtb0/1574858250rqmwmqb1qx)  
Могу ли я автоматически добавить новый хост в known_hosts?[здесь](https://qastack.ru/server/132970/can-i-automatically-add-a-new-host-to-known-hosts)  
Как игнорировать проверку подлинности SSH? [здесь](https://issue.life/questions/32297456)  
автоПАРОЛЬ ssh](https://forum.ubuntu.ru/index.php?topic=220985.0)  
Как передать пароль команде ssh / scp в Bash скрипте[здесь](https://itsecforu.ru/2019/02/13/%D0%BA%D0%B0%D0%BA-%D0%BF%D0%B5%D1%80%D0%B5%D0%B4%D0%B0%D1%82%D1%8C-%D0%BF%D0%B0%D1%80%D0%BE%D0%BB%D1%8C-%D0%BA%D0%BE%D0%BC%D0%B0%D0%BD%D0%B4%D0%B5-ssh-scp-%D0%B2-bash-%D1%81%D0%BA%D1%80%D0%B8%D0%BF/)  

