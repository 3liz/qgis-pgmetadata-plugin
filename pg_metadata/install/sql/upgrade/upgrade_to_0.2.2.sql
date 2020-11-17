BEGIN;

-- theme
DROP TABLE IF EXISTS pgmetadata.theme;
CREATE TABLE pgmetadata.theme ( 
    id integer NOT NULL, 
    code text unique NOT NULL, 
    label text unique NOT NULL, 
    description text
);

-- theme
COMMENT ON TABLE pgmetadata.theme IS 'List of themes related to the published datasets.';


-- theme_id_seq
CREATE SEQUENCE pgmetadata.theme_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


-- theme_id_seq
ALTER SEQUENCE pgmetadata.theme_id_seq OWNED BY pgmetadata.theme.id;


-- theme id
ALTER TABLE ONLY pgmetadata.theme ALTER COLUMN id SET DEFAULT nextval('pgmetadata.theme_id_seq'::regclass);


-- theme.id
COMMENT ON COLUMN pgmetadata.theme.id IS 'Internal automatic integer ID';


-- theme.code
COMMENT ON COLUMN pgmetadata.theme.code IS 'Code Of the theme';


-- theme.label
COMMENT ON COLUMN pgmetadata.theme.label IS 'Label of the theme';


-- theme.description
COMMENT ON COLUMN pgmetadata.theme.description IS 'Description of the theme';


-- Add field theme in dataset
ALTER TABLE pgmetadata.dataset ADD COLUMN themes text[];


-- dataset.themes
COMMENT ON COLUMN pgmetadata.dataset.themes IS 'List of themes';


-- v_dataset
DROP VIEW IF EXISTS pgmetadata.v_dataset;
CREATE VIEW pgmetadata.v_dataset AS
 WITH s AS (
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
            gcat.label AS cat,
            gtheme.label AS theme,
            s.keywords,
            s.spatial_level,
            ('1/'::text || s.minimum_optimal_scale) AS minimum_optimal_scale,
            ('1/'::text || s.maximum_optimal_scale) AS maximum_optimal_scale,
            s.publication_date,
            gfre.label AS publication_frequency,
            concat(glic.label, ' (', s.license, ')') AS license,
            gcon.label AS confidentiality,
            s.feature_count,
            s.geometry_type,
            (regexp_split_to_array((rs.srtext)::text, '"'::text))[2] AS projection_name,
            s.projection_authid,
            s.spatial_extent,
            s.creation_date,
            s.update_date
           FROM ((((((s
             LEFT JOIN pgmetadata.glossary gcat ON (((gcat.field = 'dataset.categories'::text) AND (gcat.code = s.cat))))
             LEFT JOIN pgmetadata.theme gtheme ON ((gtheme.code = s.theme)))
             LEFT JOIN pgmetadata.glossary gfre ON (((gfre.field = 'dataset.publication_frequency'::text) AND (gfre.code = s.publication_frequency))))
             LEFT JOIN pgmetadata.glossary glic ON (((glic.field = 'dataset.license'::text) AND (glic.code = s.license))))
             LEFT JOIN pgmetadata.glossary gcon ON (((gcon.field = 'dataset.confidentiality'::text) AND (gcon.code = s.confidentiality))))
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
    ss.update_date
   FROM ss
  GROUP BY ss.id, ss.uid, ss.table_name, ss.schema_name, ss.title, ss.abstract, ss.keywords, ss.spatial_level, ss.minimum_optimal_scale, ss.maximum_optimal_scale, ss.publication_date, ss.publication_frequency, ss.license, ss.confidentiality, ss.feature_count, ss.geometry_type, ss.projection_name, ss.projection_authid, ss.spatial_extent, ss.creation_date, ss.update_date;


-- VIEW v_dataset
COMMENT ON VIEW pgmetadata.v_dataset IS 'Formatted version of dataset data, with all the codes replaced by corresponding labels taken from pgmetadata.glossary. Used in the function in charge of building the HTML metadata content.';


COMMIT;
