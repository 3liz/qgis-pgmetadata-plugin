# Sys admin

## Deploying within an organization

When [QGIS is deployed within an organization](https://docs.qgis.org/testing/en/docs/user_manual/introduction/qgis_configuration.html?highlight=organization#deploying-qgis-within-an-organization),
the system administrator can hide administration Processing tools from normal users and also set the default
path where PgMetadata is installed.

Example of a `QGIS3.ini` file which activates the plugin automatically and set 3 connections where PgMetadata is
installed :

```ini
[pgmetadata]
auto_open_dock=true
end_user_only=true
connection_names=Connection 1;Connection 2;Connection 3

[Plugins]
pg_metadata=true
```
