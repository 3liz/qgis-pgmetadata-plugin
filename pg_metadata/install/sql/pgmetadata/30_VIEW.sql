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

-- v_contact
CREATE VIEW pgmetadata.v_contact AS
 SELECT d.table_name,
    d.schema_name,
    c.name,
    c.organisation_name,
    c.organisation_unit,
    g.label AS contact_role,
    c.email
   FROM (((pgmetadata.dataset_contact dc
     JOIN pgmetadata.dataset d ON ((d.id = dc.fk_id_dataset)))
     JOIN pgmetadata.contact c ON ((dc.fk_id_contact = c.id)))
     JOIN pgmetadata.glossary g ON (((g.field = 'contact.contact_role'::text) AND (g.code = dc.contact_role))))
  WHERE true
  ORDER BY dc.id;


-- VIEW v_contact
COMMENT ON VIEW pgmetadata.v_contact IS 'Formatted version of contact data, with all the codes replaced by corresponding labels taken from pgmetadata.glossary. Used in the function in charge of building the HTML metadata content.';


-- v_dataset
CREATE VIEW pgmetadata.v_dataset AS
 WITH s AS (
         SELECT d.id,
            d.uid,
            d.table_name,
            d.schema_name,
            d.title,
            d.abstract,
            d.categories,
            d.keywords,
            d.spatial_level,
            d.minimum_optimal_scale,
            d.maximum_optimal_scale,
            d.publication_date,
            d.publication_frequency,
            d.license,
            d.confidentiality,
            d.feature_count,
            d.geometry_type,
            d.projection_name,
            d.projection_authid,
            d.spatial_extent,
            d.creation_date,
            d.update_date,
            d.geom,
            cat.cat
           FROM (pgmetadata.dataset d
             LEFT JOIN LATERAL unnest(d.categories) cat(cat) ON (true))
          WHERE true
          ORDER BY d.id
        ), ss AS (
         SELECT s.id,
            s.uid,
            s.table_name,
            s.schema_name,
            s.title,
            s.abstract,
            gcat.label AS cat,
            s.keywords,
            s.spatial_level,
            ('1/'::text || s.minimum_optimal_scale) AS minimum_optimal_scale,
            ('1/'::text || s.maximum_optimal_scale) AS maximum_optimal_scale,
            s.publication_date,
            gfre.label AS publication_frequency,
            concat(glic.label, ' (', s.license, ')') AS license,
            gcon.label AS confidentiality,
            s.feature_count,
            s.geometry_type,
            (regexp_split_to_array((rs.srtext)::text, '"'::text))[2] AS projection_name,
            s.projection_authid,
            s.spatial_extent,
            s.creation_date,
            s.update_date
           FROM (((((s
             LEFT JOIN pgmetadata.glossary gcat ON (((gcat.field = 'dataset.categories'::text) AND (gcat.code = s.cat))))
             LEFT JOIN pgmetadata.glossary gfre ON (((gfre.field = 'dataset.publication_frequency'::text) AND (gfre.code = s.publication_frequency))))
             LEFT JOIN pgmetadata.glossary glic ON (((glic.field = 'dataset.license'::text) AND (glic.code = s.license))))
             LEFT JOIN pgmetadata.glossary gcon ON (((gcon.field = 'dataset.confidentiality'::text) AND (gcon.code = s.confidentiality))))
             LEFT JOIN public.spatial_ref_sys rs ON ((concat(rs.auth_name, ':', rs.auth_srid) = s.projection_authid)))
        )
 SELECT ss.id,
    ss.uid,
    ss.table_name,
    ss.schema_name,
    ss.title,
    ss.abstract,
    string_agg(DISTINCT ss.cat, ', '::text ORDER BY ss.cat) AS categories,
    ss.keywords,
    ss.spatial_level,
    ss.minimum_optimal_scale,
    ss.maximum_optimal_scale,
    ss.publication_date,
    ss.publication_frequency,
    ss.license,
    ss.confidentiality,
    ss.feature_count,
    ss.geometry_type,
    ss.projection_name,
    ss.projection_authid,
    ss.spatial_extent,
    ss.creation_date,
    ss.update_date
   FROM ss
  GROUP BY ss.id, ss.uid, ss.table_name, ss.schema_name, ss.title, ss.abstract, ss.keywords, ss.spatial_level, ss.minimum_optimal_scale, ss.maximum_optimal_scale, ss.publication_date, ss.publication_frequency, ss.license, ss.confidentiality, ss.feature_count, ss.geometry_type, ss.projection_name, ss.projection_authid, ss.spatial_extent, ss.creation_date, ss.update_date;


-- VIEW v_dataset
COMMENT ON VIEW pgmetadata.v_dataset IS 'Formatted version of dataset data, with all the codes replaced by corresponding labels taken from pgmetadata.glossary. Used in the function in charge of building the HTML metadata content.';


