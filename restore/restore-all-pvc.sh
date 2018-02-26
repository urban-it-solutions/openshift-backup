#!bin/sh
set +e


TOKEN="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"

echo "+==============================================================+"
echo "| Starting restore jobs to restore all PVCs in current project |"
echo "+==============================================================+"

echo "+=========================+"
echo "| Creating PVCs if needed |"
echo "+=========================+"

export API_TO_RESTORE="persistentvolumeclaims"
./metadata-restore.sh

echo "Will try to restore these PVCs:"

oc get pvc --no-headers=true | awk '{print $1}'

echo "==============================================================="

echo "Deleting previous jobs"
oc get pvc --no-headers=true | awk '{print $1}' | while read -r pvc ; do
    echo "Deleting old job for $pvc"
    oc delete job restore-files-for-pvc-$pvc
done

oc get pvc --no-headers=true | awk '{print $1}' | while read -r pvc ; do
    echo "Processing $pvc..."
    oc process restore-project-files -p=CUSTOM_TAG=$pvc -p=JOB_NAME=restore-files-for-pvc-$pvc -p=RESTIC_DESTINATION=$RESTIC_DESTINATION -p=RESTIC_HOST=$RESTIC_HOST -p=RESTIC_S3_PORT=$RESTIC_S3_PORT -p=AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID -p=AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY -p RESTIC_SNAPSHOT=$RESTIC_SNAPSHOT | oc create -f -
done

