# PgMetadata

![icon](pg_metadata/resources/icons/icon.png)

Store metadata in a PostgreSQL database and manage it from QGIS.

## Documentation

https://docs.3liz.org/qgis-pgmetadata-plugin/

## Installation

The plugin is not yet available in the official QGIS repository, you must install it manually.

### Custom repository

We recommend adding the QGIS [custom repository](https://docs.qgis.org/testing/en/docs/user_manual/plugins/plugins.html#the-settings-tab),
using this URL `https://github.com/3liz/qgis-pgmetadata-plugin/releases/latest/download/plugins.xml`.
There isn't any authentification and you will have automatic updates later.

### Manual ZIP

If you don't want to setup a custom repository, you can download the ZIP file from the
[release page](https://github.com/3liz/qgis-pgmetadata-plugin/releases)

## Running migrations

Environment variable `TEST_DATABASE_INSTALL_PGMETADATA = 0.0.1`
