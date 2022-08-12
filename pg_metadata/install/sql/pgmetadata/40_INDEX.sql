BEGIN;
--
-- PostgreSQL database dump
--

-- Dumped from database version 11.7 (Debian 11.7-2.pgdg100+1)
-- Dumped by pg_dump version 11.7 (Debian 11.7-2.pgdg100+1)

SET statement_timeout = 0;
SET lock_timeout = 0;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

-- dataset_id_idx
CREATE INDEX dataset_id_idx ON pgmetadata.dataset USING btree (id);


-- glossary_id_idx
CREATE INDEX glossary_id_idx ON pgmetadata.glossary USING btree (id);


-- qgis_plugin_id_idx
CREATE INDEX qgis_plugin_id_idx ON pgmetadata.qgis_plugin USING btree (id);


--
-- PostgreSQL database dump complete
--


COMMIT;
