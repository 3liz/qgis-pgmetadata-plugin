# Contributing

This project is hosted on GitHub.

[Visit GitHub](https://github.com/3liz/qgis-pgmetadata-plugin/){: .md-button .md-button--primary }

## Translation

[![🗺 Transifex](https://github.com/3liz/qgis-pgmetadata-plugin/actions/workflows/transifex.yml/badge.svg)](https://github.com/3liz/qgis-pgmetadata-plugin/actions/workflows/transifex.yml)

The UI is available on [Transifex](https://www.transifex.com/3liz-1/pgmetadata/dashboard/), no development
knowledge is required. You need to create an account, request the language if your language is not available by default (we will happily accept) and start to translate strings.

To translate the metadata glossary, the
[SQL file](https://github.com/3liz/qgis-pgmetadata-plugin/blob/master/pg_metadata/install/sql/pgmetadata/90_GLOSSARY.sql)
needs to be edited.

If you change an SQL file, you need to add a migration file, located in `pg_metadata/install/sql/upgrade/`.
These files are run according to the current version of the database to be sure that an **existing** database
can also be upgraded to a newer version of the plugin.

SQL files located in `pg_metadata/install/sql/pgmetadata` are run **only** on a new database.

Example of a migration file to update the glossary with German language :

```sql
CREATE TABLE pgmetadata.t_glossary (field text, code text, label_de text, description_de text);

INSERT INTO pgmetadata.t_glossary (field, code, label_de, description_de)
VALUES
('dataset.publication_frequency', 'WEE', 'wöchentlich', 'Daten werden wöchentlich aktualisiert')
ON CONFLICT DO NOTHING;

UPDATE pgmetadata.glossary AS g
SET (label_de, description_de)
= (t.label_de, t.description_de)
FROM pgmetadata.t_glossary AS t
WHERE g.field = t.field AND g.code = t.code;

DROP TABLE pgmetadata.t_glossary;
```

You can submit a 
[PR](https://docs.github.com/en/github/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests)
on GitHub or feel free to contact us for any assistance. There are some languages available already.

## Code

[![🧪 Tests](https://github.com/3liz/qgis-pgmetadata-plugin/actions/workflows/ci.yml/badge.svg)](https://github.com/3liz/qgis-pgmetadata-plugin/actions/workflows/ci.yml)

SQL and Python are covered by unittests with Docker.

```bash
pip install -r requirements/dev.txt
flake8
make tests
make test_migration
```

On a new database, if you want to install the database by using migrations :

```python
import os
os.environ['TEST_DATABASE_INSTALL_PGMETADATA'] = '0.0.1'  # Enable
del os.environ['TEST_DATABASE_INSTALL_PGMETADATA']  # Disable
```

## Documentation

[![📖 Documentation](https://github.com/3liz/qgis-pgmetadata-plugin/actions/workflows/publish-doc.yml/badge.svg)](https://github.com/3liz/qgis-pgmetadata-plugin/actions/workflows/publish-doc.yml)

The documentation is using [MkDocs](https://www.mkdocs.org/) with [Material](https://squidfunk.github.io/mkdocs-material/).

```bash
pip install -r requirements/doc.txt
mkdocs serve
```
