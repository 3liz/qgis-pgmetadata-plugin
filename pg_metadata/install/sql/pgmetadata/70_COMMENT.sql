--
-- PostgreSQL database dump
--

-- Dumped from database version 10.14 (Debian 10.14-1.pgdg100+1)
-- Dumped by pg_dump version 10.14 (Debian 10.14-1.pgdg100+1)

SET statement_timeout = 0;
SET lock_timeout = 0;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

-- SCHEMA pgmetadata
COMMENT ON SCHEMA pgmetadata IS 'PgMetadata - contains tables for the QGIS plugin pg_metadata';


-- contact
COMMENT ON TABLE pgmetadata.contact IS 'List of contacts related to the published datasets.';


-- contact.id
COMMENT ON COLUMN pgmetadata.contact.id IS 'Internal automatic integer ID';


-- contact.name
COMMENT ON COLUMN pgmetadata.contact.name IS 'Full name of the contact';


-- contact.organisation_name
COMMENT ON COLUMN pgmetadata.contact.organisation_name IS 'Organisation name. Ex: ACME';


-- contact.organisation_unit
COMMENT ON COLUMN pgmetadata.contact.organisation_unit IS 'Organisation unit name. Ex: GIS unit';


-- contact.email
COMMENT ON COLUMN pgmetadata.contact.email IS 'Email address';


-- dataset
COMMENT ON TABLE pgmetadata.dataset IS 'Main table for storing dataset about PostgreSQL vector layers.';


-- dataset.id
COMMENT ON COLUMN pgmetadata.dataset.id IS 'Internal automatic integer ID';


-- dataset.uid
COMMENT ON COLUMN pgmetadata.dataset.uid IS 'Unique identifier of the data. Ex: 89e3dde9-3850-c211-5045-b5b09aa1da9a';


-- dataset.table_name
COMMENT ON COLUMN pgmetadata.dataset.table_name IS 'Name of the related table in the database';


-- dataset.schema_name
COMMENT ON COLUMN pgmetadata.dataset.schema_name IS 'Name of the related schema in the database';


-- dataset.title
COMMENT ON COLUMN pgmetadata.dataset.title IS 'Title of the data';


-- dataset.abstract
COMMENT ON COLUMN pgmetadata.dataset.abstract IS 'Full description of the data';


-- dataset.categories
COMMENT ON COLUMN pgmetadata.dataset.categories IS 'List of categories';


-- dataset.keywords
COMMENT ON COLUMN pgmetadata.dataset.keywords IS 'List of keywords';


-- dataset.spatial_level
COMMENT ON COLUMN pgmetadata.dataset.spatial_level IS 'Spatial Level of the data. Ex: city, country, street';


-- dataset.minimum_optimal_scale
COMMENT ON COLUMN pgmetadata.dataset.minimum_optimal_scale IS 'Minimum optimal scale denominator to view the data. Ex: 100000 for 1/100000. Most "zoomed out".';


-- dataset.maximum_optimal_scale
COMMENT ON COLUMN pgmetadata.dataset.maximum_optimal_scale IS 'Maximum optimal scale denominator to view the data. Ex: 2000 for 1/2000. Most "zoomed in".';


-- dataset.publication_date
COMMENT ON COLUMN pgmetadata.dataset.publication_date IS 'Date of publication of the data';


-- dataset.publication_frequency
COMMENT ON COLUMN pgmetadata.dataset.publication_frequency IS 'Frequency of publication: how often the data is published.';


-- dataset.license
COMMENT ON COLUMN pgmetadata.dataset.license IS 'License. Ex: Public domain';


-- dataset.confidentiality
COMMENT ON COLUMN pgmetadata.dataset.confidentiality IS 'Confidentiality of the data. ';


-- dataset.feature_count
COMMENT ON COLUMN pgmetadata.dataset.feature_count IS 'Number of features of the data';


