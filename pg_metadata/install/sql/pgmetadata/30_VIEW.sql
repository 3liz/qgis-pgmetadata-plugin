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

-- v_glossary
CREATE VIEW pgmetadata.v_glossary AS
 WITH one AS (
         SELECT glossary.field,
            glossary.code,
            json_build_object('label', json_build_object('en', glossary.label, 'fr', COALESCE(NULLIF(glossary.label_fr, ''::text), glossary.label, ''::text), 'it', COALESCE(NULLIF(glossary.label_it, ''::text), glossary.label, ''::text), 'es', COALESCE(NULLIF(glossary.label_es, ''::text), glossary.label, ''::text), 'de', COALESCE(NULLIF(glossary.label_de, ''::text), glossary.label, ''::text)), 'description', json_build_object('en', glossary.description, 'fr', COALESCE(NULLIF(glossary.description_fr, ''::text), glossary.description, ''::text), 'it', COALESCE(NULLIF(glossary.description_it, ''::text), glossary.description, ''::text), 'es', COALESCE(NULLIF(glossary.description_es, ''::text), glossary.description, ''::text), 'de', COALESCE(NULLIF(glossary.description_de, ''::text), glossary.description, ''::text))) AS dict
           FROM pgmetadata.glossary
        ), two AS (
         SELECT one.field,
            json_object_agg(one.code, one.dict) AS dict
           FROM one
          GROUP BY one.field
        )
 SELECT json_object_agg(two.field, two.dict) AS dict
   FROM two;


-- VIEW v_glossary
COMMENT ON VIEW pgmetadata.v_glossary IS 'View transforming the glossary content into a JSON helping to localize a label or description by fetching directly the corresponding item. Ex: SET SESSION "pgmetadata.locale" = ''fr''; WITH glossary AS (SELECT dict FROM pgmetadata.v_glossary) SELECT (dict->''contact.contact_role''->''OW''->''label''->''fr'')::text AS label FROM glossary;';


-- v_contact
CREATE VIEW pgmetadata.v_contact AS
 WITH glossary AS (
         SELECT COALESCE(current_setting('pgmetadata.locale'::text, true), 'en'::text) AS locale,
            v_glossary.dict
           FROM pgmetadata.v_glossary
        )
 SELECT d.table_name,
    d.schema_name,
    c.name,
    c.organisation_name,
    c.organisation_unit,
    ((((glossary.dict -> 'contact.contact_role'::text) -> dc.contact_role) -> 'label'::text) ->> glossary.locale) AS contact_role,
    c.email
   FROM glossary,
    ((pgmetadata.dataset_contact dc
     JOIN pgmetadata.dataset d ON ((d.id = dc.fk_id_dataset)))
     JOIN pgmetadata.contact c ON ((dc.fk_id_contact = c.id)))
  WHERE true
  ORDER BY dc.id;


-- VIEW v_contact
COMMENT ON VIEW pgmetadata.v_contact IS 'Formatted version of contact data, with all the codes replaced by corresponding labels taken from pgmetadata.glossary. Used in the function in charge of building the HTML metadata content. The localized version of labels and descriptions are taken considering the session setting ''pgmetadata.locale''. For example with: SET SESSION "pgmetadata.locale" = ''fr''; ';


