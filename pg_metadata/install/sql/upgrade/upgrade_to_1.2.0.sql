BEGIN;


DROP FUNCTION pgmetadata.calculate_fields_from_data() CASCADE;
CREATE FUNCTION pgmetadata.calculate_fields_from_data() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$
DECLARE
    test_target_table regclass;
    target_table text;
    test_geom_column record;
    test_rast_column record;
    geom_envelop geometry;
    geom_column_name text;
    rast_column_name text;
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

    -- Date fields
    NEW.update_date = now();
    IF TG_OP = 'INSERT' THEN
        NEW.creation_date = now();
    END IF;

    -- Get table feature count
    EXECUTE 'SELECT COUNT(*) FROM ' || target_table
    INTO NEW.feature_count;
    -- RAISE NOTICE 'pgmetadata - % feature_count: %', target_table, NEW.feature_count;

    -- Check geometry properties: get data from geometry_columns and raster_columns
    EXECUTE
    ' SELECT *' ||
    ' FROM geometry_columns' ||
    ' WHERE f_table_schema=' || quote_literal(NEW.schema_name) ||
    ' AND f_table_name=' || quote_literal(NEW.table_name) ||
    ' LIMIT 1'
    INTO test_geom_column;

    IF to_regclass('raster_columns') is not null THEN
        EXECUTE
        ' SELECT *' ||
        ' FROM raster_columns' ||
        ' WHERE r_table_schema=' || quote_literal(NEW.schema_name) ||
        ' AND r_table_name=' || quote_literal(NEW.table_name) ||
        ' LIMIT 1'
        INTO test_rast_column;
    ELSE
        select null into test_rast_column;
    END IF;

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
        INTO geom_envelop;

        -- Test if it's not a point or a line
        IF GeometryType(geom_envelop) != 'POLYGON' THEN
            EXECUTE '
                SELECT ST_SetSRID(ST_Buffer(ST_GeomFromText(''' || ST_ASTEXT(geom_envelop) || '''), 0.0001), 4326)'
            INTO NEW.geom;
        ELSE
            NEW.GEOM = geom_envelop;
        END IF;

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

    ELSIF test_rast_column is not null THEN

        -- column name
        rast_column_name = test_rast_column.r_raster_column;
        RAISE NOTICE 'pgmetadata - table % has a raster column: %', target_table, rast_column_name;

        -- spatial_extent
        EXECUTE 'SELECT CONCAT(ST_xmin($1)::text, '', '', ST_xmax($1)::text, '', '',
                               ST_ymin($1)::text, '', '', ST_ymax($1)::text)'
        INTO NEW.spatial_extent
        USING test_rast_column.extent;

        -- use extent (of whole table) from raster_columns catalog as envelope
        -- (union of convexhull of all rasters (tiles) in target table is too slow for big tables)
        EXECUTE 'SELECT ST_Transform($1, 4326)'
        INTO geom_envelop
        USING test_rast_column.extent;

        -- Test if it's not a point or a line
        IF GeometryType(geom_envelop) != 'POLYGON' THEN
            EXECUTE '
                SELECT ST_SetSRID(ST_Buffer(ST_GeomFromText(''' || ST_ASTEXT(geom_envelop) || '''), 0.0001), 4326)'
            INTO NEW.geom;
        ELSE
            NEW.GEOM = geom_envelop;
        END IF;

        -- projection_authid (use test_rast_column because querying table similar to vector layer is very slow)
        EXECUTE 'SELECT CONCAT(auth_name, '':'', $1) FROM spatial_ref_sys WHERE auth_srid = $1'
        INTO NEW.projection_authid
        USING test_rast_column.srid;

        -- geometry_type
        NEW.geometry_type = 'RASTER';

    ELSE
    -- No geometry column found: we need to erase values
            NEW.geom = NULL;
            NEW.projection_authid = NULL;
            NEW.geometry_type = NULL;
            NEW.spatial_extent = NULL;
    END IF;

    RETURN NEW;
END;
$_$;

-- FUNCTION calculate_fields_from_data()
COMMENT ON FUNCTION pgmetadata.calculate_fields_from_data() IS 'Update some fields content when updating or inserting a line in pgmetadata.dataset table.';

-- restore trigger
CREATE TRIGGER trg_calculate_fields_from_data BEFORE INSERT OR UPDATE ON pgmetadata.dataset FOR EACH ROW EXECUTE PROCEDURE pgmetadata.calculate_fields_from_data();



