#!/bin/sh
set +e

echo "======================================================================"
echo " Parameters:                                                          "
echo " Will backup: $BACKUP_TYPE for project $PROJECT_NAME                  "
echo " Destination: $RESTIC_DESTINATION                                     "
echo " Host $RESTIC_HOST:$RESTIC_S3_PORT                                       "
echo " Repository password: $RESTIC_PASSWORD                                "
echo " Backup tag: $RESTIC_TAG                                              "
echo " Will keep $RESTIC_KEEP copies of data                                "
echo " Will exclude files from target directory with mask $RESTIC_EXCLUDE   "
echo "======================================================================"


case $RESTIC_DESTINATION in
    s3)
        echo "Will backup to S3 generic (like Minio) object store - $RESTIC_HOST:$RESTIC_S3_PORT"
        export RESTIC_REPOSITORY=s3:http://$RESTIC_HOST:$RESTIC_S3_PORT/$PROJECT_NAME/$BACKUP_TYPE/$RESTIC_TAG
    ;;
    aws)
        echo "Will backup to AMAZON S3 storage - $RESTIC_HOST"
        export RESTIC_REPOSITORY=s3:$RESTIC_HOST/$PROJECT_NAME/$BACKUP_TYPE/$RESTIC_TAG
    ;;
esac

restic -r $RESTIC_REPOSITORY init

echo ""

case $BACKUP_TYPE in
    metadata)
        echo "Will try to backup project metadata"
        ./metadata-backup.sh
        ;;
    files)
        echo "Will try to backup files from one PVC"
        ./files-backup.sh
        ;;
    databases)
        echo "Will try to backup database"
        ./databases-backup.sh
        ;;
    all-pvcs)
        echo "Will try to backup all pvcs in the project"
        ./all-pvcs-backup.sh
        ;;
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