-- v_dataset
CREATE VIEW pgmetadata.v_dataset AS
 WITH glossary AS (
         SELECT COALESCE(current_setting('pgmetadata.locale'::text, true), 'en'::text) AS locale,
            v_glossary.dict
           FROM pgmetadata.v_glossary
        ), s AS (
         SELECT d.id,
            d.uid,
            d.table_name,
            d.schema_name,
            d.title,
            d.abstract,
            d.categories,
            d.themes,
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
            d.data_last_update,
            d.geom,
            cat.cat,
            theme.theme
           FROM ((pgmetadata.dataset d
             LEFT JOIN LATERAL unnest(d.categories) cat(cat) ON (true))
             LEFT JOIN LATERAL unnest(d.themes) theme(theme) ON (true))
          WHERE true
          ORDER BY d.id
        ), ss AS (
         SELECT s.id,
            s.uid,
            s.table_name,
            s.schema_name,
            s.title,
            s.abstract,
            ((((glossary.dict -> 'dataset.categories'::text) -> s.cat) -> 'label'::text) ->> glossary.locale) AS cat,
            gtheme.label AS theme,
            s.keywords,
            s.spatial_level,
            ('1/'::text || s.minimum_optimal_scale) AS minimum_optimal_scale,
            ('1/'::text || s.maximum_optimal_scale) AS maximum_optimal_scale,
            s.publication_date,
            ((((glossary.dict -> 'dataset.publication_frequency'::text) -> s.publication_frequency) -> 'label'::text) ->> glossary.locale) AS publication_frequency,
            ((((glossary.dict -> 'dataset.license'::text) -> s.license) -> 'label'::text) ->> glossary.locale) AS license,
            ((((glossary.dict -> 'dataset.confidentiality'::text) -> s.confidentiality) -> 'label'::text) ->> glossary.locale) AS confidentiality,
            s.feature_count,
            s.geometry_type,
            (regexp_split_to_array((rs.srtext)::text, '"'::text))[2] AS projection_name,
            s.projection_authid,
            s.spatial_extent,
            s.creation_date,
            s.update_date,
            s.data_last_update
           FROM glossary,
            ((s
             LEFT JOIN pgmetadata.theme gtheme ON ((gtheme.code = s.theme)))
             LEFT JOIN public.spatial_ref_sys rs ON ((concat(rs.auth_name, ':', rs.auth_srid) = s.projection_authid)))
        )
 SELECT ss.id,
    ss.uid,
    ss.table_name,
    ss.schema_name,
    ss.title,
    ss.abstract,
    string_agg(DISTINCT ss.cat, ', '::text ORDER BY ss.cat) AS categories,
    string_agg(DISTINCT ss.theme, ', '::text ORDER BY ss.theme) AS themes,
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
    ss.update_date,
    ss.data_last_update
   FROM ss
  GROUP BY ss.id, ss.uid, ss.table_name, ss.schema_name, ss.title, ss.abstract, ss.keywords, ss.spatial_level, ss.minimum_optimal_scale, ss.maximum_optimal_scale, ss.publication_date, ss.publication_frequency, ss.license, ss.confidentiality, ss.feature_count, ss.geometry_type, ss.projection_name, ss.projection_authid, ss.spatial_extent, ss.creation_date, ss.update_date, ss.data_last_update;


-- VIEW v_dataset
COMMENT ON VIEW pgmetadata.v_dataset IS 'Formatted version of dataset data, with all the codes replaced by corresponding labels taken from pgmetadata.glossary. Used in the function in charge of building the HTML metadata content.';


-- v_dataset_as_dcat
CREATE VIEW pgmetadata.v_dataset_as_dcat AS
 WITH glossary AS (
         SELECT COALESCE(current_setting('pgmetadata.locale'::text, true), 'en'::text) AS locale,
            v_glossary.dict
           FROM pgmetadata.v_glossary
        )
 SELECT d.schema_name,
    d.table_name,
    d.uid,
    XMLELEMENT(NAME "dcat:dataset", XMLELEMENT(NAME "dcat:Dataset", XMLFOREST(d.uid AS "dct:identifier", d.title AS "dct:title", d.abstract AS "dct:description", COALESCE(current_setting('pgmetadata.locale'::text, true), 'en'::text) AS "dct:language", ((((glossary.dict -> 'dataset.license'::text) -> d.license) -> 'label'::text) ->> glossary.locale) AS "dct:license", ((((glossary.dict -> 'dataset.confidentiality'::text) -> d.confidentiality) -> 'label'::text) ->> glossary.locale) AS "dct:rights", ((((glossary.dict -> 'dataset.publication_frequency'::text) -> d.publication_frequency) -> 'label'::text) ->> glossary.locale) AS "dct:accrualPeriodicity", public.st_asgeojson(d.geom) AS "dct:spatial"), XMLELEMENT(NAME "dct:created", XMLATTRIBUTES('http://www.w3.org/2001/XMLSchema#dateTime' AS "rdf:datatype"), d.creation_date), XMLELEMENT(NAME "dct:issued", XMLATTRIBUTES('http://www.w3.org/2001/XMLSchema#dateTime' AS "rdf:datatype"), d.publication_date), XMLELEMENT(NAME "dct:modified", XMLATTRIBUTES('http://www.w3.org/2001/XMLSchema#dateTime' AS "rdf:datatype"), d.update_date), ( SELECT xmlagg(XMLCONCAT(XMLELEMENT(NAME "dcat:contactPoint", XMLELEMENT(NAME "vcard:Organization", XMLELEMENT(NAME "vcard:fn", btrim(concat(c.name, ' - ', c.organisation_name, ((' ('::text || c.organisation_unit) || ')'::text)))), XMLELEMENT(NAME "vcard:hasEmail", XMLATTRIBUTES(c.email AS "rdf:resource"), c.email))), XMLELEMENT(NAME "dct:creator", XMLELEMENT(NAME "foaf:Organization", XMLELEMENT(NAME "foaf:name", btrim(concat(c.name, ' - ', c.organisation_name, ((' ('::text || c.organisation_unit) || ')'::text)))), XMLELEMENT(NAME "foaf:mbox", c.email))))) AS xmlagg
           FROM (pgmetadata.contact c
             JOIN pgmetadata.dataset_contact dc ON (((dc.contact_role = 'OW'::text) AND (dc.fk_id_dataset = d.id) AND (dc.fk_id_contact = c.id))))), ( SELECT xmlagg(XMLELEMENT(NAME "dct:publisher", XMLELEMENT(NAME "foaf:Organization", XMLELEMENT(NAME "foaf:name", btrim(concat(c.name, ' - ', c.organisation_name, ((' ('::text || c.organisation_unit) || ')'::text)))), XMLELEMENT(NAME "foaf:mbox", c.email)))) AS xmlagg
           FROM (pgmetadata.contact c
             JOIN pgmetadata.dataset_contact dc ON (((dc.contact_role = 'DI'::text) AND (dc.fk_id_dataset = d.id) AND (dc.fk_id_contact = c.id))))), ( SELECT xmlagg(XMLELEMENT(NAME "dcat:distribution", XMLELEMENT(NAME "dcat:Distribution", XMLFOREST(l.name AS "dct:title", l.description AS "dct:description", l.url AS "dcat:downloadURL", ((((glossary.dict -> 'link.mime'::text) -> l.mime) -> 'label'::text) ->> glossary.locale) AS "dcat:mediaType", COALESCE(l.format, ((((glossary.dict -> 'link.type'::text) -> l.type) -> 'label'::text) ->> glossary.locale)) AS "dct:format", l.size AS "dct:bytesize")))) AS xmlagg
           FROM pgmetadata.link l
          WHERE (l.fk_id_dataset = d.id)), ( SELECT xmlagg(XMLELEMENT(NAME "dcat:keyword", btrim(kw.kw))) AS xmlagg
           FROM unnest(regexp_split_to_array(d.keywords, ','::text)) kw(kw)), ( SELECT xmlagg(XMLELEMENT(NAME "dcat:theme", th.label)) AS xmlagg
           FROM pgmetadata.theme th,
            unnest(d.themes) cat(cat)
          WHERE (th.code = cat.cat)), ( SELECT xmlagg(XMLELEMENT(NAME "dcat:theme", ((((glossary.dict -> 'dataset.categories'::text) -> cat.cat) -> 'label'::text) ->> glossary.locale))) AS xmlagg
           FROM unnest(d.categories) cat(cat)))) AS dataset
   FROM glossary,
    pgmetadata.dataset d;


