# PgMetadata

[![Tests 🎳](https://github.com/3liz/qgis-pgmetadata-plugin/workflows/Tests%20%F0%9F%8E%B3/badge.svg)](https://github.com/3liz/qgis-pgmetadata-plugin/actions?query=workflow%3A%22Tests+%F0%9F%8E%B3%22+branch%3Amaster)
[![Flake8 🎳](https://github.com/3liz/qgis-pgmetadata-plugin/workflows/Flake8%20%F0%9F%8E%B3/badge.svg)](https://github.com/3liz/qgis-pgmetadata-plugin/actions?query=workflow%3A%22Flake8+%F0%9F%8E%B3%22+branch%3Amaster)
[![Migration 🗂](https://github.com/3liz/qgis-pgmetadata-plugin/workflows/Migration%20%F0%9F%97%82/badge.svg)](https://github.com/3liz/qgis-pgmetadata-plugin/actions?query=workflow%3A%22Migration+%F0%9F%97%82%22+branch%3Amaster)
[![Transifex 🗺](https://github.com/3liz/qgis-pgmetadata-plugin/workflows/Transifex%20%F0%9F%97%BA/badge.svg)](https://github.com/3liz/qgis-pgmetadata-plugin/actions?query=workflow%3A%22Transifex+%F0%9F%97%BA%22+branch%3Amaster)
[![Release 🚀](https://github.com/3liz/qgis-pgmetadata-plugin/workflows/Release%20%F0%9F%9A%80/badge.svg)](https://github.com/3liz/qgis-pgmetadata-plugin/actions?query=workflow%3A%22Release+%F0%9F%9A%80%22)

![icon](pg_metadata/resources/icons/icon.png)

Store metadata in a PostgreSQL database and manage it from QGIS.

## Documentation

https://docs.3liz.org/qgis-pgmetadata-plugin/

## Installation

The plugin is not yet available in the official QGIS repository, you must install it manually.

### Custom repository

We recommend adding the QGIS 
[custom repository](https://docs.qgis.org/testing/en/docs/user_manual/plugins/plugins.html#the-settings-tab),
using this URL `https://github.com/3liz/qgis-pgmetadata-plugin/releases/latest/download/plugins.xml`.
There isn't any authentication, and you will have automatic updates later.

### Manual ZIP

If you don't want to setup a custom repository, you can download the ZIP file from the
[release page](https://github.com/3liz/qgis-pgmetadata-plugin/releases)

## Running migrations

Environment variable `TEST_DATABASE_INSTALL_PGMETADATA = 0.0.1`
