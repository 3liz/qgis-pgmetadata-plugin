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

-- v_orphan_dataset_items
CREATE VIEW pgmetadata.v_orphan_dataset_items AS
 SELECT row_number() OVER () AS id,
    dataset.schema_name,
    dataset.table_name
   FROM pgmetadata.dataset
  WHERE (NOT (concat(dataset.schema_name, '.', dataset.table_name) IN ( SELECT concat(pg_tables.schemaname, '.', pg_tables.tablename) AS concat
           FROM pg_tables)));


-- VIEW v_orphan_dataset_items
COMMENT ON VIEW pgmetadata.v_orphan_dataset_items IS 'View containing the tables referenced in dataset but inexisting';


-- v_orphan_tables
CREATE VIEW pgmetadata.v_orphan_tables AS
 SELECT row_number() OVER () AS id,
    (pg_tables.schemaname)::text AS schemaname,
    (pg_tables.tablename)::text AS tablename
   FROM pg_tables
  WHERE ((NOT (concat(pg_tables.schemaname, '.', pg_tables.tablename) IN ( SELECT concat(dataset.schema_name, '.', dataset.table_name) AS concat
           FROM pgmetadata.dataset))) AND (pg_tables.schemaname <> ALL (ARRAY['pg_catalog'::name, 'information_schema'::name])));


-- VIEW v_orphan_tables
COMMENT ON VIEW pgmetadata.v_orphan_tables IS 'View containing the existing tables but not referenced in dataset';


-- v_table_comment_from_metadata
CREATE VIEW pgmetadata.v_table_comment_from_metadata AS
 SELECT d.schema_name AS table_schema,
    d.table_name,
    concat(d.title, ' - ', d.abstract, ' (', array_to_string(d.categories, ', '::text), ')') AS table_comment
   FROM pgmetadata.dataset d;


-- VIEW v_table_comment_from_metadata
COMMENT ON VIEW pgmetadata.v_table_comment_from_metadata IS 'View containing the desired formatted comment for the tables listed in the pgmetadata.dataset table. This view is used by the trigger to update the table comment when the dataset item is added or modified';


--
-- PostgreSQL database dump complete
--

