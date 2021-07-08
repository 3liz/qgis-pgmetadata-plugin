BEGIN;

-- add ids because in the administration project QGIS automatically sets the first column as key, now all records will be displayed.
DROP VIEW pgmetadata.v_valid_dataset;
CREATE OR REPLACE VIEW pgmetadata.v_valid_dataset
 AS
 SELECT row_number() OVER () AS id,
    d.schema_name,
    d.table_name
   FROM pgmetadata.dataset d
     LEFT JOIN information_schema.tables t ON d.schema_name = t.table_schema::text AND d.table_name = t.table_name::text
  WHERE t.table_name IS NOT NULL
  ORDER BY d.schema_name, d.table_name;

-- VIEW v_valid_dataset
COMMENT ON VIEW pgmetadata.v_valid_dataset IS 'Gives a list of lines from pgmetadata.dataset with corresponding (existing) tables and views.';

-- add ids, see above.
-- extend with (adapted) table_types (information_schema.tables) to be used by the comment trigger function. 
-- table_type ~~ 'FOREIGN%' is due to compatibility with PG>10.
DROP VIEW pgmetadata.v_table_comment_from_metadata;
CREATE VIEW pgmetadata.v_table_comment_from_metadata AS
 SELECT row_number() OVER () AS id,
    d.schema_name AS table_schema,
    d.table_name,
    concat(d.title, ' - ', d.abstract, ' (', array_to_string(d.categories, ', '::text), ')') AS table_comment,
        CASE
            WHEN ((t.table_type)::text = 'BASE TABLE'::text) THEN 'TABLE'::text
            WHEN ((t.table_type)::text ~~ 'FOREIGN%'::text) THEN 'FOREIGN TABLE'::text
            ELSE (t.table_type)::text
        END AS table_type
   FROM (pgmetadata.dataset d
      LEFT JOIN information_schema.tables t ON (((d.schema_name = (t.table_schema)::text) AND (d.table_name = (t.table_name)::text))));

-- VIEW v_table_comment_from_metadata
COMMENT ON VIEW pgmetadata.v_table_comment_from_metadata IS 'View containing the desired formatted comment for the tables listed in the pgmetadata.dataset table. This view is used by the trigger to update the table comment when the dataset item is added or modified';


--extend function update_postgresql_table_comment(text, text, text) for working on all sorts of table types
DROP FUNCTION pgmetadata.update_postgresql_table_comment(text, text, text);

-- update_postgresql_table_comment(text, text, text, text)
-- extending the sql_text with adapted table_types from v_table_comment_from_metadata.
CREATE FUNCTION pgmetadata.update_postgresql_table_comment(table_schema text, table_name text, table_comment text, table_type text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    sql_text text;
BEGIN

    BEGIN
        sql_text = 'COMMENT ON ' || replace(quote_literal(table_type), '''', '') || ' ' || quote_ident(table_schema) || '.' || quote_ident(table_name) || ' IS ' || quote_literal(table_comment) ;
        EXECUTE sql_text;
        RAISE NOTICE 'Comment updated for %s', quote_ident(table_schema) || '.' || quote_ident(table_name) ;
        RETURN True;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'ERROR - Failed updated comment for table %s', quote_ident(table_schema) || '.' || quote_ident(table_name);
        RETURN False;
    END;

    RETURN True;
END;
$$;


-- FUNCTION update_postgresql_table_comment(table_schema text, table_name text, table_comment text, table_type text)
COMMENT ON FUNCTION pgmetadata.update_postgresql_table_comment(table_schema text, table_name text, table_comment text, table_type text) IS 'Update the PostgreSQL comment of a table by giving table schema, name and comment
Example: if you need to update the comments for all the items listed by pgmetadata.v_table_comment_from_metadata:

    SELECT
    v.table_schema,
    v.table_name,
    pgmetadata.update_postgresql_table_comment(
        v.table_schema,
        v.table_name,
        v.table_comment,
        v.table_type
    ) AS comment_updated
    FROM pgmetadata.v_table_comment_from_metadata AS v

    ';


-- update_table_comment_from_dataset()
DROP FUNCTION pgmetadata.update_table_comment_from_dataset() CASCADE;
CREATE FUNCTION pgmetadata.update_table_comment_from_dataset() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    is_updated bool;
BEGIN
    SELECT pgmetadata.update_postgresql_table_comment(
        v.table_schema,
        v.table_name,
        v.table_comment,
        v.table_type
    )
    FROM pgmetadata.v_table_comment_from_metadata AS v
    WHERE True
    AND v.table_schema = NEW.schema_name
    AND v.table_name = NEW.table_name
    INTO is_updated
    ;

    RETURN NEW;
END;
$$;


-- FUNCTION update_table_comment_from_dataset()
COMMENT ON FUNCTION pgmetadata.update_table_comment_from_dataset() IS 'Update the PostgreSQL table comment when updating or inserting a line in pgmetadata.dataset table. Comment is taken from the view pgmetadata.v_table_comment_from_metadata.';

-- restore trigger
CREATE TRIGGER trg_update_table_comment_from_dataset AFTER INSERT OR UPDATE ON pgmetadata.dataset FOR EACH ROW EXECUTE PROCEDURE pgmetadata.update_table_comment_from_dataset();


COMMIT;
