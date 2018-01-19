#!bin/sh
set +e

RESTIC_TAG=$DATABASE_SVC

echo "Starting container ..."
echo "====================================="
echo "Parameters:"
echo "Source - $DATABASE_TYPE on service $DATABASE_SVC"
echo "Destination: "$RESTIC_DESTINATION
echo "Repository password: "$RESTIC_PASSWORD
echo "Backup tag: " $RESTIC_TAG
echo "Project name: " $PROJECT_NAME
echo "Will keep $RESTIC_KEEP copies of dumps"
echo "===================================="

if [ $RESTIC_DESTINATION = "nfs" ]; then
    RESTIC_REPOSITORY="$RESTIC_REPOSITORY/$PROJECT_NAME/$RESTIC_TAG"
    echo "Will backup to NFS, dir $RESTIC_REPOSITORY"
    mkdir -p $RESTIC_REPOSITORY
    if [ ! -f "$RESTIC_REPOSITORY/config" ]; then
        echo "Restic repository '${RESTIC_REPOSITORY}' does not exists. Running restic init."
        restic init | true
    fi
fi

if [ $RESTIC_DESTINATION = "s3" ]; then
    echo "Will backup to S3 object store - $RESTIC_S3_HOST:$RESTIC_S3_PORT"
    export RESTIC_REPOSITORY=s3:http://$RESTIC_S3_HOST:$RESTIC_S3_PORT/$PROJECT_NAME
    restic -r $RESTIC_REPOSITORY init
fi


if [ $DATABASE_TYPE = "postgres" ]; then
    export PGPASSWORD=$DATABASE_PASSWORD
    echo "Starting postgresql backup with user $PG_USER"
    pg_dumpall -h $DATABASE_SVC -U $PG_USER | restic backup -r $RESTIC_REPOSITORY --hostname $RESTIC_TAG --stdin --stdin-filename $DATABASE_SVC.sql --tag $RESTIC_TAG --cache-dir /tmp/
fi

if [ $DATABASE_TYPE = "mariadb" ]; then
    echo "Starting mariadb backup with user $MYSQL_USER"
    mysqldump -h $DATABASE_SVC -u $MYSQL_USER --password=$DATABASE_PASSWORD -C --all-databases | restic backup -r $RESTIC_REPOSITORY --stdin --hostname $RESTIC_TAG --stdin-filename $DATABASE_SVC.sql --tag $RESTIC_TAG --cache-dir /tmp/
fi 

echo "Backup successfull!"
echo "==================================="
echo "Starting prune process..."
echo "-----------------------------------"

restic forget --keep-last $RESTIC_KEEP --prune --tag $RESTIC_TAG --cache-dir /tmp/

echo "-----------------------------------"
echo "Pruning complete!"
echo "==================================="
echo "Current backups in repositories:"

restic snapshots --cache-dir /tmp/

