BEGIN;

-- v_orphan_tables add support for views
CREATE OR REPLACE VIEW pgmetadata.v_orphan_tables
 AS
 SELECT row_number() OVER () AS id,
    (tables.table_schema)::text AS schemaname,
    (tables.table_name)::text AS tablename
   FROM information_schema.tables
  WHERE ((NOT (concat(tables.table_schema, '.', tables.table_name) IN ( SELECT concat(dataset.schema_name, '.', dataset.table_name) AS concat
           FROM pgmetadata.dataset))) AND (tables.table_schema <> ALL (ARRAY['pg_catalog'::name, 'information_schema'::name])))
  ORDER BY ((tables.table_schema)::text), ((tables.table_name)::text);

-- v_orphan_dataset_items add support for views
CREATE OR REPLACE VIEW pgmetadata.v_orphan_dataset_items
 AS
 SELECT row_number() OVER () AS id,
    d.schema_name,
    d.table_name
   FROM pgmetadata.dataset d
     LEFT JOIN information_schema.tables t ON (((d.schema_name = (t.table_schema)::text) AND (d.table_name = (t.table_name)::text)))
  WHERE (t.table_name IS NULL)
  ORDER BY d.schema_name, d.table_name;

-- v_valid_dataset add support for views
CREATE OR REPLACE VIEW pgmetadata.v_valid_dataset
 AS
 SELECT d.schema_name,
    d.table_name
   FROM pgmetadata.dataset d
     LEFT JOIN information_schema.tables t ON (((d.schema_name = (t.table_schema)::text) AND (d.table_name = (t.table_name)::text)))
  WHERE (t.table_name IS NOT NULL)
  ORDER BY d.schema_name, d.table_name;

COMMENT ON VIEW pgmetadata.v_valid_dataset IS 'Gives a list of lines from pgmetadata.dataset with corresponding (existing) tables and views.';

COMMIT;
