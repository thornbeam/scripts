#!/bin/bash
 
BACKUP_PATH="./bkp"
EXCLUDE_DIR='{"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"}'
SOURCE_DIR="/"
 
sudo rsync -aAXv ${SOURCE_DIR} --exclude=${EXCLUDE_DIR} ${BACKUP_PATH}
 
if [ $? -eq 0 ]; then
    echo "Backup completed successfully"
else
    echo "Some error occurred during backup"
fi
