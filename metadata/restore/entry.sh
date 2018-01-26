#!bin/sh
set +e

echo "Starting container ..."
echo "====================================="
echo "Parameters:"
echo "Source: project metadata $PROJECT_NAME"
echo "Destination: $RESTIC_DESTINATION"
echo "Repository password: "$RESTIC_PASSWORD
echo "Backup tag: " $RESTIC_TAG
echo "Project name: " $PROJECT_NAME
echo "Will keep $RESTIC_KEEP copies of data"
echo "===================================="

if [ $RESTIC_DESTINATION = "nfs" ]; then
    RESTIC_REPOSITORY="$RESTIC_REPOSITORY/$PROJECT_NAME"
    echo "Will restore from NFS, dir $RESTIC_REPOSITORY"
fi

if [ $RESTIC_DESTINATION = "s3" ]; then
    echo "Will restore from S3 object store - $RESTIC_S3_HOST:$RESTIC_S3_PORT"
    export RESTIC_REPOSITORY=s3:http://$RESTIC_S3_HOST:$RESTIC_S3_PORT/$PROJECT_NAME
fi

TOKEN="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
TMP_DIR=/var/tmp/$PROJECT_NAME
mkdir -p $TMP_DIR

echo "Working using token $TOKEN"

echo "Starting project restore...."

echo "=============================================================="

echo "Current snapshots in repository:"

restic -r $RESTIC_REPOSITORY snapshots --cache-dir /tmp/

echo "=============================================================="

#restic -r $RESTIC_REPOSITORY backup $TMP_DIR/*.yaml --tag metadata --tag $PROJECT_NAME --tag $RESTIC_TAG --hostname $PROJECT_NAME --cache-dir /tmp/ 2>&1

echo "Restoring files using snapshot ${RESTIC_SNAPSHOT}"

restic -r $RESTIC_REPOSITORY  restore $RESTIC_SNAPSHOT --target $TMP_DIR

rc=$?

if [[ $rc == 0 ]]; then
    echo "Restore successfull" 
else
    echo "Restore Failed with Status ${rc}"
    restic unlock
    exit
fi





