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

![Search with comment](../img/datasource_manager.png)

## Panel

The PgMetadata panel can be opened. If set, the layer metadata will be displayed according to the layer 
selected in the legend.

## Export

To export metadata as PDF, HTML or DCAT, you need to select a layer in your layer tree saved in the metadata 
table `dataset`. Then in the dock you have a button to open the `export menu` and choose the output format.

![Button Export](../img/dockpgmetadata_with_metadata.png)

If no layer with metadata are selected, you can't click on the button of the `export menu`.

![Button Export without metadata](../img/dockpgmetadatawithoutmetadata.png)

# For the administrator

## Installation

### Database

1. The plugin is using a schema in PostgreSQL.
    * If you just installed the plugin in a new organization, you must
use the [install database structure](../processing/index.html#installation-of-the-database-structure)
    * If the `pgmetadata` schema is already existing in your database, you may need to upgrade it after a 
    plugin upgrade using the 
    [upgrade database structure](../processing/index.html#upgrade-the-database-structure)

### Administration project

1. The GIS administrator can generate a QGIS project using 
[create metadata project](../processing/index.html#create-metadata-administration-project). You need to open
the generated project and use the normal QGIS editing tools.
1. In the group called `Information Warnings` :
    * `Orphan metadata` displays tables not existing in the database itself, but the metadata exists in the
    `dataset` table.
    * `Orphan tables` is the reverse. It displays tables existing in the database but in the `dataset` table.

### Editing metadata

Before creating metadata for your layer/table, you need to implement some table. To edit this table you need
to open the attribute table, switch on **Edition** mode and add a new row.

Switching to edit mode:

![Attribute table](../img/attribute_table_edit_mode.png)

Adding a new row:

![Attribute table](../img/attribute_table_new_row.png)

Switching to the form view: You can access the form view at the bottom right corner of the attribute table.

![Attribute table](../img/attribute_table_view_form.png)

1. On the `Theme` table you can add many theme corresponding to different theme of your layers.
    You need to enter a **code** e.g. "A01" and a **label** corresponding at the name e.g. "Naturals area".
    Example adding theme:

    ![Attribute table](../img/attribute_table_add_theme.png)

1. On the `Contact` table you can add contacts that can later be associated with your metadata layer.
    Example new contact:

    ![Attribute table](../img/attribute_table_add_contact.png)

1. The `Dataset` table is the metadata table. You can add many rows and one added line corresponds to a 
   metadata of a layer.
    You need to fill a row with these minimum information : 
    * Table name,
    * Schema name,
    * Title,
    * Abstract,
    * Etc

    Example to add a new metadata for a layer:
      On the second picture you can see the theme.

    ![Attribute table](../img/attribute_table_add_dataset.png)

1. Now you can add a contact to a dataset row with the `Dataset` table. You can click on a tab called `contact`.
    You need to allow **edit mode** in this tab because you implement an other table.
    Example:

    ![Attribute table](../img/attribute_table_add_contact.png)

1. And now you can add some`Link` to a dataset row with the `Dataset` table. It's same that to add a contact,
   you have a link tab.
    Don't forget to allow **edit mode**.
    Example:

    ![Attribute table](../img/attribute_table_add_link.png)


When you stop editing a table, don't forget to save your change with clicking on the save icon et leave the
edit mode.
To save:

![Attribute table](../img/attribute_table_save.png)

To leave the edit mode you need to click on the same button that to enter the edit mode.

## HTML Template

You can customize the HTML template.

* Use `[% "name_of_field" %]` to display a specific field, eg `abstract`.
* use `[% meta_contacts %]` to display all contacts related. It's using the template called `contact`.
* use `[% meta_links %]` to display all links related. It's using the template called `link`.

# Lizmap Web Client

The metadata can be displayed in the QGIS Lizmap Web Client using the
[module](https://github.com/3liz/lizmap-pgmetadata-module). The module is also providing a DCAT catalog.
