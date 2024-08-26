BEGIN;
--
-- PostgreSQL database dump
--

-- Dumped from database version 13.4 (Debian 13.4-1.pgdg110+1)
-- Dumped by pg_dump version 13.4 (Debian 13.4-1.pgdg110+1)

SET statement_timeout = 0;
SET lock_timeout = 0;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

-- dataset trg_calculate_fields_from_data
CREATE TRIGGER trg_calculate_fields_from_data BEFORE INSERT OR UPDATE ON pgmetadata.dataset FOR EACH ROW EXECUTE PROCEDURE pgmetadata.calculate_fields_from_data();


-- dataset trg_update_table_comment_from_dataset
CREATE TRIGGER trg_update_table_comment_from_dataset AFTER INSERT OR UPDATE ON pgmetadata.dataset FOR EACH ROW EXECUTE PROCEDURE pgmetadata.update_table_comment_from_dataset();


--
-- PostgreSQL database dump complete
--


COMMIT;
