#!bin/sh
set +e

echo "+=====================================+"
echo "| Starting script to make FILE backup |"
echo "+=====================================+"

echo "Total size for backup:"

df -h /data | awk {'print $3'} | sed '2!D'

echo "Starting backup...."

restic backup /data --tag files --tag $PROJECT_NAME --tag $RESTIC_TAG --hostname $PROJECT_NAME --exclude=$RESTIC_EXCLUDE --cache-dir /tmp/ 2>&1

rc=$?

if [[ $rc == 0 ]]; then
    echo "File backup using restic was successfull" 
else
    echo "File backup using restic command filed with status ${rc}"
    restic unlock
    exit
fi


