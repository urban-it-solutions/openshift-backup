#!bin/sh
set +e

echo "+====================================================+"
echo "| Starting script to make DATABASE backup            |"
echo "+====================================================+"

case $DATABASE_TYPE in
    postgresql)
        export PGPASSWORD=$DATABASE_PASSWORD
        if [[ "$DATABASE_NAME" ]]
            echo "Will try to backup ONLY postgresql $DATABASE_NAME on service $DATABASE_SVC with user $DATABASE_USER and password $DATABASE_PASSWORD"
            pg_dump -h $DATABASE_SVC -U $DATABASE_USER $DATABASE_NAME | restic backup -r $RESTIC_REPOSITORY --tag databases --tag $PROJECT_NAME --tag $DATABASE_SVC --hostname $PROJECT_NAME --stdin --stdin-filename $DATABASE_SVC-$DATABASE_NAME.sql --cache-dir /tmp/
        else
            echo "Will try to backup ALL postgresql databases on service $DATABASE_SVC with user $DATABASE_USER and password $DATABASE_PASSWORD"
            pg_dumpall -h $DATABASE_SVC -U $DATABASE_USER | restic backup -r $RESTIC_REPOSITORY --tag databases --tag $PROJECT_NAME --tag $DATABASE_SVC --hostname $PROJECT_NAME --stdin --stdin-filename $DATABASE_SVC-$DATABASE_NAME.sql --cache-dir /tmp/
        fi
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

echo "Writing credentials into file $DATABASE_SVC.creds"
echo "$DATABASE_SVC $DATABASE_USER $DATABASE_PASSWORD" | restic backup -r $RESTIC_REPOSITORY --tag databases --tag $PROJECT_NAME --tag $DATABASE_SVC-creds --hostname $PROJECT_NAME --stdin --stdin-filename $DATABASE_SVC.creds --cache-dir /tmp/
 

