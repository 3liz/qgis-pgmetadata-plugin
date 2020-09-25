## Automatic generation of structure SQL files

### Schema pgmetadata

Generation of the `pgmetadata` schema SQL files is made via

```bash
cd install/sql
./export_database_structure_to_SQL.sh pgmetadata pgmetadata
```

This script will remove and regenerate the SQL files based on the `pg_dump` tool, by connecting to the database referenced by the PostgreSQL service `pgmetadata`. You need to pass the parameter `pgmetadata`, which is the name of the schema, and the name of the target folder (relative to `install/sql`)

It splits the content of the SQL dump into one file per database object type:

* functions
* tables, sequences, default values
* views
* indexes
* triggers
* constraints (pk, unique, fk, etc.)
* comments

The script needs :
* `pg_dump`
* `pg_restore`
* `rename` available with APT
