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

#restic -r $RESTIC_REPOSITORY backup $TMP_DIR/*.yaml --tag metadata --tag $PROJECT_NAME --tag $RESTIC_TAG --hostname $PROJECT_NAME --cache-dir /tmp/ 2>&1

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
echo "| Starting project metadata      |"
echo "+================================+"

while read api; do
    echo "Restoring $api for $PROJECT_NAME"
    oc create -f $TMP_DIR/$PROJECT_NAME-$api.json
    echo "=============================================================="
done < /restic-openshift-oapi.cfg

while read api; do
    echo "Restoring $api for $PROJECT_NAME"
    oc create -f $TMP_DIR/$PROJECT_NAME-$api.json
    echo "=============================================================="
done < /restic-openshift-api.cfg

echo "+================================+"
echo "| Finished restoring process     |"
echo "+================================+"



