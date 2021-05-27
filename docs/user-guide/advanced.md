# Advanced

As described in [the end user guide](./end-user.md), it's possible to export a single dataset
or the full catalog as XML DCAT or as HTML. All this logic is generated in the database itself.

The QGIS PgMetadata dock or [Lizmap Web Client](../lizmap.md) are taking advantage of this to publish the DCAT
catalog on the web, by calling the SQL query to generate the XML DCAT catalog on the database.

If you are not using Lizmap to publish your QGIS projects on the web, you can easily write your own wrapper
(using [Flask](https://flask.palletsprojects.com) or any other WEB framework) to call these SQL queries.

To generate the HTML for a given dataset :

```sql
SELECT pgmetadata.get_dataset_item_html_content('{schema}', '{table}', '{locale}');
```

To generate the DCAT XML for a one or many datasets :

```sql
SELECT
    dataset
FROM
    pgmetadata.get_datasets_as_dcat_xml('{locale}','[{uuid}]');
```

If you are building your own wrapper around PgMetadata to reuse DCAT catalog, feel free to contact us or to
submit a PR with a reference to your source code ♥
