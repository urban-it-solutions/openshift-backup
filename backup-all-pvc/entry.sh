#!bin/sh
set +e

echo "======================================================================"
echo " Parameters:                                                          "
echo " Will backup: $BACKUP_TYPE for project $PROJECT_NAME                  "
echo " Destination: $RESTIC_DESTINATION                                     "
echo " Host $RESTIC_S3_HOST:$RESTIC_S3_PORT                                       "
echo " Repository password: $RESTIC_PASSWORD                                "
echo " Backup tag: $RESTIC_TAG                                              "
echo " Will keep $RESTIC_KEEP copies of data                                "
echo " Will exclude files from target directory with mask $RESTIC_EXCLUDE   "
echo "======================================================================"

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
    oc process backup-project-files	-p=CUSTOM_TAG=$pvc -p=JOB_NAME=backup-files-from-pvc-$pvc -p=RESTIC_DESTINATION=$RESTIC_DESTINATION -p=RESTIC_HOST=$RESTIC_HOST -p=RESTIC_S3_PORT=$RESTIC_S3_PORT -p=RESTIC_EXCLUDE=$RESTIC_EXCLUDE -p=RESTIC_KEEP=$RESTIC_KEEP -p=AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID -p=AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY | oc create -f -
done




