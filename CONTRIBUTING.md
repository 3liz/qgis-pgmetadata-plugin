# Contributing

This project is hosted on GitHub.

[Visit GitHub](https://github.com/3liz/qgis-pgmetadata-plugin/){: .md-button .md-button--primary }

## Translation

The UI is available on [Transifex](https://www.transifex.com/3liz-1/pgmetadata/dashboard/), no development
knowledge is required. [![Transifex 🗺](https://github.com/3liz/qgis-pgmetadata-plugin/workflows/Transifex%20%F0%9F%97%BA/badge.svg)](https://github.com/3liz/qgis-pgmetadata-plugin/actions?query=workflow%3A%22Transifex+%F0%9F%97%BA%22+branch%3Amaster)


To translate the metadata glossary, the
[SQL file](https://github.com/3liz/qgis-pgmetadata-plugin/blob/master/pg_metadata/install/sql/pgmetadata/90_GLOSSARY.sql)
needs to be edited.

## Code

SQL and Python are covered by unittests with Docker.

[![Tests 🎳](https://github.com/3liz/qgis-pgmetadata-plugin/workflows/Tests%20%F0%9F%8E%B3/badge.svg)](https://github.com/3liz/qgis-pgmetadata-plugin/actions?query=workflow%3A%22Tests+%F0%9F%8E%B3%22+branch%3Amaster)
[![Flake8 🎳](https://github.com/3liz/qgis-pgmetadata-plugin/workflows/Flake8%20%F0%9F%8E%B3/badge.svg)](https://github.com/3liz/qgis-pgmetadata-plugin/actions?query=workflow%3A%22Flake8+%F0%9F%8E%B3%22+branch%3Amaster)
[![Migration 🗂](https://github.com/3liz/qgis-pgmetadata-plugin/workflows/Migration%20%F0%9F%97%82/badge.svg)](https://github.com/3liz/qgis-pgmetadata-plugin/actions?query=workflow%3A%22Migration+%F0%9F%97%82%22+branch%3Amaster)

```bash
pip install -r requirements-dev.txt
flake8
make tests
make test_migration
```

## Documentation

The documentation is using [MkDocs](https://www.mkdocs.org/) with [Material](https://squidfunk.github.io/mkdocs-material/) :

```bash
pip install -r requirements-doc.txt
mkdocs serve
```
