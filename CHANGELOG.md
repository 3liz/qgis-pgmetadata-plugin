## CHANGELOG

### 0.2.2 - 17/11/2020

* Fix locator SQL query
* Add themes
* Update of the QGIS project

### 0.2.1 - 16/11/2020

* Improve HTML templates for making them compatible with Lizmap
* SQL - Fix calculate spatial field with Z or M geometries
* SQL - Fix HTML generation for fields email and size
* Processing - Fix upgrade algorithm and add tests
* Fix bug with empty links when link has no mime or type - fixes #34
* SQL - Fix if the envelop is a point or a line
* SQL - Add a view to query only valid dataset with the locator
* Fix running migrations in the Processing algorithm

### 0.2.0 - 12/11/2020

* Auto vacuum tables after install/upgrade of the database
* Add an option to auto open the dock from the locator
* Add a new field data_last_update
* Add an algorithm to set database connections for normal users
* Review default HTML templates
* Fix filter for QGS files in Processing

### 0.1.0 - 03/11/2020

* Automatically compute values from the table itself : feature count, CRS etc
* Improve QGIS form
* Improve the dock to display HTML metadata
* Use HTML templates stored in the database
* Display the layer geometry in the locator
* Add flag to disable Processing algorithm if needed for non admin user

### 0.0.3 - 20/10/2020

* Add a dock displaying basic metadata information
* Fix file filter about QGS file selector
* Improve error reporting from the locator

### 0.0.2 - 15/10/2020

* Add French language

### 0.0.1 - 14/10/2020

* Provide a basic locator for adding layers
* Install the database schema
* Provide a QGIS project to edit the metadata

###
