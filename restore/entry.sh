#!bin/sh
set +e

echo "======================================================================"
echo " Parameters:                                                          "
echo " Will restore: $BACKUP_TYPE for project $PROJECT_NAME                  "
echo " Destination: $RESTIC_DESTINATION                                     "
echo " Host $RESTIC_S3_HOST:$RESTIC_S3_PORT                                 "
echo " Repository password: $RESTIC_PASSWORD                                "
echo " Backup tag: $RESTIC_TAG                                              "
echo "======================================================================"


case $RESTIC_DESTINATION in
    s3)
        echo "Will backup to S3 generic (like Minio) object store - $RESTIC_S3_HOST:$RESTIC_S3_PORT"
        export RESTIC_REPOSITORY=s3:http://$RESTIC_S3_HOST:$RESTIC_S3_PORT/$PROJECT_NAME/$BACKUP_TYPE/$RESTIC_TAG
    ;;
    aws)
        echo "Will backup to AMAZON S3 storage - $RESTIC_S3_HOST"
        export RESTIC_REPOSITORY=s3:$RESTIC_S3_HOST/$PROJECT_NAME/$BACKUP_TYPE/$RESTIC_TAG
    ;;
esac

case $BACKUP_TYPE in
    metadata)
        echo "Will try to restore project metadata"
        ./metadata-restore.sh
        ;;
    files)
        echo "Will try to restore files for PVC $RESTIC_TAG"
        ./files-restore.sh
        ;;
    databases)
        echo "Will try to restore database with service $DATABASE_SVC"
        ./databases-restore.sh
        ;;
esac

rc=$?

if [[ $rc == 0 ]]; then
    echo "Restore job finished successful" 
else
    echo "Restore failed with status ${rc}"
    exit
fi




