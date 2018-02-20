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

echo "Restoring files using snapshot ${RESTIC_SNAPSHOT}"

echo "+================================+"
echo "| Starting restore process....   |"
echo "+================================+"

restic -r $RESTIC_REPOSITORY restore $RESTIC_SNAPSHOT --target / --cache-dir /tmp/ --include /data 2>&1

rc=$?

if [[ $rc == 0 ]]; then
    echo "Restore successfull" 
else
    echo "Restore failed with status ${rc}"
    restic unlock --cache-dir /tmp/
exit
fi


