BEGIN;

-- Add licence in DCAT distributions
CREATE OR REPLACE VIEW pgmetadata.v_dataset_as_dcat AS
WITH glossary AS (
    SELECT
        Coalesce(current_setting('pgmetadata.locale', true), 'en') AS locale,
        dict
    FROM pgmetadata.v_glossary
)
SELECT
d.schema_name, d.table_name, d.uid,
xmlelement(
name "dcat:dataset",
    xmlelement(
        name "dcat:Dataset",
        xmlforest(
            uid AS "dct:identifier",
            title AS "dct:title",
            abstract AS "dct:description",
            Coalesce(current_setting('pgmetadata.locale', true), 'en') AS "dct:language",
            (dict->'dataset.license'->(license)->'label'->>locale)::text AS "dct:license",
            (dict->'dataset.confidentiality'->(confidentiality)->'label'->>locale)::text AS "dct:rights",
            (dict->'dataset.publication_frequency'->(publication_frequency)->'label'->>locale)::text AS "dct:accrualPeriodicity",
            ST_AsGeoJSON(geom) AS "dct:spatial"
        ),

        -- Dates
        xmlelement(
            name "dct:created",
            xmlattributes('http://www.w3.org/2001/XMLSchema#dateTime'    AS "rdf:datatype"),
            creation_date
        ),
        xmlelement(
            name "dct:issued",
            xmlattributes('http://www.w3.org/2001/XMLSchema#dateTime'    AS "rdf:datatype"),
            publication_date
        ),
        xmlelement(
            name "dct:modified",
            xmlattributes('http://www.w3.org/2001/XMLSchema#dateTime' AS "rdf:datatype"),
            update_date
        ),
        -- Creators
        (
            SELECT
            xmlagg(
                xmlconcat(
                    xmlelement(
                        name "dcat:contactPoint",
                        xmlelement(
                            name "vcard:Organization",
                            -- xmlattributes(md5(concat(c.organisation_name, c.organisation_unit)) AS "rdf:nodeID"),
                            xmlelement(
                                name "vcard:fn",
                                trim(Concat( c.name, ' - ',
                                    c.organisation_name,
                                    ' (' || c.organisation_unit || ')'
                                ))

                            ),
                            xmlelement(
                                name "vcard:hasEmail",
                                xmlattributes(c.email AS "rdf:resource"),
                                c.email
                            )
                        )
                    ),

                    xmlelement(
                        name "dct:creator",
                        xmlelement(
                            name "foaf:Organization",
                            xmlelement(
                                name "foaf:name",
                                trim(Concat( c.name, ' - ',
                                    c.organisation_name,
                                    ' (' || c.organisation_unit || ')'
                                ))
                            ),
                            xmlelement(
                                name "foaf:mbox",
                                c.email
                            )
                        )
                    )
                )
            )
            FROM pgmetadata.contact AS c
            JOIN pgmetadata.dataset_contact AS dc
                ON dc.contact_role = 'OW'
                AND dc.fk_id_dataset = d.id
                AND dc.fk_id_contact = c.id
        ),

        -- Publisher
        (
            SELECT
            xmlagg(
                xmlelement(
                    name "dct:publisher",
                    xmlelement(
                        name "foaf:Organization",
                        xmlelement(
                            name "foaf:name",
                            trim(Concat( c.name, ' - ',
                                c.organisation_name,
                                ' (' || c.organisation_unit || ')'
                            ))
                        ),
                        xmlelement(
                            name "foaf:mbox",
                            c.email
                        )
                    )
                )
            )
            FROM pgmetadata.contact AS c
            JOIN pgmetadata.dataset_contact AS dc
                ON dc.contact_role = 'DI'
                AND dc.fk_id_dataset = d.id
                AND dc.fk_id_contact = c.id
        )
        ,

        -- Links
        (
            SELECT
            xmlagg(
                xmlelement(
                    name "dcat:distribution",
                    xmlelement(
                        name "dcat:Distribution",
                        xmlforest(
                            l.name AS "dct:title",
                            l.description AS "dct:description",
                            l.url AS "dcat:downloadURL",
                            (dict->'link.mime'->(l.mime)->'label'->>locale)::text AS "dcat:mediaType",
                            coalesce(
                                l.format,
                                (dict->'link.type'->(l.type)->'label'->>locale)::text
                            ) AS "dct:format",
                            l.size AS "dct:bytesize",
                            (dict->'dataset.license'->(license)->'label'->>locale)::text AS "dct:license"
                        )
                    )
                )

            )
            FROM pgmetadata.link AS l
            WHERE l.fk_id_dataset = d.id
        ),

        -- keywords
        (
            SELECT
            xmlagg(
                xmlelement(
                    name "dcat:keyword",
                    trim(kw.kw)::text
                )
            )
            FROM unnest(regexp_split_to_array(d.keywords, ',')) AS kw
        ),

        -- themes
        (
            SELECT
            xmlagg(
                xmlelement(
                    name "dcat:theme",
                    th.label
                )
            )
            FROM pgmetadata.theme AS th, unnest(d.themes) AS cat
            WHERE th.code = cat.cat
        ),

        -- categories: into themes
        (
            SELECT
            xmlagg(
                xmlelement(
                    name "dcat:theme",
                    (dict->'dataset.categories'->(cat.cat)->'label'->>locale)::text
                )
            )
            FROM unnest(d.categories) AS cat
        )

    )
) AS dataset
FROM glossary, pgmetadata.dataset AS d
;

