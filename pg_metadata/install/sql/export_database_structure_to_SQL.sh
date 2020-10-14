#!/bin/sh
#
# Explode PostgreSQL database dump into several files, one per type
# LICENCE: GPL 2
# AUTHOR: 3LIZ

echo "# CHECK INPUT PARAMETERS service and schema"
if [ -n "$1" ]; then
  echo "# POSTGRESQL SERVICE: $1"
  SERVICE=$1
else
  echo "ERROR: No PostgreSQL service given as second parameter";
  exit;
fi
if [ -n "$2" ]; then
  echo "# GIVEN SCHEMA: $2"
  SCHEMA=$2
else
  echo "# DEFAULT SCHEMA: pgmetadata";
  SCHEMA="pgmetadata"
fi
echo ""

OUTDIR=$SCHEMA

# Remove previous SQL files
ls ./"$OUTDIR"/*.sql | xargs rm
mkdir -p "$OUTDIR"

# STRUCTURE
# Dump database structure
pg_dump service=$SERVICE --schema-only -n $SCHEMA --no-acl --no-owner -Fc -f "$OUTDIR/dump"

# Loop through DB object types and extract SQL
I=10
for ITEM in FUNCTION "TABLE|SEQUENCE|DEFAULT" VIEW INDEX TRIGGER CONSTRAINT COMMENT; do
    echo $ITEM
    # Extract list of objects for current item
    pg_restore --no-acl --no-owner -l $OUTDIR/dump | grep -E "$ITEM" > "$OUTDIR/$ITEM";
    # Extract SQL for these objects
    pg_restore -f "$OUTDIR"/"$I"_"$ITEM".sql --no-acl --no-owner -L "$OUTDIR/$ITEM" "$OUTDIR/dump";
    # Remove file containing list of objects
    rm "$OUTDIR/$ITEM";
    # Simplify comments inside SQL files
    perl -i -0pe 's/\n--\n-- Name: (TABLE )?(COLUMN )?(.+); Type:.+\n--\n\n/\n-- $3\n/g' "$OUTDIR"/"$I"_"$ITEM".sql;
    # Remove audit trigger (added afterwards)
    if [ $ITEM = 'TRIGGER' ]
    then
        sed -i '/audit_trigger/d' "$OUTDIR"/"$I"_"$ITEM".sql;
    fi
    # Remove SET function to remove some compatibility issues between PostgreSQL versions
    sed -i "s#SET idle_in_transaction_session_timeout = 0;##g" "$OUTDIR"/"$I"_"$ITEM".sql;
    # Remove SET search_path
    sed -i "s#SELECT pg_catalog.set_config('search_path', '', false);##g" "$OUTDIR"/"$I"_"$ITEM".sql;
    # Remove default_table_access_method
    sed -i "s#SET default_table_access_method = heap##g" "$OUTDIR"/"$I"_"$ITEM".sql;
    # Replace FOR EACH ROW EXECUTE FUNCTION (pg13) by FOR EACH ROW EXECUTE PROCEDURE (still ok for Pg13)
    sed -i "s#FOR EACH ROW EXECUTE FUNCTION#FOR EACH ROW EXECUTE PROCEDURE#g" "$OUTDIR"/"$I"_"$ITEM".sql;
    # Rename
    rename -f 's#\|#_#g' "$OUTDIR"/"$I"_"$ITEM".sql;
    # Increment I
    I=$(($I+10));
done

# Remove dump
rm "$OUTDIR/dump"

# NOMENCLATURE
echo "GLOSSARY"
if [ $SCHEMA = 'pgmetadata' ]
then
    pg_dump service=$SERVICE --data-only --inserts --column-inserts -n $SCHEMA --no-acl --no-owner --table "pgmetadata.glossary" -f "$OUTDIR"/90_GLOSSARY.sql
    sed -i "s#SET idle_in_transaction_session_timeout = 0;##g" "$OUTDIR"/"90_GLOSSARY.sql"
    sed -i "s#SELECT pg_catalog.set_config('search_path', '', false);##g" "$OUTDIR"/"90_GLOSSARY.sql"
fi
