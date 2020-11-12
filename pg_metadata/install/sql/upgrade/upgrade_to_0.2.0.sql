
CREATE OR REPLACE FUNCTION pgmetadata.calculate_fields_from_data() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    test_target_table regclass;
    target_table text;
    test_geom_column record;
geom_column_name text;
BEGIN

    -- table
    target_table = quote_ident(NEW.schema_name) || '.' || quote_ident(NEW.table_name);
    IF target_table IS NULL THEN
        RETURN NEW;
    END IF;

    -- Check if table exists
    EXECUTE 'SELECT to_regclass(' || quote_literal(target_table) ||')'
    INTO test_target_table
    ;
    IF test_target_table IS NULL THEN
        RAISE NOTICE 'pgmetadata - table does not exists: %', target_table;
        RETURN NEW;
    END IF;

-- Get table feature count
    EXECUTE 'SELECT COUNT(*) FROM ' || target_table
    INTO NEW.feature_count;
    -- RAISE NOTICE 'pgmetadata - % feature_count: %', target_table, NEW.feature_count;

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
        RAISE NOTICE 'pgmetadata - table % has a geometry column: %', target_table, geom_column_name;

        -- spatial_extent
        EXECUTE 'SELECT CONCAT(min(ST_xmin(' || geom_column_name || '))::text, '', '',  max(ST_xmax(' || geom_column_name || '))::text, '', '', min(ST_ymin(' || geom_column_name || '))::text, '', '', max(ST_ymax(' || geom_column_name || '))::text) FROM '
        || target_table
        INTO NEW.spatial_extent;

        -- geom: convexhull from target table
        EXECUTE 'SELECT ST_Transform(ST_ConvexHull(st_collect(' || geom_column_name || ')), 4326) FROM ' || target_table
        INTO NEW.geom;

        -- projection_authid
        EXECUTE 'SELECT CONCAT(s.auth_name, '':'', ST_SRID(m.' || geom_column_name || ')::text) FROM ' || target_table || ' m, spatial_ref_sys s WHERE s.auth_srid = ST_SRID(m.' || geom_column_name || ') LIMIT 1'
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


INSERT INTO pgmetadata.glossary (field, code, label) VALUES
('dataset.license', 'LO-2.0', 'Licence Ouverte Version 2.0'),
('dataset.license', 'LO-2.1', 'Licence Ouverte Version 2.1')
ON CONFLICT DO NOTHING
;


ALTER TABLE pgmetadata.dataset ADD COLUMN IF NOT EXISTS data_last_update timestamp;
COMMENT ON COLUMN pgmetadata.dataset.data_last_update IS 'Date of the last modification of the target data (not on the dataset item line)';

