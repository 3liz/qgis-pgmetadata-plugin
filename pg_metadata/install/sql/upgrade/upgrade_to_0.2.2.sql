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
ALTER TABLE pgmetadata.dataset ADD COLUMN theme text[];


-- dataset.theme
COMMENT ON COLUMN pgmetadata.dataset.theme IS 'List of themes';
