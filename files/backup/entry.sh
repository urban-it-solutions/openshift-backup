#!bin/sh
set +e

echo "Starting container ..."
echo "====================================="
echo "Parameters:"
echo "Source: /data"
echo "Destination: "$RESTIC_REPOSITORY
echo "Repository password: "$RESTIC_PASSWORD
echo "Backup tag: " $RESTIC_TAG
echo "Project name: " $PROJECT_NAME
echo "Will keep $RESTIC_KEEP copies of data"
echo "Will exclude files from target directory with mask $RESTIC_EXCLUDE"
echo "===================================="

if [ $RESTIC_DESTINATION = "nfs" ]; then
    RESTIC_REPOSITORY="$RESTIC_REPOSITORY/$PROJECT_NAME/$RESTIC_TAG"
    echo "Will backup to NFS, dir $RESTIC_REPOSITORY"
    mkdir -p $RESTIC_REPOSITORY
    if [ ! -f "$RESTIC_REPOSITORY/config" ]; then
        echo "Restic repository '${RESTIC_REPOSITORY}' does not exists. Running restic init."
        restic init | true
    fi
fi

if [ $RESTIC_DESTINATION = "s3" ]; then
    echo "Will backup to S3 object store - $RESTIC_S3_HOST:$RESTIC_S3_PORT"
    export RESTIC_REPOSITORY=s3:http://$RESTIC_S3_HOST:$RESTIC_S3_PORT/$PROJECT_NAME/$RESTIC_TAG
    restic -r $RESTIC_REPOSITORY init
fi

echo "Starting backup...."

restic backup /data --tag files --tag $PROJECT_NAME --tag $RESTIC_TAG --hostname $PROJECT_NAME --exclude=$RESTIC_EXCLUDE --cache-dir /tmp/ 2>&1

rc=$?

if [[ $rc == 0 ]]; then
    echo "Backup successfull" 
else
    echo "Backup failed with Status ${rc}"
    restic unlock
exit

fi


echo "==================================="
echo "Starting prune process..."
echo "-----------------------------------"

restic forget --keep-last $RESTIC_KEEP --prune --tag files --tag $PROJECT_NAME --tag $RESTIC_TAG --cache-dir /tmp/

echo "-----------------------------------"
echo "Pruning complete!"
echo "==================================="
echo "Current backups in repositories:"

restic snapshots

