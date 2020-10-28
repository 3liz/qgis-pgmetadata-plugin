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

-- calculate_fields_from_data()
CREATE FUNCTION pgmetadata.calculate_fields_from_data() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    my_table text;
    test_geom_column record;
geom_column_name text;
BEGIN
-- table
    my_table = CONCAT(NEW.schema_name, '.', NEW.table_name);

-- Get table feature count
    EXECUTE 'SELECT COUNT(*) FROM ' || my_table
    INTO NEW.feature_count;
RAISE NOTICE 'pgmetadata - % feature_count: %', my_table, NEW.feature_count;

-- Check geometry properties: get data from geometry_columns
    EXECUTE
' SELECT *' ||
' FROM geometry_columns' ||
' WHERE f_table_schema=' || quote_literal(NEW.schema_name) ||
' AND f_table_name=' || quote_literal(NEW.table_name) ||
' LIMIT 1'
INTO test_geom_column;

-- If the table has a geometry column, calculate field values
    IF test_geom_column IS NOT NULL THEN

-- column name
geom_column_name = test_geom_column.f_geometry_column;
RAISE NOTICE 'pgmetadata - table % has a geometry column: %', my_table, geom_column_name;

-- spatial_extent
EXECUTE 'SELECT CONCAT(min(ST_xmin(' || geom_column_name || '))::text, '', '',  max(ST_xmax(' || geom_column_name || '))::text, '', '', min(ST_ymin(' || geom_column_name || '))::text, '', '', max(ST_ymax(' || geom_column_name || '))::text) FROM '
|| my_table
INTO NEW.spatial_extent;

-- geom: convexhull from target table
EXECUTE 'SELECT ST_Transform(ST_ConvexHull(st_collect(' || geom_column_name || ')), 4326) FROM ' || my_table
INTO NEW.geom;

-- projection_authid
EXECUTE 'SELECT CONCAT(s.auth_name, '':'', ST_SRID(m.' || geom_column_name || ')::text) FROM ' || my_table || ' m, spatial_ref_sys s WHERE s.auth_srid = ST_SRID(m.' || geom_column_name || ') LIMIT 1'
INTO NEW.projection_authid;

-- projection_name
-- TODO

-- geometry_type
NEW.geometry_type = test_geom_column.type;

ELSE
-- No geometry column found: we need to erase values
        NEW.geom = NULL;
        NEW.projection_authid = NULL;
        NEW.geometry_type = NULL;
        NEW.spatial_extent = NULL;
END IF;

    RETURN NEW;
END;
$$;


-- FUNCTION calculate_fields_from_data()
COMMENT ON FUNCTION pgmetadata.calculate_fields_from_data() IS 'Update some fields content when updating or inserting a line in pgmetadata.dataset table.';


-- get_dataset_item_html_content(text, text, text)
CREATE FUNCTION pgmetadata.get_dataset_item_html_content(_table_schema text, _table_name text, _template_section text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    item record;
    html text;
BEGIN

    -- Get main HTML template
    SELECT content
    FROM pgmetadata.html_template AS h
    WHERE True
    AND section = _template_section
    INTO html
    ;

    IF html IS NULL THEN
        RETURN 'No HTML template found';
    END IF;

    -- Get dataset item
    -- We transpose dataset record into rows such as
    -- col    | val
    -- id     | 1
    -- uid    | dfd3b73c-3cd3-40b7-b92d-aa0f625c86fe
    -- ...
    -- title  | My title
    -- For each row, we search and replace the [% "col" %] by val
    FOR item IN
        SELECT (line.d).key AS col, Coalesce((line.d).value, '') AS val
        FROM (
            SELECT json_each_text(row_to_json(d.*)) d
            FROM pgmetadata.dataset AS d
            WHERE True
            AND d.schema_name = _table_schema
            AND d.table_name = _table_name
        ) AS line
    LOOP
        -- replace QGIS style field [% "my_field" %] by field value
        html = regexp_replace(
            html,
            concat('\[%( )*?(")*', item.col ,'(")*( )*%\]'),
            item.val,
            'g'
        )
        ;

    END LOOP;

    RETURN html;

END;
$$;


-- FUNCTION get_dataset_item_html_content(_table_schema text, _table_name text, _template_section text)
COMMENT ON FUNCTION pgmetadata.get_dataset_item_html_content(_table_schema text, _table_name text, _template_section text) IS 'Generate the HTML content for the given table, based on the template stored in the pgmetadata.html_template table.';


-- refresh_dataset_calculated_fields()
CREATE FUNCTION pgmetadata.refresh_dataset_calculated_fields() RETURNS void
    LANGUAGE plpgsql
    AS $$ BEGIN 	UPDATE pgmetadata.dataset SET geom = NULL; END; $$;


-- FUNCTION refresh_dataset_calculated_fields()
COMMENT ON FUNCTION pgmetadata.refresh_dataset_calculated_fields() IS 'Force the calculation of spatial related fields in dataset table by updating all lines, which will trigger the function calculate_fields_from_data';


-- update_postgresql_table_comment(text, text, text)
CREATE FUNCTION pgmetadata.update_postgresql_table_comment(table_schema text, table_name text, table_comment text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    sql_text text;
BEGIN

    BEGIN
        sql_text = 'COMMENT ON TABLE ' || quote_ident(table_schema) || '.' || quote_ident(table_name) || ' IS ' || quote_literal(table_comment) ;
        EXECUTE sql_text;
        RAISE NOTICE 'Comment updated for %s', quote_ident(table_schema) || '.' || quote_ident(table_name) ;
        RETURN True;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'ERROR - Failed updated comment for table %s', quote_ident(table_schema) || '.' || quote_ident(table_name);
        RETURN False;
    END;

    RETURN True;
END;
$$;


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


-- update_table_comment_from_dataset()
CREATE FUNCTION pgmetadata.update_table_comment_from_dataset() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    is_updated bool;
BEGIN
    SELECT pgmetadata.update_postgresql_table_comment(
        v.table_schema,
        v.table_name,
        v.table_comment
    )
    FROM pgmetadata.v_table_comment_from_metadata AS v
    WHERE True
    AND v.table_schema = NEW.schema_name
    AND v.table_name = NEW.table_name
    INTO is_updated
    ;

    RETURN NEW;
END;
$$;


-- FUNCTION update_table_comment_from_dataset()
COMMENT ON FUNCTION pgmetadata.update_table_comment_from_dataset() IS 'Update the PostgreSQL table comment when updating or inserting a line in pgmetadata.dataset table. Comment is taken from the view pgmetadata.v_table_comment_from_metadata.';


--
-- PostgreSQL database dump complete
--

