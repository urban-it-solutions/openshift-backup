#!bin/sh
set +e

RESTIC_TAG=$DATABASE_SVC

echo "+=================================================+"
echo "| Starting script to make DATABASE backup         |"
echo "+=================================================+"

if [ $DATABASE_TYPE = "postgres" ]; then
    export PGPASSWORD=$DATABASE_PASSWORD
    echo "Starting postgresql backup with user $PG_USER"
    pg_dumpall -h $DATABASE_SVC -U $PG_USER | restic backup -r $RESTIC_REPOSITORY --hostname $RESTIC_TAG --stdin --stdin-filename $DATABASE_SVC.sql --tag $RESTIC_TAG --cache-dir /tmp/
fi

if [ $DATABASE_TYPE = "mariadb" ]; then
    echo "Starting mariadb backup with user $MYSQL_USER"
    mysqldump -h $DATABASE_SVC -u $MYSQL_USER --password=$DATABASE_PASSWORD -C --all-databases | restic backup -r $RESTIC_REPOSITORY --stdin --hostname $RESTIC_TAG --stdin-filename $DATABASE_SVC.sql --tag $RESTIC_TAG --cache-dir /tmp/
fi 



