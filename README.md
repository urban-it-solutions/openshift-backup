# openshift-backup

backup/ - image to perform backups for project metadata, files (from one pvc) and databases (postgresql and mysql)

backup-all-pvc/ - image to perform backup for all pvc's in one project (requires templates in this project)

openshift-templates/ - templates to create jobs and accouts to do backup and restore

restore/ - image to perform restore from repositories for project metadata, files (for one pvc) and databases
