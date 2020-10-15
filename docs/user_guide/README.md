---
Title: PgMetadata
Favicon: ../icon.png
Up: True
...

[TOC]


# Installation

1. The plugin is using a schema in PostgreSQL.
    * If you just installed the plugin in a new organization, you must
use the [install database structure](../processing/index.html#installation-of-the-database-structure)
    * If the `pgmetadata` schema is already existing in your database, you may need to upgrade it after a 
    plugin upgrade using the 
    [upgrade database structure](../processing/index.html#upgrade-the-database-structure)

1. The GIS administrator can generate a QGIS project using 
[create metadata project](../processing/index.html#create-metadata-administration-project). You need to open
the generated project and use the normal QGIS editing tools.
On the `dataset` table, you need to fill a row with these minimum information : 
    * Table name,
    * Schema name,
    * Title,
    * Abstract

You need to save your `dataset` layer.

# Usage

Type `ctrl+k` in QGIS to open the locator widget. You can start type `meta` then you should see layers in the
list.
