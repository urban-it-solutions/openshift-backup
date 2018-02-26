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

echo "+=============================================+"
echo "| Remove annotations from pvc's descriptions  |"
echo "+=============================================+"

sed -i '/pv.kubernetes.io/d' $TMP_DIR/$PROJECT_NAME-persistentvolumeclaims.yaml

sed -i '/volumeName:/d' $TMP_DIR/$PROJECT_NAME-persistentvolumeclaims.yaml

echo "+===============================================+"
echo "| Check if there are any storage classes exist  |"
echo "+===============================================+"

STORAGE_CLASS=`oc get sc`                                                       
                                                                            
if [ -z $STORAGE_CLASS ]; then
    echo "No storage classes found in your environment. Removing storage class definition from pvcs" 
    sed -i '/storageClassName/d' $TMP_DIR/$PROJECT_NAME-persistentvolumeclaims.yaml
else
    echo "Storage classes found in your environment:"
    echo "${STORAGE_CLASS}"
    echo "PVCs will be created with storage class description."
    echo "If storage class will not be found - you have to fix it by yourself!!!"
    echo "Means that you have to recreate PVCs manually"
fi

echo "+================================+"
echo "| Starting metadata restore...   |"
echo "+================================+"

if [[ -n $API_TO_RESTORE ]]; then
    echo "Will restore ONLY $API_TO_RESTORE in the project!"
    oc create -f $TMP_DIR/$PROJECT_NAME-$API_TO_RESTORE.yaml
    exit
fi

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



