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


-- HTML
--

UPDATE pgmetadata.glossary SET code = 'txml' WHERE code = 'xml' AND label = 'text/xml';
ALTER TABLE pgmetadata.glossary DROP CONSTRAINT IF EXISTS glossary_field_code_key;
ALTER TABLE pgmetadata.glossary ADD CONSTRAINT glossary_field_code_key UNIQUE (field,code);

-- confidentiality
INSERT INTO pgmetadata.glossary (field, code, label, description, item_order) VALUES
('dataset.confidentiality', 'OPE', 'Open', 'No restriction access for this dataset', 1),
('dataset.confidentiality', 'RES', 'Restricted', 'The dataset access is restricted to some users', 2)
ON CONFLICT DO NOTHING
;

-- publication_frequency
INSERT INTO pgmetadata.glossary (field, code, label, description, item_order) VALUES
('dataset.publication_frequency', 'NEC', 'When necessary', 'Update data when necessary', 1),
('dataset.publication_frequency', 'YEA', 'Yearly', 'Update data yearly', 2),
('dataset.publication_frequency', 'MON', 'Monthly', 'Update data monthly', 3),
('dataset.publication_frequency', 'WEE', 'Weekly', 'Update data weekly', 4),
('dataset.publication_frequency', 'DAY', 'Daily', 'Update data dayly', 5)
ON CONFLICT DO NOTHING
;

-- glossary PKEY
ALTER TABLE pgmetadata.glossary DROP CONSTRAINT IF EXISTS glossary_pkey;
ALTER TABLE pgmetadata.glossary ADD PRIMARY KEY (id);

-- keywords
ALTER TABLE pgmetadata.dataset ALTER COLUMN keywords TYPE text USING array_to_string(keywords, ', ');
COMMENT ON COLUMN pgmetadata.dataset.keywords IS 'List of keywords separated by comma. Ex: environment, paris, trees';

-- Update value list in constraint for html_template.section
ALTER TABLE pgmetadata.html_template DROP constraint if exists html_template_section_check;
ALTER TABLE pgmetadata.html_template ADD constraint html_template_section_check
CHECK (section = ANY (ARRAY['main'::text, 'contact'::text, 'link'::text]));

-- Views with formated data (get label from glossary)
-- v_dataset
DROP VIEW IF EXISTS pgmetadata.v_dataset;
CREATE VIEW pgmetadata.v_dataset AS

WITH
s AS (
    SELECT *
    FROM pgmetadata.dataset d
    LEFT JOIN unnest(categories) AS cat ON True
    WHERE True
    ORDER BY d.id
),
ss AS (
SELECT
    s.id, s.uid, s.table_name, s.schema_name, s.title, s.abstract,
    gcat.label AS cat, s.keywords,
    s.spatial_level, '1/' || s.minimum_optimal_scale AS minimum_optimal_scale, '1/' || s.maximum_optimal_scale AS maximum_optimal_scale,
    s.publication_date, gfre.label AS publication_frequency,
    concat(glic.label, ' (', s.license, ')') AS license,
    gcon.label AS confidentiality,
    s.feature_count, s.geometry_type, (regexp_split_to_array(rs.srtext, '"'))[2] AS projection_name, s.projection_authid, s.spatial_extent,
    s.creation_date, s.update_date

    FROM s
    LEFT JOIN pgmetadata.glossary AS gcat
        ON gcat.field = 'dataset.categories'
        AND gcat.code = cat
    LEFT JOIN pgmetadata.glossary AS gfre
        ON gfre.field = 'dataset.publication_frequency'
        AND gfre.code = s.publication_frequency
    LEFT JOIN pgmetadata.glossary AS glic
        ON glic.field = 'dataset.license'
        AND glic.code = s.license
    LEFT JOIN pgmetadata.glossary AS gcon
        ON gcon.field = 'dataset.confidentiality'
        AND gcon.code = s.confidentiality
    LEFT JOIN public.spatial_ref_sys AS rs
        ON concat(auth_name, ':', auth_srid) = s.projection_authid
)
SELECT id, uid, table_name, schema_name, title, abstract,
string_agg(DISTINCT cat, ', ' ORDER BY cat) AS categories, keywords, spatial_level, minimum_optimal_scale, maximum_optimal_scale,
publication_date, publication_frequency, license, confidentiality,
feature_count, geometry_type, projection_name, projection_authid, spatial_extent,
creation_date, update_date
FROM ss
GROUP BY
id, uid, table_name, schema_name, title, abstract,
keywords, spatial_level, minimum_optimal_scale, maximum_optimal_scale,
publication_date, publication_frequency, license, confidentiality,
feature_count, geometry_type, projection_name, projection_authid, spatial_extent,
creation_date, update_date
;

