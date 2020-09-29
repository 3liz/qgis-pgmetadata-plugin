--
-- PostgreSQL database dump
--

-- Dumped from database version 10.14 (Debian 10.14-1.pgdg100+1)
-- Dumped by pg_dump version 10.14 (Debian 10.14-1.pgdg100+1)

SET statement_timeout = 0;
SET lock_timeout = 0;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

-- contact contact_pkey
ALTER TABLE ONLY pgmetadata.contact
    ADD CONSTRAINT contact_pkey PRIMARY KEY (id);


-- dataset_contact dataset_contact_fk_id_contact_fk_id_dataset_contact_role_key
ALTER TABLE ONLY pgmetadata.dataset_contact
    ADD CONSTRAINT dataset_contact_fk_id_contact_fk_id_dataset_contact_role_key UNIQUE (fk_id_contact, fk_id_dataset, contact_role);


-- dataset_contact dataset_contact_pkey
ALTER TABLE ONLY pgmetadata.dataset_contact
    ADD CONSTRAINT dataset_contact_pkey PRIMARY KEY (id);


-- dataset dataset_pkey
ALTER TABLE ONLY pgmetadata.dataset
    ADD CONSTRAINT dataset_pkey PRIMARY KEY (id);


-- dataset dataset_uid_key
ALTER TABLE ONLY pgmetadata.dataset
    ADD CONSTRAINT dataset_uid_key UNIQUE (uid);


-- link link_pkey
ALTER TABLE ONLY pgmetadata.link
    ADD CONSTRAINT link_pkey PRIMARY KEY (id);


-- dataset_contact dataset_contact_fk_id_contact_fkey
ALTER TABLE ONLY pgmetadata.dataset_contact
    ADD CONSTRAINT dataset_contact_fk_id_contact_fkey FOREIGN KEY (fk_id_contact) REFERENCES pgmetadata.contact(id) ON DELETE RESTRICT;


-- dataset_contact dataset_contact_fk_id_dataset_fkey
ALTER TABLE ONLY pgmetadata.dataset_contact
    ADD CONSTRAINT dataset_contact_fk_id_dataset_fkey FOREIGN KEY (fk_id_dataset) REFERENCES pgmetadata.dataset(id) ON DELETE CASCADE;


-- link link_fk_id_dataset_fkey
ALTER TABLE ONLY pgmetadata.link
    ADD CONSTRAINT link_fk_id_dataset_fkey FOREIGN KEY (fk_id_dataset) REFERENCES pgmetadata.dataset(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

