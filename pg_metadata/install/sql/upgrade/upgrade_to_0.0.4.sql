-- View v_orphan_dataset_items
CREATE VIEW pgmetadata.v_orphan_dataset_items AS
SELECT row_number() OVER() AS id, schema_name, table_name 
FROM pgmetadata.dataset
WHERE CONCAT(schema_name, '.', table_name ) NOT IN 
(SELECT CONCAT(schemaname, '.', tablename) FROM pg_tables );

-- View v_orphan_tables
CREATE VIEW pgmetadata.v_orphan_tables AS
SELECT row_number() OVER() AS id, schemaname::text, tablename::text
FROM pg_tables 
WHERE CONCAT(schemaname, '.', tablename) NOT IN 
(SELECT CONCAT(schema_name, '.', table_name ) FROM pgmetadata.dataset )
AND schemaname NOT IN ('pg_catalog', 'information_schema');

-- VIEW v_orphan_dataset_items
COMMENT ON VIEW pgmetadata.v_orphan_dataset_items IS 'View containing the tables referenced in dataset but inexisting';


-- VIEW v_orphan_tables
COMMENT ON VIEW pgmetadata.v_orphan_tables IS 'View containing the existing tables but not referenced in dataset';


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

-- dataset trg_calculate_fields_from_data
CREATE TRIGGER trg_calculate_fields_from_data
    BEFORE INSERT OR UPDATE
    ON pgmetadata.dataset
    FOR EACH ROW
    EXECUTE PROCEDURE pgmetadata.calculate_fields_from_data();


-- refresh_dataset_calculated_fields()
CREATE FUNCTION pgmetadata.refresh_dataset_calculated_fields() RETURNS void
    LANGUAGE plpgsql
    AS $$ BEGIN 	UPDATE pgmetadata.dataset SET geom = NULL; END; $$;


-- FUNCTION refresh_dataset_calculated_fields()
COMMENT ON FUNCTION pgmetadata.refresh_dataset_calculated_fields() IS 'Force the calculation of spatial related fields in dataset table by updating all lines, which will trigger the function calculate_fields_from_data';


-- v_schema_list
DROP VIEW pgmetadata.v_schema_list;
CREATE VIEW pgmetadata.v_schema_list AS
SELECT ROW_NUMBER() OVER() as id, schema_name::text
FROM information_schema.schemata
WHERE schema_name NOT IN ('pg_toast', 'pg_temp_1', 'pg_toast_temp_1', 'pg_catalog', 'information_schema');

-- v_table_list
DROP VIEW pgmetadata.v_table_list;
CREATE VIEW pgmetadata.v_table_list AS
SELECT ROW_NUMBER() OVER() as id, table_schema::text as schema_name, table_name::text
FROM information_schema.tables
WHERE table_schema NOT IN ('pg_toast', 'pg_temp_1', 'pg_toast_temp_1', 'pg_catalog', 'information_schema');

-- VIEW v_schema_list
COMMENT ON VIEW pgmetadata.v_schema_list IS 'View containing list of all schema in this database';

-- VIEW v_table_list
COMMENT ON VIEW pgmetadata.v_table_list IS 'View containing list of all tables in this database with schema name';