DROP FUNCTION pgmetadata.update_postgresql_table_comment(text, text, text, text);
CREATE FUNCTION pgmetadata.update_postgresql_table_comment(table_schema text, table_name text, table_comment text, table_type text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    sql_text text;
BEGIN

    BEGIN
        sql_text = 'COMMENT ON ' || replace(quote_literal(table_type), '''', '') || ' ' || quote_ident(table_schema) || '.' || quote_ident(table_name) || ' IS ' || quote_literal(table_comment) ;
        EXECUTE sql_text;
        RAISE NOTICE 'Comment updated for %', quote_ident(table_schema) || '.' || quote_ident(table_name) ;
        RETURN True;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'ERROR - Failed updated comment for table %', quote_ident(table_schema) || '.' || quote_ident(table_name);
        RETURN False;
    END;

    RETURN True;
END;
$$;


-- Issue #115 (fix backslashes in regexp substition for HTML templates)

-- generate_html_from_json(json, text)
DROP FUNCTION IF EXISTS pgmetadata.generate_html_from_json(json, text);
CREATE OR REPLACE FUNCTION pgmetadata.generate_html_from_json(_json_data json, _template_section text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    item record;
    html text;
BEGIN

    -- Get HTML template from html_template table
    SELECT content
    FROM pgmetadata.html_template AS h
    WHERE True
    AND section = _template_section
    INTO html
    ;
    IF html IS NULL THEN
        RETURN NULL;
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
            SELECT json_each_text(_json_data) d
        ) AS line
    LOOP
        -- replace QGIS style field [% "my_field" %] by field value
        html = regexp_replace(
            html,
            concat('\[% *"?', item.col, '"? *%\]'),
            replace(item.val, $quote$\$quote$, $quote$\\$quote$), -- escape backslashes in substitution string (\1...\9 refer to subexpressions)
            'g'
        )
        ;

    END LOOP;

    RETURN html;

END;
$$;

-- FUNCTION generate_html_from_json(_json_data json, _template_section text)
COMMENT ON FUNCTION pgmetadata.generate_html_from_json(_json_data json, _template_section text) IS 'Generate HTML content for the given JSON representation of a record and a given section, based on the template stored in the pgmetadata.html_template table. Template section controlled values are "main", "contact" and "link". If the corresponding line is not found in the pgmetadata.html_template table, NULL is returned.';


-- get_dataset_item_html_content(text, text, text)
DROP FUNCTION IF EXISTS get_dataset_item_html_content(text, text, text);
CREATE OR REPLACE FUNCTION pgmetadata.get_dataset_item_html_content(_table_schema text, _table_name text, _locale text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    locale_exists boolean;
    item record;
    dataset_rec record;
    sql_text text;
    json_data json;
    html text;
    html_contact text;
    html_link text;
    html_main text;
BEGIN
    -- Check if dataset exists
    SELECT *
    FROM pgmetadata.dataset
    WHERE True
    AND schema_name = _table_schema
    AND table_name = _table_name
    LIMIT 1
    INTO dataset_rec
    ;

    IF dataset_rec.id IS NULL THEN
        RETURN NULL;
    END IF;

    -- Check if the _locale parameter corresponds to the available locales
    _locale = lower(_locale);
    SELECT _locale IN (SELECT locale FROM pgmetadata.v_locales)
    INTO locale_exists
    ;
    IF NOT locale_exists THEN
        _locale = 'en';
    END IF;

    -- Set locale
    -- We must use EXECUTE in order to have _locale to be correctly interpreted
    sql_text = concat('SET SESSION "pgmetadata.locale" = ', quote_literal(_locale));
    EXECUTE sql_text;

    -- Contacts
    html_contact = '';
    FOR json_data IN
        WITH a AS (
            SELECT *
            FROM pgmetadata.v_contact
            WHERE True
            AND schema_name = _table_schema
            AND table_name = _table_name
        )
        SELECT row_to_json(a.*)
        FROM a
    LOOP
        html_contact = concat(
            html_contact, '
            ',
            pgmetadata.generate_html_from_json(json_data, 'contact')
        );
    END LOOP;
    -- RAISE NOTICE 'html_contact: %', html_contact;

    -- Links
    html_link = '';
    FOR json_data IN
        WITH a AS (
            SELECT *
            FROM pgmetadata.v_link
            WHERE True
            AND schema_name = _table_schema
            AND table_name = _table_name
        )
        SELECT row_to_json(a.*)
        FROM a
    LOOP
        html_link = concat(
            html_link, '
            ',
            pgmetadata.generate_html_from_json(json_data, 'link')
        );
    END LOOP;
    --RAISE NOTICE 'html_link: %', html_link;

    -- Main
    html_main = '';
    WITH a AS (
        SELECT *
        FROM pgmetadata.v_dataset
        WHERE True
        AND schema_name = _table_schema
        AND table_name = _table_name
    )
    SELECT row_to_json(a.*)
    FROM a
    INTO json_data
    ;
    html_main = pgmetadata.generate_html_from_json(json_data, 'main');
    -- RAISE NOTICE 'html_main: %', html_main;

    IF html_main IS NULL THEN
        RETURN NULL;
    END IF;

    html = html_main;

    -- add contacts: [% "meta_contacts" %]
    html = regexp_replace(
        html,
        concat('\[% *"?meta_contacts"? *%\]'),
        coalesce(replace(html_contact, $quote$\$quote$, $quote$\\$quote$), ''), -- escape backslashes in substitution string (\1...\9 refer to subexpressions)
        'g'
    );

    -- add links [% "meta_links" %]
    html = regexp_replace(
        html,
        concat('\[% *"?meta_links"? *%\]'),
        coalesce(replace(html_link, $quote$\$quote$, $quote$\\$quote$), ''), -- escape backslashes in substitution string (\1...\9 refer to subexpressions)
        'g'
    );

    RETURN html;

END;
$$;

COMMENT ON FUNCTION pgmetadata.get_dataset_item_html_content(_table_schema text, _table_name text, _locale text) IS 'Generate the metadata HTML content for the given table and given language or NULL if no templates are stored in the pgmetadata.html_template table.';


COMMIT;
