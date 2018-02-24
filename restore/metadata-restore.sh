#!bin/sh
set +e

TOKEN="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
TMP_DIR=/var/tmp/$PROJECT_NAME
mkdir -p $TMP_DIR

echo "=============================================================="
echo "Working using token $TOKEN"
echo "=============================================================="
echo "Current snapshots in repository:"

restic -r $RESTIC_REPOSITORY snapshots --cache-dir /tmp/

echo "=============================================================="

echo "Restoring metadata using snapshot ${RESTIC_SNAPSHOT}"

restic -r $RESTIC_REPOSITORY restore $RESTIC_SNAPSHOT --target $TMP_DIR --cache-dir /tmp/

rc=$?

if [[ $rc == 0 ]]; then
    echo "Restore files with metadata successfull" 
else
    echo "Restore files with metadata failed with status ${rc}"
    restic unlock
    exit
fi

echo "+================================+"
echo "| Remove volumeName from pvc     |"
echo "+================================+"

sed -i '/volumeName:/d' $TMP_DIR/$PROJECT_NAME-persistent-volumeclaims.yaml

echo "+================================+"
echo "| Starting metadata restore...   |"
echo "+================================+"

while read api; do
    echo "Restoring $api for $PROJECT_NAME"
    oc create -f $TMP_DIR/$PROJECT_NAME-$api.yaml
    echo "=============================================================="
done < /restic-openshift-oapi.cfg

while read api; do
    echo "Restoring $api for $PROJECT_NAME"
    oc create -f $TMP_DIR/$PROJECT_NAME-$api.yaml
    echo "=============================================================="
done < /restic-openshift-api.cfg

echo "+================================+"
echo "| Restoring process finished.    |"
echo "+================================+"



