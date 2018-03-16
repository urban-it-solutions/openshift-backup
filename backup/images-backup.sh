#!bin/sh
set +e

echo "+=================================================+"
echo "| Starting script to make images backup |"
echo "+=================================================+"

TOKEN="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
TMP_DIR=/var/tmp/$PROJECT_NAME
mkdir -p $TMP_DIR

echo "Working using token $TOKEN"

echo "=============================================================="

echo "Get images from image streams into temp dir"
    
oc get is -o custom-columns='NAME:.metadata.name' --no-headers=true | while read -r is_name ; do
    echo "Processing $is_name..."
    is_path=$(oc get is $is_name --no-headers | awk '{print $2":" $3}')
    skopeo copy --src-tls-verify=false --scr-creds backup-sa:$TOKEN docker://$is_path tarball:$TMP_DIR/$is_name.tar.gz
done

restic -r $RESTIC_REPOSITORY backup $TMP_DIR/*.tar.gz --tag images --tag $PROJECT_NAME --tag $RESTIC_TAG --hostname $PROJECT_NAME --cache-dir /tmp/ 2>&1

rc=$?

if [[ $rc == 0 ]]; then
    echo "Images backup using restic successfull" 
else
    echo "Images backup using restic command failed with status ${rc}"
    restic unlock
    exit
fi