-- VIEW v_dataset_as_dcat
COMMENT ON VIEW pgmetadata.v_dataset_as_dcat IS 'DCAT - View which formats the datasets AS DCAT XML record objects';


-- v_link
CREATE VIEW pgmetadata.v_link AS
 WITH glossary AS (
         SELECT COALESCE(current_setting('pgmetadata.locale'::text, true), 'en'::text) AS locale,
            v_glossary.dict
           FROM pgmetadata.v_glossary
        )
 SELECT l.id,
    d.table_name,
    d.schema_name,
    l.name,
    l.type,
    ((((glossary.dict -> 'link.type'::text) -> l.type) -> 'label'::text) ->> glossary.locale) AS type_label,
    l.url,
    l.description,
    l.format,
    l.mime,
    ((((glossary.dict -> 'link.mime'::text) -> l.mime) -> 'label'::text) ->> glossary.locale) AS mime_label,
    l.size
   FROM glossary,
    (pgmetadata.link l
     JOIN pgmetadata.dataset d ON ((d.id = l.fk_id_dataset)))
  WHERE true
  ORDER BY l.id;


-- VIEW v_link
COMMENT ON VIEW pgmetadata.v_link IS 'Formatted version of link data, with all the codes replaced by corresponding labels taken from pgmetadata.glossary. Used in the function in charge of building the HTML metadata content.';


-- v_locales
CREATE VIEW pgmetadata.v_locales AS
 SELECT 'en'::text AS locale
UNION
 SELECT replace((columns.column_name)::text, 'label_'::text, ''::text) AS locale
   FROM information_schema.columns
  WHERE (((columns.table_schema)::text = 'pgmetadata'::text) AND ((columns.table_name)::text = 'glossary'::text) AND ((columns.column_name)::text ~~ 'label_%'::text))
  ORDER BY 1;


-- VIEW v_locales
COMMENT ON VIEW pgmetadata.v_locales IS 'Lists the locales available in the glossary, by listing the columns label_xx of the table pgmetadata.glossary';


-- v_orphan_dataset_items
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


-- v_valid_dataset
CREATE VIEW pgmetadata.v_valid_dataset AS
 SELECT d.schema_name,
    d.table_name
   FROM (pgmetadata.dataset d
     LEFT JOIN pg_tables t ON (((d.schema_name = (t.schemaname)::text) AND (d.table_name = (t.tablename)::text))))
  WHERE (t.tablename IS NOT NULL)
  ORDER BY d.schema_name, d.table_name;


-- VIEW v_valid_dataset
COMMENT ON VIEW pgmetadata.v_valid_dataset IS 'Gives a list of lines from pgmetadata.dataset with corresponding (existing) tables.';


--
-- PostgreSQL database dump complete
--

