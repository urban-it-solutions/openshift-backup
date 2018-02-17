#!/bin/sh
set +e

echo "+======================================================================+"
echo "| Parameters:                                                          |"
echo "| Will backup: $BACKUP_TYPE for project $PROJECT_NAME                  |"
echo "| Destination: $RESTIC_REPOSITORY                                      |"
echo "| Repository password: $RESTIC_PASSWORD                                |"
echo "| Backup tag: $RESTIC_TAG                                              |"
echo "| Will keep $RESTIC_KEEP copies of data                                |"
echo "| Will exclude files from target directory with mask $RESTIC_EXCLUDE   |"
echo "=======================================================================+"

echo ""

if [ $RESTIC_DESTINATION = "s3" ]; then
    echo "Will backup to S3 object store - $RESTIC_S3_HOST:$RESTIC_S3_PORT"
    export RESTIC_REPOSITORY=s3:http://$RESTIC_S3_HOST:$RESTIC_S3_PORT/$PROJECT_NAME/$BACKUP_TYPE/$RESTIC_TAG
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

rc=$?

if [[ $rc == 0 ]]; then
    echo "Backup job finished successful" 
else
    echo "Backup failed with status ${rc}"
    exit
fi

echo "+===================================+"
echo "|Starting prune process...          |"
echo "+===================================+"

restic -r $RESTIC_REPOSITORY forget --keep-last $RESTIC_KEEP --prune --tag $BACKUP_TYPE --tag $PROJECT_NAME --tag $RESTIC_TAG --cache-dir /tmp/

rc=$?

if [[ $rc == 0 ]]; then
    echo "Prune Successfull!" 
else
    echo "Prune Failed with Status ${rc}"
    restic unlock
    exit
fi

echo "===================================="
echo ""
echo "+==================================+"
echo "| Current backups in repositories: |"
echo "+==================================+"

restic -r $RESTIC_REPOSITORY snapshots --cache-dir /tmp/

echo "Finished."
