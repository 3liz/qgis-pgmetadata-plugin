BEGIN;

-- Add primary key constraint
-- upgrade_to_0.2.3.sql do the job, but not tag exists with this value...
ALTER TABLE ONLY pgmetadata.theme
    DROP CONSTRAINT IF EXISTS theme_pkey;
ALTER TABLE ONLY pgmetadata.theme
    ADD CONSTRAINT theme_pkey PRIMARY KEY (id);

-- Add french columns for label and description in glossary
ALTER TABLE pgmetadata.glossary ADD COLUMN IF NOT EXISTS label_fr text;
ALTER TABLE pgmetadata.glossary ADD COLUMN IF NOT EXISTS description_fr text;
ALTER TABLE pgmetadata.glossary ADD COLUMN IF NOT EXISTS label_it text;
ALTER TABLE pgmetadata.glossary ADD COLUMN IF NOT EXISTS description_it text;
ALTER TABLE pgmetadata.glossary ADD COLUMN IF NOT EXISTS label_es text;
ALTER TABLE pgmetadata.glossary ADD COLUMN IF NOT EXISTS description_es text;
ALTER TABLE pgmetadata.glossary ADD COLUMN IF NOT EXISTS label_de text;
ALTER TABLE pgmetadata.glossary ADD COLUMN IF NOT EXISTS description_de text;

CREATE TABLE pgmetadata.t_glossary (code text, label_fr text, description_fr text);
INSERT INTO pgmetadata.t_glossary (code, label_fr, description_fr)
VALUES
('CU', 'Dépositaire', NULL),
('DI', 'Distributeur', NULL),
('OW', 'Propriétaire', NULL),
('HEA', 'Santé', NULL),
('ELE', 'Altitude', NULL),
('GEO', 'Informations géoscientifiques', NULL),
('PLA', 'Planification/Cadastre', NULL),
('INL', 'Eaux intérieures', NULL),
('BOU', 'Limites', NULL),
('STR', 'Structure', NULL),
('TRA', 'Transport', NULL),
('INT', 'Renseignement/Secteur militaire', NULL),
('LOC', 'Localisation', NULL),
('CLI', 'Climatologie/Météorologie/Atmosphère', NULL),
('FAR', 'Agriculture', NULL),
('ENV', 'Environnement', NULL),
('OCE', 'Océans', NULL),
('BIO', 'Biote', NULL),
('IMA', 'Imagerie/Cartes de base/Occupation des terres', NULL),
('SOC', 'Société', NULL),
('ECO', 'Économie', NULL),
('UTI', 'Services d’utilité publique/Communication', NULL),

('OPE', 'Ouvert', 'Aucune restriction d''accès pour ce jeu de données'),
('RES', 'Restreint', 'L''accès au jeu de données est restreint à certains utilisateurs'),

('DAY', 'Journalier', 'Mise à jour journalière'),
('MON', 'Mensuel', 'Mise à jour mensuelle'),
('YEA', 'Annuel', 'Mise à jour annuelle'),
('NEC', 'Lorsque nécessaire', 'Mise à jour lorsque nécessaire'),
('WEE', 'Hebdomadaire', 'Mise à jour hebdomadaire')

ON CONFLICT DO NOTHING
;


-- UPDATE glossary
UPDATE pgmetadata.glossary AS g
SET (label_fr, description_fr)
= (t.label_fr, t.description_fr)
FROM pgmetadata.t_glossary AS t
WHERE g.code = t.code
;

DROP TABLE pgmetadata.t_glossary;


-- Create view helping to localize glossary labels and descriptions
CREATE OR REPLACE VIEW pgmetadata.v_glossary AS
WITH one AS (
    SELECT
    field,
    code,
    json_build_object(
        'label',
        json_build_object(
            'en', label,
            'fr', Coalesce(Nullif(label_fr, ''), label, ''),
            'it', Coalesce(Nullif(label_it, ''), label, ''),
            'es', Coalesce(Nullif(label_es, ''), label, ''),
            'de', Coalesce(Nullif(label_de, ''), label, '')
        ),
        'description',
        json_build_object(
            'en', description,
            'fr', Coalesce(Nullif(description_fr, ''), description, ''),
            'it', Coalesce(Nullif(description_it, ''), description, ''),
            'es', Coalesce(Nullif(description_es, ''), description, ''),
            'de', Coalesce(Nullif(description_de, ''), description, '')
        )
    ) AS dict
    FROM pgmetadata.glossary
),
two AS (
    SELECT field,
    json_object_agg(code, dict) AS dict
    FROM one
    GROUP BY field
)
SELECT json_object_agg(field, dict) AS dict
FROM two
;

COMMENT ON VIEW pgmetadata.v_glossary
IS 'View transforming the glossary content into a JSON helping to localize a label or description by fetching directly the corresponding item. Ex: SET SESSION "pgmetadata.locale" = ''fr''; WITH glossary AS (SELECT dict FROM pgmetadata.v_glossary) SELECT (dict->''contact.contact_role''->''OW''->''label''->''fr'')::text AS label FROM glossary;'
;

-- Modify views to use this new item
CREATE OR REPLACE VIEW pgmetadata.v_contact AS
WITH glossary AS (
    SELECT
        Coalesce(current_setting('pgmetadata.locale', true), 'en') AS locale,
        dict
    FROM pgmetadata.v_glossary
)
SELECT
    d.table_name,
    d.schema_name,
    c.name,
    c.organisation_name,
    c.organisation_unit,
    (dict->'contact.contact_role'->(dc.contact_role)->'label'->>locale)::text AS contact_role,
    c.email
