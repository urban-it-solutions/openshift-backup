#!bin/sh
set +e

echo "+=====================================+"
echo "| Starting script to make FILE backup |"
echo "+=====================================+"

if [ $RESTIC_DESTINATION = "s3" ]; then
    echo "Will backup to S3 object store - $RESTIC_S3_HOST:$RESTIC_S3_PORT"
    export RESTIC_REPOSITORY=s3:http://$RESTIC_S3_HOST:$RESTIC_S3_PORT/$PROJECT_NAME/$RESTIC_TAG
    restic -r $RESTIC_REPOSITORY init
fi

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


