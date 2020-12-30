--
-- PostgreSQL database dump
--

-- Dumped from database version 10.14 (Debian 10.14-1.pgdg100+1)
-- Dumped by pg_dump version 10.14 (Debian 10.14-1.pgdg100+1)

SET statement_timeout = 0;
SET lock_timeout = 0;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

-- SCHEMA pgmetadata
COMMENT ON SCHEMA pgmetadata IS 'PgMetadata - contains tables for the QGIS plugin pg_metadata';


-- FUNCTION calculate_fields_from_data()
COMMENT ON FUNCTION pgmetadata.calculate_fields_from_data() IS 'Update some fields content when updating or inserting a line in pgmetadata.dataset table.';


-- FUNCTION generate_html_from_json(_json_data json, _template_section text)
COMMENT ON FUNCTION pgmetadata.generate_html_from_json(_json_data json, _template_section text) IS 'Generate HTML content for the given JSON representation of a record and a given section, based on the template stored in the pgmetadata.html_template table. Template section controlled values are "main", "contact" and "link". If the corresponding line is not found in the pgmetadata.html_template table, NULL is returned.';


-- FUNCTION get_dataset_item_html_content(_table_schema text, _table_name text)
COMMENT ON FUNCTION pgmetadata.get_dataset_item_html_content(_table_schema text, _table_name text) IS 'Generate the metadata HTML content for the given table and locale, or NULL if no templates are stored in the pgmetadata.html_template table.';


-- FUNCTION refresh_dataset_calculated_fields()
COMMENT ON FUNCTION pgmetadata.refresh_dataset_calculated_fields() IS 'Force the calculation of spatial related fields in dataset table by updating all lines, which will trigger the function calculate_fields_from_data';


-- FUNCTION update_postgresql_table_comment(table_schema text, table_name text, table_comment text)
COMMENT ON FUNCTION pgmetadata.update_postgresql_table_comment(table_schema text, table_name text, table_comment text) IS 'Update the PostgreSQL comment of a table by giving table schema, name and comment
Example: if you need to update the comments for all the items listed by pgmetadata.v_table_comment_from_metadata:

    SELECT
    v.table_schema,
    v.table_name,
    pgmetadata.update_postgresql_table_comment(
        v.table_schema,
        v.table_name,
        v.table_comment
    ) AS comment_updated
    FROM pgmetadata.v_table_comment_from_metadata AS v

    ';


-- FUNCTION update_table_comment_from_dataset()
COMMENT ON FUNCTION pgmetadata.update_table_comment_from_dataset() IS 'Update the PostgreSQL table comment when updating or inserting a line in pgmetadata.dataset table. Comment is taken from the view pgmetadata.v_table_comment_from_metadata.';


-- contact
COMMENT ON TABLE pgmetadata.contact IS 'List of contacts related to the published datasets.';


-- contact.id
COMMENT ON COLUMN pgmetadata.contact.id IS 'Internal automatic integer ID';


-- contact.name
COMMENT ON COLUMN pgmetadata.contact.name IS 'Full name of the contact';


-- contact.organisation_name
COMMENT ON COLUMN pgmetadata.contact.organisation_name IS 'Organisation name. E.g. ACME';


-- contact.organisation_unit
COMMENT ON COLUMN pgmetadata.contact.organisation_unit IS 'Organisation unit name. E.g. GIS unit';


-- contact.email
COMMENT ON COLUMN pgmetadata.contact.email IS 'Email address';


-- dataset
COMMENT ON TABLE pgmetadata.dataset IS 'Main table for storing dataset about PostgreSQL vector layers.';


-- dataset.id
COMMENT ON COLUMN pgmetadata.dataset.id IS 'Internal automatic integer ID';


-- dataset.uid
COMMENT ON COLUMN pgmetadata.dataset.uid IS 'Unique identifier of the data. E.g. 89e3dde9-3850-c211-5045-b5b09aa1da9a';


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
COMMENT ON COLUMN pgmetadata.dataset.keywords IS 'List of keywords separated by comma. Ex: environment, paris, trees';


-- dataset.spatial_level
COMMENT ON COLUMN pgmetadata.dataset.spatial_level IS 'Spatial level of the data. E.g. city, country, street';


-- dataset.minimum_optimal_scale
COMMENT ON COLUMN pgmetadata.dataset.minimum_optimal_scale IS 'Minimum optimal scale denominator to view the data. E.g. 100000 for 1/100000. Most "zoomed out".';


-- dataset.maximum_optimal_scale
COMMENT ON COLUMN pgmetadata.dataset.maximum_optimal_scale IS 'Maximum optimal scale denominator to view the data. E.g. 2000 for 1/2000. Most "zoomed in".';


-- dataset.publication_date
COMMENT ON COLUMN pgmetadata.dataset.publication_date IS 'Date of publication of the data';


-- dataset.publication_frequency
COMMENT ON COLUMN pgmetadata.dataset.publication_frequency IS 'Frequency of publication: how often the data is published.';


-- dataset.license
COMMENT ON COLUMN pgmetadata.dataset.license IS 'License. E.g. Public domain';


-- dataset.confidentiality
COMMENT ON COLUMN pgmetadata.dataset.confidentiality IS 'Confidentiality of the data.';


-- dataset.feature_count
COMMENT ON COLUMN pgmetadata.dataset.feature_count IS 'Number of features of the data';


-- dataset.geometry_type
COMMENT ON COLUMN pgmetadata.dataset.geometry_type IS 'Geometry type. E.g. Polygon';


-- dataset.projection_name
COMMENT ON COLUMN pgmetadata.dataset.projection_name IS 'Projection name of the dataset. E.g. WGS 84 - Geographic';


