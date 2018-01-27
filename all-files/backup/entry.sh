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
echo "===================================="

TOKEN="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"

echo "Starting backup jobs to backup all PVCs in current project"

echo "=============================================================="

echo "Will try to backup these PVCs:"

oc get pvc --no-headers=true | awk '{print $1}'

oc get pvc --no-headers=true | awk '{print $1}' | while read -r pvc ; do
    echo "Processing $pvc"
    # your code goes here now
    oc process backup-project-files	-p=CUSTOM_TAG=$pvc | oc create -f -
done




