#!/usr/bin/env bash
export $(grep -v '^#' .env | xargs)

if [ -n "$(git status --porcelain -uno)" ];
then
    echo "Git working directory is not clean. Aborting."
    exit 1
fi

docker exec postgis bash -c "apt-get install -y rename" > /dev/null

echo 'Generating SQL files'
docker exec postgis bash -c "cd /tests_directory/${PLUGIN_NAME}/install/sql/ && ./export_database_structure_to_SQL.sh test ${SCHEMA}"

docker exec postgis bash -c "cd /tests_directory/${PLUGIN_NAME}/install/sql/${SCHEMA} && chmod 777 *.sql"
