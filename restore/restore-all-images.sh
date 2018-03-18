#!bin/sh
set +e


TOKEN="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
echo "Working using token $TOKEN"

echo "+================================================================+"
echo "| Starting restore jobs to restore all images in current project |"
echo "+================================================================+"

echo "+=================================+"
echo "| Creating imagestreams if needed |"
echo "+=================================+"

export API_TO_RESTORE="imagestreams"
./metadata-restore.sh

TMP_DIR=/var/tmp/$PROJECT_NAME/images
mkdir -p $TMP_DIR

echo "+=================================+"
echo "| Restoring images...             |"
echo "+=================================+"

restic -r $RESTIC_REPOSITORY restore $RESTIC_SNAPSHOT --target $TMP_DIR --cache-dir /tmp/ --include /data 2>&1

echo "+=================================+"
echo "| Pulling images into imagestreams|"
echo "+=================================+"

oc get is -o custom-columns='NAME:.metadata.name' --no-headers=true | while read -r is_name ; do
    echo "Processing $is_name..."
    is_path=$(oc get is $is_name --no-headers | awk '{print $2}')
    is_tag=$(oc get is $is_name --no-headers | awk '{print $3}')
    skopeo copy --dest-creds backup-sa:$TOKEN --dest-tls-verify=false docker-archive:$TMP_DIR/$is_name docker://$is_path
done





