---
Title: PgMetadata
Favicon: ../icon.png
Up: True
...

[TOC]

# For the normal user

## Hide Processing algorithms

The system administrator can hide PgMetadata Processing algorithms from normal users by adding a environment 
variable `PGMETADATA_USER`. If this variable exists, Processing algorithms won't be displayed.

## Locator

Type `ctrl+k` in QGIS to open the locator widget. You can start type `meta` then you should see layers in the
list.

## Datasource manager

This works without the plugin installed on the computer. It's native in QGIS.

![Search with comment](../datasource_manager.png)

## Panel

The PgMetadata panel can be opened. If set, the layer metadata will be displayed according to the layer 
selected in the legend.

# For the administrator

## Installation

1. The plugin is using a schema in PostgreSQL.
    * If you just installed the plugin in a new organization, you must
use the [install database structure](../processing/index.html#installation-of-the-database-structure)
    * If the `pgmetadata` schema is already existing in your database, you may need to upgrade it after a 
    plugin upgrade using the 
    [upgrade database structure](../processing/index.html#upgrade-the-database-structure)

1. The GIS administrator can generate a QGIS project using 
[create metadata project](../processing/index.html#create-metadata-administration-project). You need to open
the generated project and use the normal QGIS editing tools.
1. On the `dataset` table, open the attribute table, switch on **Edition** mode and add a new row.
    You need to fill a row with these minimum information : 
    * Table name,
    * Schema name,
    * Title,
    * Abstract

![Attribute table](../attribute_table_new_row.png)

You need to save your `dataset` layer by switching off editable mode.

## HTML Template

You can customize the HTML template.

* Use `[% "name_of_field" %]` to display a specific field, eg `abstract`.
* use `[% meta_contacts %]` to display all contacts related. It's using the template called `contact`.
* use `[% meta_links %]` to display all links related. It's using the template called `link`.

