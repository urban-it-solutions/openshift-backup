#!bin/sh
set +e

echo "+=================================================+"
echo "| Starting script to make PROJECT METADATA backup |"
echo "+=================================================+"

TOKEN="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
TMP_DIR=/var/tmp/$PROJECT_NAME
mkdir -p $TMP_DIR

echo "Working using token $TOKEN"

echo "Starting project metadata backup...."

echo "=============================================================="

echo "Get project metadata"

echo "Get project name"
curl --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
    -H "Authorization: Bearer $TOKEN" \
    -H 'Accept: application/json' \
    https://openshift.default.svc.cluster.local/oapi/v1/projects/$PROJECT_NAME > $TMP_DIR/$PROJECT_NAME-project.json

while read api; do
    echo "Perform backup $api on https://openshift.default.svc.cluster.local/oapi/v1/namespaces/$PROJECT_NAME/$api"
    curl --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
    -H "Authorization: Bearer $TOKEN" \
    -H 'Accept: application/json' \
    https://openshift.default.svc.cluster.local/oapi/v1/namespaces/$PROJECT_NAME/$api > $TMP_DIR/$PROJECT_NAME-$api.json
done < /restic-openshift-oapi.cfg

while read api; do
    echo "Perform backup $api on https://openshift.default.svc.cluster.local/api/v1/namespaces/$PROJECT_NAME/$api"
    curl --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
    -H "Authorization: Bearer $TOKEN" \
    -H 'Accept: application/json' \
    https://openshift.default.svc.cluster.local/api/v1/namespaces/$PROJECT_NAME/$api > $TMP_DIR/$PROJECT_NAME-$api.json
    echo "=============================================================="
done < /restic-openshift-api.cfg

echo "=============================================================="

restic -r $RESTIC_REPOSITORY backup $TMP_DIR/*.json --tag metadata --tag $PROJECT_NAME --tag $RESTIC_TAG --hostname $PROJECT_NAME --cache-dir /tmp/ 2>&1

rc=$?

if [[ $rc == 0 ]]; then
    echo "Metadata backup using restic successfull" 
else
    echo "Metadata backup using restic command filed with status ${rc}"
    restic unlock
    exit
fi