COMMENT ON VIEW pgmetadata.v_dataset_as_dcat
IS 'DCAT - View which formats the datasets AS DCAT XML record objects'
;


-- Improve performance of dcat export by filtering sooner
DROP FUNCTION IF EXISTS pgmetadata.get_datasets_as_dcat_xml(_locale text);
CREATE OR REPLACE FUNCTION pgmetadata.get_datasets_as_dcat_xml(_locale text, uids uuid[])
RETURNS TABLE(schema_name text, table_name text, uid uuid, dataset xml)
    LANGUAGE plpgsql
    AS $$
DECLARE
    locale_exists boolean;
    sql_text text;
BEGIN

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

    -- Return content
    IF uids IS NOT NULL THEN
        RETURN QUERY
        SELECT
        *
        FROM pgmetadata.v_dataset_as_dcat AS d
        WHERE d.uid = ANY (uids)
        ;
    ELSE
        RETURN QUERY
        SELECT
        *
        FROM pgmetadata.v_dataset_as_dcat AS d
        ;
    END IF;

END;
$$;


-- FUNCTION get_datasets_as_dcat_xml(_locale text)
COMMENT ON FUNCTION pgmetadata.get_datasets_as_dcat_xml(_locale text, uids uuid[])
IS 'Get the datasets records as XML DCAT datasets for the given locale. Datasets are filtered by the given array of uids. IF uids is NULL, no filter is used and all datasets are returned';

CREATE FUNCTION pgmetadata.get_datasets_as_dcat_xml(_locale text)
RETURNS TABLE(schema_name text, table_name text, uid uuid, dataset xml)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Call the new function
    RETURN QUERY
    SELECT
    *
    FROM pgmetadata.get_datasets_as_dcat_xml(
        _locale,
        -- passing NULL means no filter
        NULL
    )
    ;

END;
$$;

COMMENT ON FUNCTION pgmetadata.get_datasets_as_dcat_xml(_locale text)
IS 'Get the datasets records as XML DCAT datasets for the given locale. All datasets are returned';


-- View flat export for Excel, LibreOffice calc
DROP VIEW IF EXISTS pgmetadata.v_export_table;
CREATE OR REPLACE VIEW pgmetadata.v_export_table AS
SELECT
d.uid, d.table_name, d.schema_name, d.title, d.abstract,
d.categories, d.themes, d.keywords,
d.spatial_level, d.minimum_optimal_scale, d.maximum_optimal_scale,
d.publication_date, d.publication_frequency,
d.license, d.confidentiality,
d.feature_count, d.geometry_type, d.projection_name, d.projection_authid, d.spatial_extent,
d.creation_date, d.update_date, d.data_last_update,
-- links
string_agg(
    l.name || ': ' || l.url,
    ', '
) AS links,
-- contacts
string_agg(
    c.name || ' (' || organisation_name || ')' || ' - ' || c.contact_role,
    ', '
) AS contacts

FROM pgmetadata.v_dataset AS d
LEFT JOIN pgmetadata.v_link AS l
    ON l.table_name = d.table_name AND l.schema_name = d.schema_name
LEFT JOIN pgmetadata.v_contact AS c
    ON c.table_name = d.table_name AND c.schema_name = d.schema_name
GROUP BY
d.uid, d.table_name, d.schema_name, d.title, d.abstract,
d.categories, d.themes, d.keywords,
d.spatial_level, d.minimum_optimal_scale, d.maximum_optimal_scale,
d.publication_date, d.publication_frequency,
d.license, d.confidentiality,
d.feature_count, d.geometry_type, d.projection_name, d.projection_authid, d.spatial_extent,
d.creation_date, d.update_date, d.data_last_update
ORDER BY d.schema_name, d.table_name
;

COMMENT ON VIEW pgmetadata.v_export_table
IS 'Generate a flat representation of the datasets. Links and contacts are grouped in one column each';


-- Use a function to get the data in the correct locale
DROP FUNCTION IF EXISTS pgmetadata.export_datasets_as_flat_table(_locale text);
CREATE OR REPLACE FUNCTION pgmetadata.export_datasets_as_flat_table(_locale text) RETURNS TABLE(
    uid uuid, table_name text, schema_name text,
    title text, abstract text,
    categories text, themes text, keywords text,
    spatial_level text, minimum_optimal_scale text, maximum_optimal_scale text,
    publication_date timestamp without time zone, publication_frequency text,
    license text, confidentiality text,
    feature_count integer, geometry_type text, projection_name text, projection_authid text, spatial_extent text,
    creation_date timestamp without time zone, update_date timestamp without time zone,
    data_last_update timestamp without time zone,
    links text, contacts text
)
    LANGUAGE plpgsql
    AS $$
DECLARE
    locale_exists boolean;
    sql_text text;
BEGIN

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

    -- Return content
    RETURN QUERY
    SELECT
    *
    FROM pgmetadata.v_export_table
    ;

END;
$$;


-- FUNCTION get_datasets_as_dcat_xml(_locale text)
COMMENT ON FUNCTION pgmetadata.export_datasets_as_flat_table(_locale text)
IS 'Generate a flat representation of the datasets for a given locale.';


COMMIT;
