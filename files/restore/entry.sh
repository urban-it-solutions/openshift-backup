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
echo "Will exclude files from target directory with mask $RESTIC_EXCLUDE"
echo "===================================="

if [ $RESTIC_DESTINATION = "nfs" ]; then
    RESTIC_REPOSITORY="$RESTIC_REPOSITORY/$PROJECT_NAME/$RESTIC_TAG"
    echo "Will restore from NFS, dir $RESTIC_REPOSITORY"
    
fi

if [ $RESTIC_DESTINATION = "s3" ]; then
    echo "Will restore from S3 object store - $RESTIC_S3_HOST:$RESTIC_S3_PORT"
    export RESTIC_REPOSITORY=s3:http://$RESTIC_S3_HOST:$RESTIC_S3_PORT/$PROJECT_NAME/$RESTIC_TAG
fi

echo "Starting restore...."

echo "=============================================================="

echo "Current snapshots in repository:"

restic -r $RESTIC_REPOSITORY snapshots --cache-dir /tmp/ 2>&1

rc=$?

if [[ $rc == 0 ]]; then
    echo "Repository found" 
else
    echo "Repository not found. Status ${rc}"
    exit
fi

echo "=============================================================="

restic -r $RESTIC_REPOSITORY restore $RESTIC_SNAPSHOT --target / --cache-dir /tmp/ --include /data 2>&1

rc=$?

if [[ $rc == 0 ]]; then
    echo "Restore successfull" 
else
    echo "Restore failed with status ${rc}"
    restic unlock --cache-dir /tmp/
exit
fi