FROM glossary, pgmetadata.dataset_contact dc
JOIN pgmetadata.dataset d ON d.id = dc.fk_id_dataset
JOIN pgmetadata.contact c ON dc.fk_id_contact = c.id
WHERE true
ORDER BY dc.id
;

COMMENT ON VIEW pgmetadata.v_contact IS 'Formatted version of contact data, with all the codes replaced by corresponding labels taken from pgmetadata.glossary. Used in the function in charge of building the HTML metadata content. The localized version of labels and descriptions are taken considering the session setting ''pgmetadata.locale''. For example with: SET SESSION "pgmetadata.locale" = ''fr''; ';


CREATE OR REPLACE VIEW pgmetadata.v_dataset AS
WITH glossary AS (
    SELECT
        Coalesce(current_setting('pgmetadata.locale', true), 'en') AS locale,
        dict
    FROM pgmetadata.v_glossary
),
s AS (
    SELECT
        d.id,
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
        d.geom,
        cat.cat,
        theme.theme
    FROM ((pgmetadata.dataset d
    LEFT JOIN LATERAL unnest(d.categories) cat(cat) ON (true))
    LEFT JOIN LATERAL unnest(d.themes) theme(theme) ON (true))
    WHERE true
    ORDER BY d.id
), ss AS (
    SELECT
        s.id,
        s.uid,
        s.table_name,
        s.schema_name,
        s.title,
        s.abstract,
        (dict->'dataset.categories'->(s.cat)->'label'->>locale)::text AS cat,
        gtheme.label AS theme,
        s.keywords,
        s.spatial_level,
        ('1/'::text || s.minimum_optimal_scale) AS minimum_optimal_scale,
        ('1/'::text || s.maximum_optimal_scale) AS maximum_optimal_scale,
        s.publication_date,
        (dict->'dataset.publication_frequency'->(s.publication_frequency)->'label'->>locale)::text AS publication_frequency,
        (dict->'dataset.license'->(s.license)->'label'->>locale)::text AS license,
        (dict->'dataset.confidentiality'->(s.confidentiality)->'label'->>locale)::text AS confidentiality,
        s.feature_count,
        s.geometry_type,
        (regexp_split_to_array((rs.srtext)::text, '"'::text))[2] AS projection_name,
        s.projection_authid,
        s.spatial_extent,
        s.creation_date,
        s.update_date
    FROM glossary, s
    LEFT JOIN pgmetadata.theme gtheme ON gtheme.code = s.theme
    LEFT JOIN public.spatial_ref_sys rs ON concat(rs.auth_name, ':', rs.auth_srid) = s.projection_authid
)
SELECT
    ss.id,
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
    ss.update_date
FROM ss
GROUP BY ss.id, ss.uid, ss.table_name, ss.schema_name, ss.title, ss.abstract, ss.keywords, ss.spatial_level, ss.minimum_optimal_scale, ss.maximum_optimal_scale, ss.publication_date, ss.publication_frequency, ss.license, ss.confidentiality, ss.feature_count, ss.geometry_type, ss.projection_name, ss.projection_authid, ss.spatial_extent, ss.creation_date, ss.update_date;

CREATE OR REPLACE VIEW pgmetadata.v_link AS
WITH glossary AS (
    SELECT
        Coalesce(current_setting('pgmetadata.locale', true), 'en') AS locale,
        dict
    FROM pgmetadata.v_glossary
)
SELECT
    l.id,
    d.table_name,
    d.schema_name,
    l.name,
    l.type,
    (dict->'link.type'->(l.type)->'label'->>locale)::text AS type_label,
    l.url,
    l.description,
    l.format,
    l.mime,
    (dict->'link.mime'->(l.mime)->'label'->>locale)::text AS mime_label,
    l.size
FROM glossary, pgmetadata.link l
JOIN pgmetadata.dataset d ON d.id = l.fk_id_dataset
WHERE true
ORDER BY l.id;

-- HTML function
CREATE OR REPLACE FUNCTION pgmetadata.get_dataset_item_html_content(_table_schema text, _table_name text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    html text;
BEGIN
    -- Call the new function with locale set to en
    SELECT pgmetadata.get_dataset_item_html_content(_table_schema, _table_name, 'en')
    INTO html;

    RETURN html;

END;
$$;

COMMENT ON FUNCTION pgmetadata.get_dataset_item_html_content(_table_schema text, _table_name text)
IS 'Backward compatibility function calling pgmetadata.get_dataset_item_html_content(_table_schema text, _table_name text, _locale text)'
;

-- View to get available locales
CREATE OR REPLACE VIEW pgmetadata.v_locales AS
SELECT 'en' AS locale
UNION
SELECT replace(column_name, 'label_', '') AS locale
FROM information_schema.columns
WHERE table_schema = 'pgmetadata'
AND table_name   = 'glossary'
AND column_name LIKE 'label_%'
ORDER BY locale;

COMMENT ON VIEW pgmetadata.v_locales
IS 'Lists the locales available in the glossary, by listing the columns label_xx of the table pgmetadata.glossary';


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


COMMENT ON FUNCTION pgmetadata.get_dataset_item_html_content(_table_schema text, _table_name text) IS
'Generate the metadata HTML content in English for the given table or NULL if no templates are stored in the pgmetadata.html_template table.';

COMMENT ON FUNCTION pgmetadata.get_dataset_item_html_content(_table_schema text, _table_name text, _locale text) IS
 'Generate the metadata HTML content for the given table and given language or NULL if no templates are stored in the pgmetadata.html_template table.';

COMMIT;
