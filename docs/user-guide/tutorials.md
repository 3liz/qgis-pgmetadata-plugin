# Tutorials

## Introduction

In these videos, we will cover how to set up and use PgMetadata, for both the 
GIS Administrator (installation of the database schema, create metadata…) and the final 
user GIS technician (searching for a specific layer, exporting as HTML…).

We will use the [geopackage file provided](./../media/example.gpkg). In QGIS, 
`Project` ➡ `Open From…` ➡ `Geopackage`, there is a single project called `project`.
This dataset is a subset of the Corsica island in France from [OpenStreetMap](https://www.openstreetmap.org).

???+ info
    OpenStreetMap® is open data, licensed under the Open Data Commons Open Database License (ODbL)
    by the OpenStreetMap Foundation (OSMF). We must use the credit "© OpenStreetMap contributors".
    https://www.openstreetmap.org/copyright/en

## Installation

In this video, we are explaining :

* the online documentation
* the database schema
* how to install and or upgrade the schema
* how to generate the QGIS project for metadata editing

<iframe width="800" height="450" src="https://www.youtube.com/embed/IaIIGHuogwM" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

## Edition

In this video, we are explaining how to edit metadata with the administration project :

* Contacts
* Links
* Metadata
* HTML templates
* Themes
* PostgreSQL views for orphan tables or orphan metadata sheets

<iframe width="800" height="450" src="https://www.youtube.com/embed/IvoSMAlfCWA" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

## Search in the catalog from QGIS

In this video, we are explaining how to re-use the metadata in QGIS Desktop :

* Without the PgMetadata plugin with the QGIS data source manager
* With the plugin using the locator bar
* Exporting a single layer metadata as PDF, HTML or PDF
* Exporting the whole catalog

<iframe width="800" height="450" src="https://www.youtube.com/embed/pXzFt--L2hc" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

## Publish metadata on the web

In this video, we are explaining how to re-use the metadata outside of QGIS Desktop :

* With [PgMetadata module](https://github.com/3liz/lizmap-pgmetadata-module) for [Lizmap](https://github.com/3liz/lizmap-web-client/)
* Write your [own wrapper](./advanced.md) to extract DCAT information

<iframe width="800" height="450" src="https://www.youtube.com/embed/hVVU9xNqjaU" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
