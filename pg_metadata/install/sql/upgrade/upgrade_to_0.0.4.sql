-- Function calculate_fields_from_data()
CREATE FUNCTION pgmetadata.calculate_fields_from_data() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    my_table text;
    test_geom_column record;
	geom_column_name text;
BEGIN
    my_table = CONCAT(NEW.schema_name, '.', NEW.table_name);
    EXECUTE 'SELECT COUNT(*) FROM ' || my_table
    INTO NEW.feature_count;
    EXECUTE 'SELECT *
    FROM geometry_columns 
    WHERE f_table_schema=' || quote_literal(NEW.schema_name) || ' AND f_table_name=' || quote_literal(NEW.table_name) INTO test_geom_column;
    IF test_geom_column IS NOT NULL THEN
        IF TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND (NEW.geom = OLD.geom AND NEW.projection_authid = OLD.projection_authid AND NEW.geometry_type = OLD.geometry_type AND NEW.spatial_extent = OLD.spatial_extent)) THEN
            geom_column_name = test_geom_column.f_geometry_column;
            EXECUTE 'SELECT CONCAT(min(ST_xmin(' || geom_column_name || '))::text, '', '',  max(ST_xmax(' || geom_column_name || '))::text, '', '', min(ST_ymin(' || geom_column_name || '))::text, '', '', max(ST_ymax(' || geom_column_name || '))::text) FROM '
            || my_table INTO NEW.spatial_extent;
            EXECUTE 'SELECT ST_Transform(ST_ConvexHull(st_collect(' || geom_column_name || ')), 4326) FROM ' || my_table INTO NEW.geom;
            EXECUTE 'SELECT CONCAT(s.auth_name, '':'', ST_SRID(m.' || geom_column_name || ')::text) FROM ' || my_table || ' m, spatial_ref_sys s WHERE s.auth_srid = ST_SRID(m.' || geom_column_name || ') LIMIT 1'
            INTO NEW.projection_authid;
            NEW.geometry_type = test_geom_column.type;
        END IF;
    ELSIF TG_OP = 'UPDATE' THEN
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

