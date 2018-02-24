#!bin/sh
set +e

echo "Current snapshots in repository:"

restic -r $RESTIC_REPOSITORY snapshots --cache-dir /tmp/ 2>&1

rc=$?

if [[ $rc == 0 ]]; then
    echo "Repository found" 
else
    echo "Repository not found. Status ${rc}"
    exit
fi

echo "Restoring database for service ${DATABASE_SVC} using snapshot ${RESTIC_SNAPSHOT}"

echo "+================================+"
echo "| Starting restore process....   |"
echo "+================================+"

restic -r $RESTIC_REPOSITORY restore $RESTIC_SNAPSHOT --target /tmp/ --include $DATABASE_SVC.creds --cache-dir /tmp/ 2>&1

DATABASE_USER=$(cat /tmp/$DATABASE_SVC.creds | awk '{print $2}')
DATABASE_PASSWORD=$(cat /tmp/$DATABASE_SVC.creds | awk '{print $3}')

case $DATABASE_TYPE in
    postgresql)
        echo "Will try to restore postgresql on service $DATABASE_SVC with user $DATABASE_USER and password $DATABASE_PASSWORD"
        export PGPASSWORD=$DATABASE_PASSWORD
        restic -r $RESTIC_REPOSITORY dump $RESTIC_SNAPSHOT --$DATABASE_SVC.sql | pg_restore -h $DATABASE_SVC -U $DATABASE_USER -C
        ;;
    mysql)
        echo "Will try to restore mysql on service $DATABASE_SVC with user $DATABASE_USER and password $DATABASE_PASSWORD"
        mysqldump -h $DATABASE_SVC -u $DATABASE_USER --password=$DATABASE_PASSWORD -C --all-databases | restic backup -r $RESTIC_REPOSITORY --stdin --tag databases --tag $PROJECT_NAME --tag $DATABASE_SVC --hostname $PROJECT_NAME --stdin-filename $DATABASE_SVC.sql --cache-dir /tmp/    
        ;;
esac