-- dataset.geometry_type
COMMENT ON COLUMN pgmetadata.dataset.geometry_type IS 'Geometry type. Ex: Polygon';


-- dataset.projection_name
COMMENT ON COLUMN pgmetadata.dataset.projection_name IS 'Projection name of the dataset. Ex: WGS 84 - Geographic';


-- dataset.projection_authid
COMMENT ON COLUMN pgmetadata.dataset.projection_authid IS 'Projection auth id. Ex: EPSG:4326';


-- dataset.spatial_extent
COMMENT ON COLUMN pgmetadata.dataset.spatial_extent IS 'Spatial extent of the data. xmin,ymin,xmax,ymax.';


-- dataset.creation_date
COMMENT ON COLUMN pgmetadata.dataset.creation_date IS 'Date of creation of the dataset item';


-- dataset.update_date
COMMENT ON COLUMN pgmetadata.dataset.update_date IS 'Date of update of the dataset item';


-- dataset.geom
COMMENT ON COLUMN pgmetadata.dataset.geom IS 'Geometry defining the extent of the data. Can be any polygon.';


-- dataset_contact
COMMENT ON TABLE pgmetadata.dataset_contact IS 'Pivot table between dataset and contacts.';


-- dataset_contact.id
COMMENT ON COLUMN pgmetadata.dataset_contact.id IS 'Internal automatic integer ID';


-- dataset_contact.fk_id_contact
COMMENT ON COLUMN pgmetadata.dataset_contact.fk_id_contact IS 'Id of the contact item';


-- dataset_contact.fk_id_dataset
COMMENT ON COLUMN pgmetadata.dataset_contact.fk_id_dataset IS 'Id of the dataset item';


-- dataset_contact.contact_role
COMMENT ON COLUMN pgmetadata.dataset_contact.contact_role IS 'Role of the contact for the specified dataset item. Ex: owner, distributor';


-- glossary
COMMENT ON TABLE pgmetadata.glossary IS 'List of labels and words used as labels for stored data';


-- glossary.id
COMMENT ON COLUMN pgmetadata.glossary.id IS 'Internal automatic integer ID';


-- glossary.field
COMMENT ON COLUMN pgmetadata.glossary.field IS 'Field name';


-- glossary.code
COMMENT ON COLUMN pgmetadata.glossary.code IS 'Item code';


-- glossary.label
COMMENT ON COLUMN pgmetadata.glossary.label IS 'Item label';


-- glossary.description
COMMENT ON COLUMN pgmetadata.glossary.description IS 'Description';


-- glossary.item_order
COMMENT ON COLUMN pgmetadata.glossary.item_order IS 'Display order';


-- link
COMMENT ON TABLE pgmetadata.link IS 'List of links related to the published datasets.';


-- link.id
COMMENT ON COLUMN pgmetadata.link.id IS 'Internal automatic integer ID';


-- link.name
COMMENT ON COLUMN pgmetadata.link.name IS 'Name of the link';


-- link.type
COMMENT ON COLUMN pgmetadata.link.type IS 'Type of the link. Ex: https, git, OGC:WFS';


-- link.url
COMMENT ON COLUMN pgmetadata.link.url IS 'Full URL';


-- link.description
COMMENT ON COLUMN pgmetadata.link.description IS 'Description';


-- link.format
COMMENT ON COLUMN pgmetadata.link.format IS 'Format.';


-- link.mime
COMMENT ON COLUMN pgmetadata.link.mime IS 'Mime type';


-- link.size
COMMENT ON COLUMN pgmetadata.link.size IS 'Size of the target';


-- link.fk_id_dataset
COMMENT ON COLUMN pgmetadata.link.fk_id_dataset IS 'Id of the dataset item';


-- qgis_plugin
COMMENT ON TABLE pgmetadata.qgis_plugin IS 'Version and date of the database structure. Usefull for database structure and glossary data migrations between the plugin versions by the QGIS plugin pg_metadata';


--
-- PostgreSQL database dump complete
--