-- v_link
CREATE VIEW pgmetadata.v_link AS
 SELECT l.id,
    d.table_name,
    d.schema_name,
    l.name,
    l.type,
    g1.label AS type_label,
    l.url,
    l.description,
    l.format,
    l.mime,
    g2.label AS mime_label,
    l.size
   FROM (((pgmetadata.link l
     JOIN pgmetadata.dataset d ON ((d.id = l.fk_id_dataset)))
     JOIN pgmetadata.glossary g1 ON (((g1.field = 'link.type'::text) AND (g1.code = l.type))))
     JOIN pgmetadata.glossary g2 ON (((g2.field = 'link.mime'::text) AND (g2.code = l.mime))))
  WHERE true
  ORDER BY l.id;


-- VIEW v_link
COMMENT ON VIEW pgmetadata.v_link IS 'Formatted version of link data, with all the codes replaced by corresponding labels taken from pgmetadata.glossary. Used in the function in charge of building the HTML metadata content.';


-- v_orphan_dataset_items
CREATE VIEW pgmetadata.v_orphan_dataset_items AS
 SELECT row_number() OVER () AS id,
    dataset.schema_name,
    dataset.table_name
   FROM pgmetadata.dataset
  WHERE (NOT (concat(dataset.schema_name, '.', dataset.table_name) IN ( SELECT concat(pg_tables.schemaname, '.', pg_tables.tablename) AS concat
           FROM pg_tables)))
  ORDER BY dataset.schema_name, dataset.table_name;


-- VIEW v_orphan_dataset_items
COMMENT ON VIEW pgmetadata.v_orphan_dataset_items IS 'View containing the tables referenced in dataset but not existing in the database itself.';


-- v_orphan_tables
CREATE VIEW pgmetadata.v_orphan_tables AS
 SELECT row_number() OVER () AS id,
    (pg_tables.schemaname)::text AS schemaname,
    (pg_tables.tablename)::text AS tablename
   FROM pg_tables
  WHERE ((NOT (concat(pg_tables.schemaname, '.', pg_tables.tablename) IN ( SELECT concat(dataset.schema_name, '.', dataset.table_name) AS concat
           FROM pgmetadata.dataset))) AND (pg_tables.schemaname <> ALL (ARRAY['pg_catalog'::name, 'information_schema'::name])))
  ORDER BY ((pg_tables.schemaname)::text), ((pg_tables.tablename)::text);


-- VIEW v_orphan_tables
COMMENT ON VIEW pgmetadata.v_orphan_tables IS 'View containing the existing tables but not referenced in dataset';


-- v_schema_list
CREATE VIEW pgmetadata.v_schema_list AS
 SELECT row_number() OVER () AS id,
    (schemata.schema_name)::text AS schema_name
   FROM information_schema.schemata
  WHERE ((schemata.schema_name)::text <> ALL ((ARRAY['pg_toast'::character varying, 'pg_temp_1'::character varying, 'pg_toast_temp_1'::character varying, 'pg_catalog'::character varying, 'information_schema'::character varying])::text[]))
  ORDER BY (schemata.schema_name)::text;


-- VIEW v_schema_list
COMMENT ON VIEW pgmetadata.v_schema_list IS 'View containing list of all schema in this database';


-- v_table_comment_from_metadata
CREATE VIEW pgmetadata.v_table_comment_from_metadata AS
 SELECT d.schema_name AS table_schema,
    d.table_name,
    concat(d.title, ' - ', d.abstract, ' (', array_to_string(d.categories, ', '::text), ')') AS table_comment
   FROM pgmetadata.dataset d;


-- VIEW v_table_comment_from_metadata
COMMENT ON VIEW pgmetadata.v_table_comment_from_metadata IS 'View containing the desired formatted comment for the tables listed in the pgmetadata.dataset table. This view is used by the trigger to update the table comment when the dataset item is added or modified';


-- v_table_list
CREATE VIEW pgmetadata.v_table_list AS
 SELECT row_number() OVER () AS id,
    (tables.table_schema)::text AS schema_name,
    (tables.table_name)::text AS table_name
   FROM information_schema.tables
  WHERE ((tables.table_schema)::text <> ALL ((ARRAY['pg_toast'::character varying, 'pg_temp_1'::character varying, 'pg_toast_temp_1'::character varying, 'pg_catalog'::character varying, 'information_schema'::character varying])::text[]))
  ORDER BY tables.table_schema, (tables.table_name)::text;


-- VIEW v_table_list
COMMENT ON VIEW pgmetadata.v_table_list IS 'View containing list of all tables in this database with schema name';


--
-- PostgreSQL database dump complete
--

