
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
        EXECUTE '
            SELECT CONCAT(
                min(ST_xmin("' || geom_column_name || '"))::text, '', '',
                max(ST_xmax("' || geom_column_name || '"))::text, '', '',
                min(ST_ymin("' || geom_column_name || '"))::text, '', '',
                max(ST_ymax("' || geom_column_name || '"))::text)
            FROM ' || target_table
        INTO NEW.spatial_extent;

        -- geom: convexhull from target table
        EXECUTE '
            SELECT ST_Transform(ST_ConvexHull(st_collect(ST_Force2d("' || geom_column_name || '"))), 4326)
            FROM ' || target_table
        INTO NEW.geom;

        -- projection_authid
        EXECUTE '
            SELECT CONCAT(s.auth_name, '':'', ST_SRID(m."' || geom_column_name || '")::text)
            FROM ' || target_table || ' m, spatial_ref_sys s
            WHERE s.auth_srid = ST_SRID(m."' || geom_column_name || '")
            LIMIT 1'
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


DROP VIEW IF EXISTS pgmetadata.v_contact;
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

-- v_link
DROP VIEW IF EXISTS pgmetadata.v_link;
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
     LEFT JOIN pgmetadata.glossary g1 ON (((g1.field = 'link.type'::text) AND (g1.code = l.type))))
     LEFT JOIN pgmetadata.glossary g2 ON (((g2.field = 'link.mime'::text) AND (g2.code = l.mime))))
  WHERE true
  ORDER BY l.id;


-- VIEW v_link
COMMENT ON VIEW pgmetadata.v_link IS 'Formatted version of link data, with all the codes replaced by corresponding labels taken from pgmetadata.glossary. Used in the function in charge of building the HTML metadata content.';


-- v_valid_dataset
DROP VIEW IF EXISTS pgmetadata.v_valid_dataset;
CREATE VIEW pgmetadata.v_valid_dataset AS 
 SELECT 
	d.schema_name,
	d.table_name
FROM pgmetadata.dataset AS d
LEFT JOIN pg_tables AS t
	ON d.schema_name = t.schemaname AND d.table_name = t.tablename
WHERE t.tablename IS NOT NULL
ORDER BY d.schema_name, d.table_name;

-- VIEW v_valid_dataset
COMMENT ON VIEW pgmetadata.v_valid_dataset IS 'Gives a list of lines from pgmetadata.dataset with corresponding (existing) tables.';

-- v_orphan_dataset_items
DROP VIEW IF EXISTS pgmetadata.v_orphan_dataset_items;
CREATE VIEW pgmetadata.v_orphan_dataset_items AS
 SELECT row_number() OVER () AS id,
    d.schema_name,
    d.table_name
   FROM (pgmetadata.dataset d
     LEFT JOIN pg_tables t ON (((d.schema_name = (t.schemaname)::text) AND (d.table_name = (t.tablename)::text))))
  WHERE (t.tablename IS NULL)
  ORDER BY d.schema_name, d.table_name;


-- VIEW v_orphan_dataset_items
COMMENT ON VIEW pgmetadata.v_orphan_dataset_items IS 'View containing the tables referenced in dataset but not existing in the database itself.';
