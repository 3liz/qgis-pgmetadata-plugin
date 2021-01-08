BEGIN;

DROP VIEW IF EXISTS pgmetadata.v_dataset_as_dcat;
CREATE VIEW pgmetadata.v_dataset_as_dcat AS
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
                            l.size AS "dct:bytesize"
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

CREATE OR REPLACE FUNCTION pgmetadata.get_datasets_as_dcat_xml(_locale text)
RETURNS TABLE (
  table_name text,
  schema_name text,
  uid uuid,
  dataset xml
)
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
    FROM pgmetadata.v_dataset_as_dcat
    ;

END;
$$;


COMMENT ON FUNCTION pgmetadata.get_datasets_as_dcat_xml(_locale text) IS
'Get the datasets records as XML DCAT datasets for the given locale.';

COMMIT;
