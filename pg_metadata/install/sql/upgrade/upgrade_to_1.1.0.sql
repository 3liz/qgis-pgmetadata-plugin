BEGIN;

-- v_valid_dataset add support for views
-- add ids because in the administration project QGIS automatically sets the first column as key, now all records will be displayed.
DROP VIEW pgmetadata.v_valid_dataset;
CREATE OR REPLACE VIEW pgmetadata.v_valid_dataset
 AS
 SELECT row_number() OVER () AS id,
    d.schema_name,
    d.table_name
   FROM pgmetadata.dataset d
     LEFT JOIN information_schema.tables t ON d.schema_name = t.table_schema::text AND d.table_name = t.table_name::text
  WHERE t.table_name IS NOT NULL
  ORDER BY d.schema_name, d.table_name;

-- VIEW v_valid_dataset
COMMENT ON VIEW pgmetadata.v_valid_dataset IS 'Gives a list of lines from pgmetadata.dataset with corresponding (existing) tables and views.';

-- v_orphan_dataset_items add support for views
CREATE OR REPLACE VIEW pgmetadata.v_orphan_dataset_items
 AS
 SELECT row_number() OVER () AS id,
    d.schema_name,
    d.table_name
   FROM pgmetadata.dataset d
     LEFT JOIN information_schema.tables t ON (((d.schema_name = (t.table_schema)::text) AND (d.table_name = (t.table_name)::text)))
  WHERE (t.table_name IS NULL)
  ORDER BY d.schema_name, d.table_name;

-- v_orphan_tables add support for views
CREATE OR REPLACE VIEW pgmetadata.v_orphan_tables
 AS
 SELECT row_number() OVER () AS id,
    (tables.table_schema)::text AS schemaname,
    (tables.table_name)::text AS tablename
   FROM information_schema.tables
  WHERE ((NOT (concat(tables.table_schema, '.', tables.table_name) IN ( SELECT concat(dataset.schema_name, '.', dataset.table_name) AS concat
           FROM pgmetadata.dataset))) AND (tables.table_schema <> ALL (ARRAY['pg_catalog'::name, 'information_schema'::name])))
  ORDER BY ((tables.table_schema)::text), ((tables.table_name)::text);

-- add ids, see above.
-- extend with (adapted) table_types (information_schema.tables) to be used by the comment trigger function. 
-- table_type ~~ 'FOREIGN%' is due to compatibility with PG>10.
DROP VIEW pgmetadata.v_table_comment_from_metadata;
CREATE VIEW pgmetadata.v_table_comment_from_metadata AS
 SELECT row_number() OVER () AS id,
    d.schema_name AS table_schema,
    d.table_name,
    concat(d.title, ' - ', d.abstract, ' (', array_to_string(d.categories, ', '::text), ')') AS table_comment,
        CASE
            WHEN ((t.table_type)::text = 'BASE TABLE'::text) THEN 'TABLE'::text
            WHEN ((t.table_type)::text ~~ 'FOREIGN%'::text) THEN 'FOREIGN TABLE'::text
            ELSE (t.table_type)::text
        END AS table_type
   FROM (pgmetadata.dataset d
      LEFT JOIN information_schema.tables t ON (((d.schema_name = (t.table_schema)::text) AND (d.table_name = (t.table_name)::text))));

-- VIEW v_table_comment_from_metadata
COMMENT ON VIEW pgmetadata.v_table_comment_from_metadata IS 'View containing the desired formatted comment for the tables listed in the pgmetadata.dataset table. This view is used by the trigger to update the table comment when the dataset item is added or modified';


--extend function update_postgresql_table_comment(text, text, text) for working on all sorts of table types
DROP FUNCTION pgmetadata.update_postgresql_table_comment(text, text, text);

