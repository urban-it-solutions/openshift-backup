#!bin/sh
set +e

echo "+====================================================+"
echo "| Starting script to make DATABASE backup            |"
echo "+====================================================+"

case $DATABASE_TYPE in
    postgresql)
        echo "Will try to backup postgresql on service $DATABASE_SVC with user $DATABASE_USER and password $DATABASE_PASSWORD"
        export PGPASSWORD=$DATABASE_PASSWORD
        pg_dumpall -h $DATABASE_SVC -U $DATABASE_USER | restic backup -r $RESTIC_REPOSITORY --tag databases --tag $PROJECT_NAME --tag $DATABASE_SVC --hostname $PROJECT_NAME --stdin --stdin-filename $DATABASE_SVC.sql --cache-dir /tmp/    
        ;;
    mysql)
        echo "Will try to backup mysql on service $DATABASE_SVC with user $DATABASE_USER and password $DATABASE_PASSWORD"
        mysqldump -h $DATABASE_SVC -u $DATABASE_USER --password=$DATABASE_PASSWORD -C --all-databases | restic backup -r $RESTIC_REPOSITORY --stdin --tag databases --tag $PROJECT_NAME --tag $DATABASE_SVC --hostname $PROJECT_NAME --stdin-filename $DATABASE_SVC.sql --cache-dir /tmp/    
        ;;
esac

rc=$?

if [[ $rc == 0 ]]; then
    echo "dbdump and backup process was successful" 
else
    echo "Backup failed with status ${rc}"
    exit
fi


