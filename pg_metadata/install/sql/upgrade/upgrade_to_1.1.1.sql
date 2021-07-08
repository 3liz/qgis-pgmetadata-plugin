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
            WHEN t.table_type::text = 'BASE TABLE'::text THEN 'TABLE'::text
            WHEN t.table_type::text ~~ 'FOREIGN%'::text THEN 'FOREIGN TABLE'::text
            ELSE t.table_type::text
        END AS table_type
   FROM pgmetadata.dataset d
      LEFT JOIN information_schema.tables t ON d.schema_name = t.table_schema::text AND d.table_name = t.table_name::text;

-- VIEW v_table_comment_from_metadata
COMMENT ON VIEW pgmetadata.v_table_comment_from_metadata IS 'View containing the desired formatted comment for the tables listed in the pgmetadata.dataset table. This view is used by the trigger to update the table comment when the dataset item is added or modified';
