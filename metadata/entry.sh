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
    echo "Will backup to NFS, dir $RESTIC_REPOSITORY"
    mkdir -p $RESTIC_REPOSITORY
    if [ ! -f "$RESTIC_REPOSITORY/config" ]; then
        echo "Restic repository '${RESTIC_REPOSITORY}' does not exists. Running restic init."
        restic init | true
    fi
fi

if [ $RESTIC_DESTINATION = "s3" ]; then
    echo "Will backup to S3 object store - $RESTIC_S3_HOST:$RESTIC_S3_PORT"
    export RESTIC_REPOSITORY=s3:http://$RESTIC_S3_HOST:$RESTIC_S3_PORT/$PROJECT_NAME
    restic -r $RESTIC_REPOSITORY init
fi

TOKEN="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
TMP_DIR=/var/tmp/$PROJECT_NAME
mkdir -p $TMP_DIR

echo "Working using token $TOKEN"

echo "Starting project backup...."

echo "=============================================================="

echo "Backuping Project description..."

curl --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
    -H "Authorization: Bearer $TOKEN" \
    -H 'Accept: application/yaml' \
    https://openshift.default.svc.cluster.local/oapi/v1/projects/$PROJECT_NAME > $TMP_DIR/$PROJECT_NAME-project.yaml

while read api; do
    echo "Backuping $api on https://openshift.default.svc.cluster.local/oapi/v1/namespaces/$PROJECT_NAME/$api"
    curl --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
    -H "Authorization: Bearer $TOKEN" \
    -H 'Accept: application/yaml' \
    https://openshift.default.svc.cluster.local/oapi/v1/namespaces/$PROJECT_NAME/$api > $TMP_DIR/$PROJECT_NAME-$api.yaml
done < /restic-openshift-oapi.cfg

while read api; do
    echo "Backuping $api on https://openshift.default.svc.cluster.local/api/v1/namespaces/$PROJECT_NAME/$api"
    curl --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
    -H "Authorization: Bearer $TOKEN" \
    -H 'Accept: application/yaml' \
    https://openshift.default.svc.cluster.local/api/v1/namespaces/$PROJECT_NAME/$api > $TMP_DIR/$PROJECT_NAME-$api.yaml
    echo "=============================================================="
done < /restic-openshift-api.cfg

echo "=============================================================="

restic -r $RESTIC_REPOSITORY backup $TMP_DIR/*.yaml --tag metadata --tag $PROJECT_NAME --tag $RESTIC_TAG --hostname $PROJECT_NAME --cache-dir /tmp/ 2>&1

rc=$?

if [[ $rc == 0 ]]; then
    echo "Backup Successfull" 
else
    echo "Backup Failed with Status ${rc}"
    restic unlock
    exit
fi


echo "==================================="
echo "Starting prune process..."
echo "-----------------------------------"

restic -r $RESTIC_REPOSITORY forget --keep-last $RESTIC_KEEP --prune --tag metadata --tag $PROJECT_NAME --tag $RESTIC_TAG --cache-dir /tmp/

rc=$?

if [[ $rc == 0 ]]; then
    echo "Prune Successfull" 
else
    echo "Prune Failed with Status ${rc}"
    restic unlock
    exit
fi


echo "-----------------------------------"
echo "Pruning complete!"
echo "==================================="
echo "Current backups in repositories:"

restic -r $RESTIC_REPOSITORY snapshots --cache-dir /tmp/