-- dataset.projection_authid
COMMENT ON COLUMN pgmetadata.dataset.projection_authid IS 'Projection auth id. E.g. EPSG:4326';


-- dataset.spatial_extent
COMMENT ON COLUMN pgmetadata.dataset.spatial_extent IS 'Spatial extent of the data. xmin,ymin,xmax,ymax.';


-- dataset.creation_date
COMMENT ON COLUMN pgmetadata.dataset.creation_date IS 'Date of creation of the dataset item';


-- dataset.update_date
COMMENT ON COLUMN pgmetadata.dataset.update_date IS 'Date of update of the dataset item';


-- dataset.geom
COMMENT ON COLUMN pgmetadata.dataset.geom IS 'Geometry defining the extent of the data. Can be any polygon.';


-- dataset.data_last_update
COMMENT ON COLUMN pgmetadata.dataset.data_last_update IS 'Date of the last modification of the target data (not on the dataset item line)';


-- dataset.themes
COMMENT ON COLUMN pgmetadata.dataset.themes IS 'List of themes';


-- dataset_contact
COMMENT ON TABLE pgmetadata.dataset_contact IS 'Pivot table between dataset and contacts.';


-- dataset_contact.id
COMMENT ON COLUMN pgmetadata.dataset_contact.id IS 'Internal automatic integer ID';


-- dataset_contact.fk_id_contact
COMMENT ON COLUMN pgmetadata.dataset_contact.fk_id_contact IS 'Id of the contact item';


-- dataset_contact.fk_id_dataset
COMMENT ON COLUMN pgmetadata.dataset_contact.fk_id_dataset IS 'Id of the dataset item';


-- dataset_contact.contact_role
COMMENT ON COLUMN pgmetadata.dataset_contact.contact_role IS 'Role of the contact for the specified dataset item. E.g. owner, distributor';


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


-- html_template
COMMENT ON TABLE pgmetadata.html_template IS 'This table contains the HTML templates for the main metadata sheet, and one for the contacts and links. Contacts and links templates are used to compute a unique contact or link HTML representation.';


-- link
COMMENT ON TABLE pgmetadata.link IS 'List of links related to the published datasets.';


-- link.id
COMMENT ON COLUMN pgmetadata.link.id IS 'Internal automatic integer ID';


-- link.name
COMMENT ON COLUMN pgmetadata.link.name IS 'Name of the link';


-- link.type
COMMENT ON COLUMN pgmetadata.link.type IS 'Type of the link. E.g. https, git, OGC:WFS';


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
COMMENT ON TABLE pgmetadata.qgis_plugin IS 'Version and date of the database structure. Useful for database structure and glossary data migrations between the plugin versions by the QGIS plugin pg_metadata';


-- theme
COMMENT ON TABLE pgmetadata.theme IS 'List of themes related to the published datasets.';


-- theme.id
COMMENT ON COLUMN pgmetadata.theme.id IS 'Internal automatic integer ID';


-- theme.code
COMMENT ON COLUMN pgmetadata.theme.code IS 'Code Of the theme';


-- theme.label
COMMENT ON COLUMN pgmetadata.theme.label IS 'Label of the theme';


-- theme.description
COMMENT ON COLUMN pgmetadata.theme.description IS 'Description of the theme';


-- VIEW v_glossary
COMMENT ON VIEW pgmetadata.v_glossary IS 'View transforming the glossary content into a JSON helping to localize a label or description by fetching directly the corresponding item. Ex: SET SESSION "pgmetadata.locale" = ''fr''; WITH glossary AS (SELECT dict FROM pgmetadata.v_glossary) SELECT (dict->''contact.contact_role''->''OW''->''label''->''fr'')::text AS label FROM glossary;';


-- VIEW v_contact
COMMENT ON VIEW pgmetadata.v_contact IS 'Formatted version of contact data, with all the codes replaced by corresponding labels taken from pgmetadata.glossary. Used in the function in charge of building the HTML metadata content. The localized version of labels and descriptions are taken considering the session setting ''pgmetadata.locale''. For example with: SET SESSION "pgmetadata.locale" = ''fr''; ';


-- VIEW v_dataset
COMMENT ON VIEW pgmetadata.v_dataset IS 'Formatted version of dataset data, with all the codes replaced by corresponding labels taken from pgmetadata.glossary. Used in the function in charge of building the HTML metadata content.';


-- VIEW v_link
COMMENT ON VIEW pgmetadata.v_link IS 'Formatted version of link data, with all the codes replaced by corresponding labels taken from pgmetadata.glossary. Used in the function in charge of building the HTML metadata content.';


-- VIEW v_orphan_dataset_items
COMMENT ON VIEW pgmetadata.v_orphan_dataset_items IS 'View containing the tables referenced in dataset but not existing in the database itself.';


-- VIEW v_orphan_tables
COMMENT ON VIEW pgmetadata.v_orphan_tables IS 'View containing the existing tables but not referenced in dataset';


-- VIEW v_schema_list
COMMENT ON VIEW pgmetadata.v_schema_list IS 'View containing list of all schema in this database';


-- VIEW v_table_comment_from_metadata
COMMENT ON VIEW pgmetadata.v_table_comment_from_metadata IS 'View containing the desired formatted comment for the tables listed in the pgmetadata.dataset table. This view is used by the trigger to update the table comment when the dataset item is added or modified';


-- VIEW v_table_list
COMMENT ON VIEW pgmetadata.v_table_list IS 'View containing list of all tables in this database with schema name';


-- VIEW v_valid_dataset
COMMENT ON VIEW pgmetadata.v_valid_dataset IS 'Gives a list of lines from pgmetadata.dataset with corresponding (existing) tables.';


--
-- PostgreSQL database dump complete
--

