# PgMetadata

[![Tests 🎳](https://github.com/3liz/qgis-pgmetadata-plugin/workflows/Tests%20%F0%9F%8E%B3/badge.svg)](https://github.com/3liz/qgis-pgmetadata-plugin/actions?query=workflow%3A%22Tests+%F0%9F%8E%B3%22+branch%3Amaster)
[![Flake8 🎳](https://github.com/3liz/qgis-pgmetadata-plugin/workflows/Flake8%20%F0%9F%8E%B3/badge.svg)](https://github.com/3liz/qgis-pgmetadata-plugin/actions?query=workflow%3A%22Flake8+%F0%9F%8E%B3%22+branch%3Amaster)
[![Migration 🗂](https://github.com/3liz/qgis-pgmetadata-plugin/workflows/Migration%20%F0%9F%97%82/badge.svg)](https://github.com/3liz/qgis-pgmetadata-plugin/actions?query=workflow%3A%22Migration+%F0%9F%97%82%22+branch%3Amaster)
[![Transifex 🗺](https://github.com/3liz/qgis-pgmetadata-plugin/workflows/Transifex%20%F0%9F%97%BA/badge.svg)](https://github.com/3liz/qgis-pgmetadata-plugin/actions?query=workflow%3A%22Transifex+%F0%9F%97%BA%22+branch%3Amaster)
[![Release 🚀](https://github.com/3liz/qgis-pgmetadata-plugin/workflows/Release%20%F0%9F%9A%80/badge.svg)](https://github.com/3liz/qgis-pgmetadata-plugin/actions?query=workflow%3A%22Release+%F0%9F%9A%80%22)

![icon](pg_metadata/resources/icons/icon.png)

Store metadata in a PostgreSQL database and manage it from QGIS.

## Documentation

Presentation, user guide, installation, Lizmap Web Client, everything is there.

https://docs.3liz.org/qgis-pgmetadata-plugin/

## Running migrations

Environment variable

```python
import os
os.environ['TEST_DATABASE_INSTALL_PGMETADATA'] = '0.0.1'
```