-- update_postgresql_table_comment(text, text, text, text)
-- extending the sql_text with adapted table_types from v_table_comment_from_metadata.
CREATE FUNCTION pgmetadata.update_postgresql_table_comment(table_schema text, table_name text, table_comment text, table_type text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    sql_text text;
BEGIN

    BEGIN
        sql_text = 'COMMENT ON ' || replace(quote_literal(table_type), '''', '') || ' ' || quote_ident(table_schema) || '.' || quote_ident(table_name) || ' IS ' || quote_literal(table_comment) ;
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


-- FUNCTION update_postgresql_table_comment(table_schema text, table_name text, table_comment text, table_type text)
COMMENT ON FUNCTION pgmetadata.update_postgresql_table_comment(table_schema text, table_name text, table_comment text, table_type text) IS 'Update the PostgreSQL comment of a table by giving table schema, name and comment
Example: if you need to update the comments for all the items listed by pgmetadata.v_table_comment_from_metadata:

    SELECT
    v.table_schema,
    v.table_name,
    pgmetadata.update_postgresql_table_comment(
        v.table_schema,
        v.table_name,
        v.table_comment,
        v.table_type
    ) AS comment_updated
    FROM pgmetadata.v_table_comment_from_metadata AS v

    ';


-- update_table_comment_from_dataset()
DROP FUNCTION pgmetadata.update_table_comment_from_dataset() CASCADE;
CREATE FUNCTION pgmetadata.update_table_comment_from_dataset() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    is_updated bool;
BEGIN
    SELECT pgmetadata.update_postgresql_table_comment(
        v.table_schema,
        v.table_name,
        v.table_comment,
        v.table_type
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

-- restore trigger
CREATE TRIGGER trg_update_table_comment_from_dataset AFTER INSERT OR UPDATE ON pgmetadata.dataset FOR EACH ROW EXECUTE PROCEDURE pgmetadata.update_table_comment_from_dataset();



CREATE OR REPLACE FUNCTION pgmetadata.calculate_fields_from_data() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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

    EXECUTE
    ' SELECT *' ||
    ' FROM raster_columns' ||
    ' WHERE r_table_schema=' || quote_literal(NEW.schema_name) ||
    ' AND r_table_name=' || quote_literal(NEW.table_name) ||
    ' LIMIT 1'
    INTO test_rast_column;

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

        -- TODO: is this the best way to get the raster extent? Could we use ST_xmin etc. on test_rast_column.extent?
        EXECUTE '
            SELECT CONCAT(
                min(ST_xmin(extent))::text, '', '',
                max(ST_xmax(extent))::text, '', '',
                min(ST_ymin(extent))::text, '', '',
                max(ST_ymax(extent))::text)
            FROM raster_columns
            WHERE r_table_schema=' || quote_literal(NEW.schema_name) ||
              'AND r_table_name=' || quote_literal(NEW.table_name)
        INTO NEW.spatial_extent;
        
        -- convexhull from target table
        EXECUTE '
            SELECT ST_Transform(ST_ConvexHull("' || rast_column_name || '"), 4326)
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
            SELECT CONCAT(s.auth_name, '':'', ST_SRID(m."' || rast_column_name || '")::text)
            FROM ' || target_table || ' m, spatial_ref_sys s
            WHERE s.auth_srid = ST_SRID(m."' || rast_column_name || '")
            LIMIT 1'
        INTO NEW.projection_authid;

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
$$;

-- FUNCTION calculate_fields_from_data()
COMMENT ON FUNCTION pgmetadata.calculate_fields_from_data() IS 'Update some fields content when updating or inserting a line in pgmetadata.dataset table.';



-- GLOSSARY

-- German translations

CREATE TABLE pgmetadata.t_glossary (field text, code text, label_de text, description_de text);
INSERT INTO pgmetadata.t_glossary (field, code, label_de, description_de)
VALUES
('link.type', 'OGC:GPKG', 'OGC Geopackage', 'SQLite-Erweiterung für den Austausch und direkte Verwendung von räumlichen Vektor-Geodaten und/oder Kachel-Matrizen von Bildern und Rasterkarten in unterschiedlichen Maßstäben'),
('link.type', 'ESRI:MPK', 'ArcGIS Map Package', 'URI eines ArcGIS Map Packages. MPK ist ein Dateiformat, das ein Kartendokument (.mxd) und die von den Layern genutzten Daten in einer einfach austauschbaren Datei enthält'),
('link.type', 'WWW:LINK', 'Web-Adresse (URL)', 'Zeigt an, dass XLINK-Eigenschaften als Schlüssel-Wert-Paare im Inhalt eines dct:references-Elements enhalten sind, um einen maschinell auswertbaren Link bereitzustellen.'),
('link.type', 'information', 'Link liefert Informationen über die Ressource', 'Link für http:GET von Informationen über die Ressource'),
('link.type', 'download', 'Link lädt die Ressource', 'Link für http:GET einer Repräsentation der Ressource; das/die Link-Typ-Attribut(e) sollten die MIME-Typen der verfügbaren Repräsentationen angeben'),
('link.type', 'service', 'Link ist Service-Endpunkt', 'Der Link ist der URL eines Service-Endpunkts; das Link-Protokoll und applicationProfile-Attributwert (und möglicherweise weitere Linkeigenschaften wie overlayAPI, abhängig vom verwendeten Link-Attribut-Profil) sollten die Service-Protokollspezifikation identifizieren'),
('link.type', 'order', 'Link stellt Formular zum Erwerb der Ressource zur Verfügung', 'Linkziel ist der URL einer Webanwendung, die Benutzerinteraktion zum Erwerb der bzw. Anfrage zur Bereitstellung der Ressource erfordert'),
('link.type', 'search', 'Link stellt Formular zur Suche der Ressource zur Verfügung', 'Linkziel ist der URL einer Webanwendung, die Benutzerinteraktion zum Suchen/Auswählen der Resoource erfordert'),
('link.type', 'file', 'eine Datei', 'CKAN Metadata Vocabulary, um die Typattribute einer CKAN-Ressource zu füllen; zeigt an, dass ein http:GET dieses URL einen Bitstream liefern sollte'),
('link.type', 'ISO 19115:2003/19139', 'ISO19115-Metadaten in ISO19139-Kodierung', 'Dies ist der CharacterString, der von Geonetwork OpenSource genutzt wird, um ISO-Metadateneintragsinstanzen zu identifizieren; offensichtlich ist anzunehmen, dass es das Korrigendum von 2006 ohne spezifische Profil-Konventionen nutzt.'),
('link.type', 'OSM', 'OpenStreetMap-Schnittstelle', 'gmd:protocol-Wert, der anzeigt, dass die CI_OnlineResource-URL für eine OSM-API zum Holen und Speichern von Roh-Geodaten von/zu einer OpenStreetMap-Datenbank ist'),
('dataset.license', 'CC0', 'Creative Commons Zero', NULL),
('dataset.license', 'CC-BY-4.0', 'Creative Commons Namensnennung – Version 4.0', NULL),
('dataset.license', 'CC-BY-SA-4.0', 'Creative Commons  Namensnennung – Weitergabe unter gleichen Bedingungen – Version 4.0', NULL),
('dataset.license', 'ODC-BY', 'Open Data Commons Namensnennung', NULL),
('dataset.license', 'ODBL', 'Open Data Commons Lizenz für Datenbankinhalte', NULL),
('dataset.license', 'PDDL', 'Open Data Commons Gemeinfreiheit-Widmung und Lizenz', NULL),
('dataset.license', 'dl-de/by-2-0', 'Datenlizenz Deutschland – Namensnennung – Version 2.0', NULL),
('dataset.license', 'proj', 'nur für Projektbearbeitung', NULL),
('contact.contact_role', 'CU', 'Verwalter', 'Person oder Stelle, welche die Zuständigkeit und Verantwortlichkeit für einen Datensatz übernommen hat und seine sachgerechte Pflege und Wartung sichert'),
('contact.contact_role', 'DI', 'Vertrieb', 'Person oder Stelle für den Vertrieb'),
('contact.contact_role', 'OW', 'Eigentümer', 'Eigentümer der Ressource'),
('dataset.categories', 'HEA', 'Gesundheitswesen ', 'Gesundheit, Gesundheitsdienste, Humanökologie und Betriebssicherheit'),
('dataset.categories', 'ELE', 'Höhenangaben', 'Höhenangabe bezogen auf ein Höhenreferenzsystem'),
('dataset.categories', 'GEO', 'Geowissenschaften', 'geowissenschaftliche Informationen'),
('dataset.categories', 'PLA', 'Planungsunterlagen, Kataster', 'Informationen für die Flächennutzungsplanung'),
('dataset.categories', 'INL', 'Binnengewässer', 'Binnengewässerdaten, Gewässernetze und deren Eigenschaften'),
('dataset.categories', 'BOU', 'Grenzen', 'gesetzlich festgelegte Grenzen'),
('dataset.categories', 'STR', 'Bauwerke', 'anthropogene Bauten'),
('dataset.categories', 'TRA', 'Verkehrswesen', 'Mittel und Wege zur Beförderung von Personen und/oder Gütern'),
('dataset.categories', 'INT', 'Militär und Aufklärung', 'Militärbasen, militärische Einrichtungen und Aktivitäten'),
('dataset.categories', 'LOC', 'Ortsangaben', 'Positionierungsangaben und -dienste'),
('dataset.categories', 'CLI', 'Atmosphäre', 'Prozesse und Naturereignisse der Atmosphäre inkl. Klimatologie und Meteorologie'),
('dataset.categories', 'FAR', 'Landwirtschaft', 'Tierzucht und/oder Pflanzenanbau'),
('dataset.categories', 'ENV', 'Umwelt', 'Umweltressourcen, Umweltschutz und Umwelterhaltung'),
('dataset.categories', 'OCE', 'Meere', 'Merkmale und Charakteristika von salzhaltigen  Gewässern (außer Binnengewässern)'),
('dataset.categories', 'BIO', 'Biologie', 'Flora und/oder Fauna in der natürlichen Umgebung'),
('dataset.categories', 'IMA', 'Oberflächenbeschreibung', 'Basiskarten und -daten'),
('dataset.categories', 'SOC', 'Gesellschaft', 'kulturelle und gesellschaftliche Merkmale'),
('dataset.categories', 'ECO', 'Wirtschaft', 'wirtschaftliche Aktivitäten, Verhältnisse und Beschäftigung'),
('dataset.categories', 'UTI', 'Ver- und Entsorgung, Kommunikation', 'Energie-, Wasser- und Abfallsysteme, Kommunikationsinfrastruktur und -dienste'),
('dataset.confidentiality', 'OPE', 'offen', 'Keine Einschränkungen des Zugriffs auf diese Daten'),
('dataset.confidentiality', 'RES', 'eingeschränkt', 'Der Zugriff auf die Daten ist auf ausgewählte Nutzer beschränkt'),
('dataset.publication_frequency', 'DAY', 'täglich', 'Daten werden täglich aktualisiert'),
('dataset.publication_frequency', 'MON', 'monatlich',  'Daten werden monatlich aktualisiert'),
('dataset.publication_frequency', 'YEA', 'jährlich', 'Daten werden jährlich aktualisiert'),
('dataset.publication_frequency', 'NEC', 'bei Bedarf',  'Daten werden bei Bedarf aktualisiert'),
('dataset.publication_frequency', 'WEE', 'wöchentlich', 'Daten werden wöchentlich aktualisiert')
ON CONFLICT DO NOTHING;

UPDATE pgmetadata.glossary AS g
SET (label_de, description_de)
= (t.label_de, t.description_de)
FROM pgmetadata.t_glossary AS t
WHERE g.field = t.field AND g.code = t.code;

DROP TABLE pgmetadata.t_glossary;


-- new terms

INSERT INTO pgmetadata.glossary (id, field, code, label_en, description_en, item_order, label_fr, description_fr, label_it, description_it, label_es, description_es, label_de, description_de) VALUES
(130, 'dataset.license', 'dl-de/by-2-0', 'Data licence Germany – attribution – version 2.0', NULL, 80, NULL, NULL, NULL, NULL, NULL, NULL, 'Datenlizenz Deutschland – Namensnennung – Version 2.0', NULL),
(131, 'dataset.license', 'proj', 'Restricted use for project-related work', NULL, 90, NULL, NULL, NULL, NULL, NULL, NULL, 'nur für Projektbearbeitung', NULL)
ON CONFLICT DO NOTHING;

INSERT INTO pgmetadata.glossary (id, field, code, label_en, description_en, item_order, label_fr, description_fr, label_it, description_it, label_es, description_es, label_de,
description_de) VALUES (132, 'dataset.publication_frequency', 'BIA', 'Biannually', 'Update data twice each year', 3, NULL, NULL, NULL, NULL, NULL, NULL, 'halbjährlich', 'Daten werden halbjährlich aktualisiert');
INSERT INTO pgmetadata.glossary (id, field, code, label_en, description_en, item_order, label_fr, description_fr, label_it, description_it, label_es, description_es, label_de, description_de) VALUES (133, 'dataset.publication_frequency', 'IRR', 'Irregular', 'Data is updated in intervals that are uneven in duration', 7, NULL, NULL, NULL, NULL, NULL, NULL, 'unregelmäßig', 'Daten werden unregelmäßig aktualisiert');
INSERT INTO pgmetadata.glossary (id, field, code, label_en, description_en, item_order, label_fr, description_fr, label_it, description_it, label_es, description_es, label_de, description_de) VALUES (134, 'dataset.publication_frequency', 'NOP', 'Not planned', 'There are no plans to update the data', 8, NULL, NULL, NULL, NULL, NULL, NULL, 'nicht geplant', 'eine Aktualisierung der Daten ist nicht geplant');
INSERT INTO pgmetadata.glossary (id, field, code, label_en, description_en, item_order, label_fr, description_fr, label_it, description_it, label_es, description_es, label_de, description_de) VALUES (135, 'contact.contact_role', 'OR', 'Originator', 'Party who created the resource', 40, NULL, NULL, NULL, NULL, NULL, NULL, 'Urheber', 'Erzeuger der Ressource');
INSERT INTO pgmetadata.glossary (id, field, code, label_en, description_en, item_order, label_fr, description_fr, label_it, description_it, label_es, description_es, label_de, description_de) VALUES (136, 'contact.contact_role', 'PR', 'Processor', 'Party who has processed the data in a manner such that the resource has been modified', 50, NULL, NULL, NULL, NULL, NULL, NULL, 'Bearbeiter', 'Person oder Stelle, die die Ressource in einem Arbeitsschritt verändert hat');

-- update item order of existing frequencies;
update pgmetadata.glossary set item_order = item_order + 1
where field = 'dataset.publication_frequency' and code in ('DAY', 'WEE', 'MON');


SELECT pg_catalog.setval('pgmetadata.glossary_id_seq', 136, true);

-- Issue #75, also update "update_date"

CREATE OR REPLACE FUNCTION pgmetadata.calculate_fields_from_data() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    test_target_table regclass;
    target_table text;
    test_geom_column record;
    geom_envelop geometry;
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

    -- Date fields
    NEW.update_date = now();
    IF TG_OP = 'INSERT' THEN
        NEW.creation_date = now();
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

COMMIT;