COMMENT ON VIEW pgmetadata.v_dataset IS 'Formated version of dataset data, with all the codes replaced by corresponding labels taken from pgmetadata.glossary. Used in the function in charge of building the HTML metadata content';

-- v_contact
DROP VIEW IF EXISTS pgmetadata.v_contact;
CREATE VIEW pgmetadata.v_contact AS
SELECT
    d.table_name, d.schema_name,
    c.name, c.organisation_name, c.organisation_unit,
    g.label AS contact_role
FROM pgmetadata.dataset_contact AS dc
INNER JOIN pgmetadata.dataset AS d
    ON d.id = dc.fk_id_dataset
INNER JOIN pgmetadata.contact AS c
    ON dc.fk_id_contact = c.id
INNER JOIN pgmetadata.glossary AS g
    ON g.field = 'contact.contact_role'
    AND g.code = dc.contact_role
WHERE True
ORDER BY dc.id
;

COMMENT ON VIEW pgmetadata.v_contact
IS 'Formated version of contact data, with all the codes replaced by corresponding labels taken from pgmetadata.glossary. Used in the function in charge of building the HTML metadata content'
;

-- v_link
DROP VIEW IF EXISTS pgmetadata.v_link;
CREATE VIEW pgmetadata.v_link AS
SELECT
    l.id, d.table_name, d.schema_name,
    l.name, l.type, g1.label AS type_label,
    l.url, l.description, l.format, l.mime, g2.label AS mime_label
FROM pgmetadata.link AS l
INNER JOIN pgmetadata.dataset AS d
    ON d.id = l.fk_id_dataset
INNER JOIN pgmetadata.glossary AS g1
    ON g1.field = 'link.type'
    AND g1.code = l.type
INNER JOIN pgmetadata.glossary AS g2
    ON g2.field = 'link.mime'
    AND g2.code = l.mime
WHERE True
ORDER BY l.id;

COMMENT ON VIEW pgmetadata.v_link IS 'Formated version of link data, with all the codes replaced by corresponding labels taken from pgmetadata.glossary. Used in the function in charge of building the HTML metadata content'
;


-- fonction pour récupérer
DROP FUNCTION IF EXISTS pgmetadata.generate_html_from_json(json, text);
CREATE OR REPLACE FUNCTION pgmetadata.generate_html_from_json(_json_data json, _template_section text)
RETURNS text
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
            concat('\[%( )*?(")*', item.col ,'(")*( )*%\]'),
            item.val,
            'g'
        )
        ;

    END LOOP;

    RETURN html;

END;
$$;

COMMENT ON FUNCTION pgmetadata.generate_html_from_json(_json_data json, _template_section text)
IS 'Generate HTML content for the given json representation of a record and givensection, based on the template stored in the pgmetadata.html_template table. Template section controlled values: main, contact, link. If the corresponding line is not found in the pgmetadata.html_template table, NULL is returned'
;



CREATE OR REPLACE FUNCTION pgmetadata.get_dataset_item_html_content(_table_schema text, _table_name text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    item record;
    dataset_rec record;
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
    RAISE NOTICE 'html_contact: %', html_contact;

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
    RAISE NOTICE 'html_link: %', html_link;

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
    RAISE NOTICE 'html_main: %', html_main;

    IF html_main IS NULL THEN
        RETURN NULL;
    END IF;

    html = html_main;

    -- add contacts: [% "meta_contacts" %]
    html = regexp_replace(
        html,
        concat('\[%( )*?(")*meta_contacts(")*( )*%\]'),
        coalesce(html_contact, ''),
        'g'
    );

    -- add links [% "meta_links" %]
    html = regexp_replace(
        html,
        concat('\[%( )*?(")*meta_links(")*( )*%\]'),
        coalesce(html_link, ''),
        'g'
    );

    RETURN html;

END;
$$;


-- FUNCTION get_dataset_item_html_content(_table_schema text, _table_name text, _template_section text)
COMMENT ON FUNCTION pgmetadata.get_dataset_item_html_content(_table_schema text, _table_name text)
IS 'Generate the metadata HTML content for the given table, or NULL if no templates are stored in the pgmetadata.html_template table.';

DROP FUNCTION IF EXISTS pgmetadata.get_dataset_item_html_content(text, text, text);
