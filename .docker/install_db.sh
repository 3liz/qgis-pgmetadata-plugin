#!/usr/bin/env bash
export $(grep -v '^#' .env | xargs)

docker cp pg_service.conf postgis:/etc/postgresql-common/

echo 'Installation from latest version'
docker exec postgis bash -c "psql service=test -c 'DROP SCHEMA IF EXISTS ${SCHEMA} CASCADE;'" > /dev/null
docker exec postgis bash -c "psql service=test -f /tests_directory/${PLUGIN_NAME}/install/sql/00_initialize_database.sql" > /dev/null
for sql_file in `ls -v ../${PLUGIN_NAME}/install/sql/${SCHEMA}/*.sql`; do
  echo "${sql_file}"
  docker exec postgis bash -c "psql service=test -f /tests_directory/${PLUGIN_NAME}/${sql_file}" > /dev/null;
  done;
