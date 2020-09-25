#!/usr/bin/env bash
export $(grep -v '^#' .env | xargs)

chmod 777 -R "${PWD}"/../docs/database
docker run \
  -v "${PWD}/../docs/database:/output" \
  --network=docker_${NETWORK} \
  etrimaille/schemaspy-pg:latest \
  -t pgsql-mat \
  -dp /drivers \
  -host db \
  -db gis \
  -u docker \
  -p docker \
  -port 5432 \
  -s ${SCHEMA}
