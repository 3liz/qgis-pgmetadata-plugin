#!/usr/bin/env bash
export $(grep -v '^#' .env | xargs)

if [ -n "$(git status --porcelain -uno)" ];
then
    echo "Git working directory is not clean. Aborting."
    exit 1
fi

echo "Installing the service file"
docker cp pg_service.conf postgis:/etc/postgresql-common/

echo "Test if PostgreSQL is ready"
until docker exec postgis bash -c "psql service=test -c 'SELECT version()'" 1>  /dev/null 2>&1
do
  echo "."
  sleep 1
done
echo "PostgreSQL is now ready !"

echo "Installation from version ${INSTALL_VERSION}"
docker exec postgis bash -c "psql service=test -c 'DROP SCHEMA IF EXISTS ${SCHEMA} CASCADE;'" > /dev/null
docker exec postgis bash -c "psql service=test -f /tests_directory/${PLUGIN_NAME}/test/data/install/sql/00_initialize_database.sql" > /dev/null
for sql_file in `ls -v ../${PLUGIN_NAME}/test/data/install/sql/${SCHEMA}/*.sql`; do
  echo "${sql_file}"
  docker exec postgis bash -c "psql service=test -f /tests_directory/${PLUGIN_NAME}/${sql_file}" > /dev/null;
  done;

echo 'Run migrations'
for migration in `ls -v ../${PLUGIN_NAME}/install/sql/upgrade/*.sql`; do
  echo "${migration}"
  docker exec postgis bash -c "psql service=test -v 'ON_ERROR_STOP=1' -f /tests_directory/${PLUGIN_NAME}/${migration}" > /dev/null;
  if [ $? -ne 0 ]
  then
    echo "Migration ${migration} is incorrect"
    exit 1;
  fi
  done;

echo 'Generate doc'
docker exec postgis bash -c "apt-get update && apt-get install -y rename" > /dev/null
docker exec postgis bash -c "cd /tests_directory/${PLUGIN_NAME}/install/sql/ && ./export_database_structure_to_SQL.sh test ${SCHEMA}"
docker exec postgis bash -c "cd /tests_directory/${PLUGIN_NAME}/install/sql/${SCHEMA} && chmod 777 *.sql"

git diff
[[ -z $(git status --porcelain -uno) ]]
exit $?
