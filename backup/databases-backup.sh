#!bin/sh
set +e

echo "+====================================================+"
echo "| Starting script to make DATABASE backup            |"
echo "| Will look for config in /pg_backup & /mysql_backup |"
echo "+====================================================+"

while read DBPARAM; do
    DATABASE_SVC=$(echo $DBPARAM | awk '{print $1}')
    DATABASE_USER=$(echo $DBPARAM | awk '{print $2}')
    PGPASSWORD=$(echo $DBPARAM | awk '{print $3}')
    echo "Perform backup for database with address $DATABASE_SVC"
    pg_dumpall -h $DATABASE_SVC -U $DATABASE_USER | restic backup -r $RESTIC_REPOSITORY --tag databases --tag $PROJECT_NAME --tag $DATABASE_SVC --hostname $PROJECT_NAME --stdin --stdin-filename $DATABASE_SVC.sql --cache-dir /tmp/
done < /pg_backup

while read DBPARAM; do
    DATABASE_SVC=$(echo $DBPARAM | awk '{print $1}')
    DATABASE_USER=$(echo $DBPARAM | awk '{print $2}')
    DATABASE_PASSWORD=$(echo $DBPARAM | awk '{print $3}')
    echo "Perform backup for database with address $DATABASE_SVC"
    mysqldump -h $DATABASE_SVC -u $DATABASE_USER --password=$DATABASE_PASSWORD -C --all-databases | restic backup -r $RESTIC_REPOSITORY --stdin --tag databases --tag $PROJECT_NAME --tag $DATABASE_SVC --hostname $PROJECT_NAME --stdin-filename $DATABASE_SVC.sql --cache-dir /tmp/
done < /mysql_backup

restic backup /mysql_backup --tag databases --tag $PROJECT_NAME --tag $RESTIC_TAG --hostname $PROJECT_NAME --cache-dir /tmp/ 2>&1
restic backup /pg_backup --tag databases --tag $PROJECT_NAME --tag $RESTIC_TAG --hostname $PROJECT_NAME --cache-dir /tmp/ 2>&1


