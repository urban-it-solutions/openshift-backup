#!/bin/sh
set +e

echo "====================================================================="
echo "Parameters:"
echo "Source: /data"
echo "Destination: "$RESTIC_REPOSITORY
echo "Repository password: "$RESTIC_PASSWORD
echo "Backup tag: " $RESTIC_TAG
echo "Project name: " $PROJECT_NAME
echo "Will keep $RESTIC_KEEP copies of data"
echo "Will exclude files from target directory with mask $RESTIC_EXCLUDE"
echo "====================================================================="

if [ $RESTIC_DESTINATION = "s3" ]; then
    echo "Will backup to S3 object store - $RESTIC_S3_HOST:$RESTIC_S3_PORT"
    export RESTIC_REPOSITORY=s3:http://$RESTIC_S3_HOST:$RESTIC_S3_PORT/$PROJECT_NAME
    restic -r $RESTIC_REPOSITORY init
fi

case $BACKUP_TYPE in
    metadata)
        echo "Will try to backup project metadata"
        metadata-backup.sh
    files)
        echo "Will try to backup files from one PVC"
        files-backup.sh
esac

echo "Job done"
