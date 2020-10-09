#!/usr/bin/env bash
export $(grep -v '^#' .env | xargs)

docker cp pg_service.conf postgis:/etc/postgresql-common/

echo "Test if PostgreSQL is ready"
until docker exec postgis bash -c "psql service=test -c 'SELECT version()'" 1>  /dev/null 2>&1
do
  echo "."
  sleep 1
done
echo "PostgreSQL is now ready !"

echo 'Installation from latest version'
docker exec postgis bash -c "psql service=test -c 'DROP SCHEMA IF EXISTS ${SCHEMA} CASCADE;'" > /dev/null
docker exec postgis bash -c "psql service=test -f /tests_directory/${PLUGIN_NAME}/install/sql/00_initialize_database.sql" > /dev/null
for sql_file in `ls -v ../${PLUGIN_NAME}/install/sql/${SCHEMA}/*.sql`; do
  echo "${sql_file}"
  docker exec postgis bash -c "psql service=test -f /tests_directory/${PLUGIN_NAME}/${sql_file}" > /dev/null;
  done;
