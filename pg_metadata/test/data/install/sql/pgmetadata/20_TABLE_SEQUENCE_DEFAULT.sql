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

SET default_tablespace = '';

-- contact
CREATE TABLE pgmetadata.contact (
    id integer NOT NULL,
    name text NOT NULL,
    organisation_name text NOT NULL,
    organisation_unit text,
    email text
);


-- contact
COMMENT ON TABLE pgmetadata.contact IS 'List of contacts related to the published datasets.';


-- contact_id_seq
CREATE SEQUENCE pgmetadata.contact_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


-- contact_id_seq
ALTER SEQUENCE pgmetadata.contact_id_seq OWNED BY pgmetadata.contact.id;


-- dataset
CREATE TABLE pgmetadata.dataset (
    id integer NOT NULL,
    uid uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    table_name text NOT NULL,
    schema_name text NOT NULL,
    title text NOT NULL,
    abstract text NOT NULL,
    categories text[],
    keywords text[],
    spatial_level text,
    minimum_optimal_scale integer,
    maximum_optimal_scale integer,
    publication_date timestamp without time zone DEFAULT now(),
    publication_frequency text,
    license text,
    confidentiality text,
    feature_count integer,
    geometry_type text,
    projection_name text,
    projection_authid text,
    spatial_extent text,
    creation_date timestamp without time zone DEFAULT now() NOT NULL,
    update_date timestamp without time zone DEFAULT now(),
    geom public.geometry(Polygon,4326)
);


-- dataset
COMMENT ON TABLE pgmetadata.dataset IS 'Main table for storing dataset about PostgreSQL vector layers.';


-- dataset_contact
CREATE TABLE pgmetadata.dataset_contact (
    id integer NOT NULL,
    fk_id_contact integer NOT NULL,
    fk_id_dataset integer NOT NULL,
    contact_role text NOT NULL
);


-- dataset_contact
COMMENT ON TABLE pgmetadata.dataset_contact IS 'Pivot table between dataset and contacts.';


-- dataset_contact_id_seq
CREATE SEQUENCE pgmetadata.dataset_contact_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


-- dataset_contact_id_seq
ALTER SEQUENCE pgmetadata.dataset_contact_id_seq OWNED BY pgmetadata.dataset_contact.id;


-- dataset_id_seq
CREATE SEQUENCE pgmetadata.dataset_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


-- dataset_id_seq
ALTER SEQUENCE pgmetadata.dataset_id_seq OWNED BY pgmetadata.dataset.id;


-- glossary
CREATE TABLE pgmetadata.glossary (
    id integer NOT NULL,
    field text NOT NULL,
    code text NOT NULL,
    label text NOT NULL,
    description text,
    item_order smallint
);


-- glossary
COMMENT ON TABLE pgmetadata.glossary IS 'List of labels and words used as labels for stored data';


-- glossary_id_seq
CREATE SEQUENCE pgmetadata.glossary_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


-- glossary_id_seq
ALTER SEQUENCE pgmetadata.glossary_id_seq OWNED BY pgmetadata.glossary.id;


-- html_template
CREATE TABLE pgmetadata.html_template (
    id integer NOT NULL,
    section text NOT NULL,
    content text,
    CONSTRAINT html_template_section_check CHECK ((section = ANY (ARRAY['main'::text, 'contacts'::text, 'links'::text])))
);


-- html_template
COMMENT ON TABLE pgmetadata.html_template IS 'This table contains the HTML templates for the main metadata sheet, and one for the contacts and links. Contacts and links templates are used to compute a unique contact or link HTML representation.';


-- html_template_id_seq
CREATE SEQUENCE pgmetadata.html_template_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


-- html_template_id_seq
ALTER SEQUENCE pgmetadata.html_template_id_seq OWNED BY pgmetadata.html_template.id;


-- link
CREATE TABLE pgmetadata.link (
    id integer NOT NULL,
    name text NOT NULL,
    type text NOT NULL,
    url text NOT NULL,
    description text,
    format text,
    mime text,
    size integer,
    fk_id_dataset integer NOT NULL
);


-- link
COMMENT ON TABLE pgmetadata.link IS 'List of links related to the published datasets.';


-- link_id_seq
CREATE SEQUENCE pgmetadata.link_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


-- link_id_seq
ALTER SEQUENCE pgmetadata.link_id_seq OWNED BY pgmetadata.link.id;


-- qgis_plugin
CREATE TABLE pgmetadata.qgis_plugin (
    id integer NOT NULL,
    version text NOT NULL,
    version_date date NOT NULL,
    status smallint NOT NULL
);


-- qgis_plugin
COMMENT ON TABLE pgmetadata.qgis_plugin IS 'Version and date of the database structure. Useful for database structure and glossary data migrations between the plugin versions by the QGIS plugin pg_metadata';


-- contact id
ALTER TABLE ONLY pgmetadata.contact ALTER COLUMN id SET DEFAULT nextval('pgmetadata.contact_id_seq'::regclass);


-- dataset id
ALTER TABLE ONLY pgmetadata.dataset ALTER COLUMN id SET DEFAULT nextval('pgmetadata.dataset_id_seq'::regclass);


-- dataset_contact id
ALTER TABLE ONLY pgmetadata.dataset_contact ALTER COLUMN id SET DEFAULT nextval('pgmetadata.dataset_contact_id_seq'::regclass);


-- glossary id
ALTER TABLE ONLY pgmetadata.glossary ALTER COLUMN id SET DEFAULT nextval('pgmetadata.glossary_id_seq'::regclass);


-- html_template id
ALTER TABLE ONLY pgmetadata.html_template ALTER COLUMN id SET DEFAULT nextval('pgmetadata.html_template_id_seq'::regclass);


-- link id
ALTER TABLE ONLY pgmetadata.link ALTER COLUMN id SET DEFAULT nextval('pgmetadata.link_id_seq'::regclass);


--
-- PostgreSQL database dump complete
--

