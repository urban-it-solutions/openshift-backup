#!bin/sh
set +e

TOKEN="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"

echo "+==============================================================+"
echo "| Starting backup jobs to backup all PVCs in current project   |"
echo "+==============================================================+"

echo "Will try to backup these PVCs:"

oc get pvc --no-headers=true | awk '{print $1}'

echo "==============================================================="

echo "Deleting previous jobs"
oc get pvc --no-headers=true | awk '{print $1}' | while read -r pvc ; do
    echo "Deleting old job for $pvc"
    oc delete job backup-files-from-pvc-$pvc
done

oc get pvc --no-headers=true | awk '{print $1}' | while read -r pvc ; do
    echo "Processing $pvc..."
    oc process backup-project-files	-p=CUSTOM_TAG=$pvc -p=JOB_NAME=backup-files-from-pvc-$pvc -p=RESTIC_EXCLUDE=$RESTIC_EXCLUDE | oc create -f -
done