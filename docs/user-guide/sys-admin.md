# Deploying within an organization

The system administrator can hide PgMetadata Processing algorithms from normal users by adding an environment
variable `QGIS_PGMETADATA_END_USER_ONLY`. If this variable exists, Processing algorithms won't be displayed.
It's possible to use the `QGIS3.ini` file instead with `end_user_only`.

In the `QGIS3.ini` file within an organisation, you may want some hardcoded configuration :

```ini
[pgmetadata]
auto_open_dock=true
end_user_only=true
connection_names=Connection 1;Connection 2;Connection 3

[Plugins]
pg_metadata=true
```
