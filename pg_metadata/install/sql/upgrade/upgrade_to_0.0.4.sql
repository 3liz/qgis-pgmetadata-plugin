-- View v_orphan_dataset_items
CREATE VIEW pgmetadata.v_orphan_dataset_items AS
SELECT row_number() OVER() AS id, schema_name, table_name 
FROM pgmetadata.dataset
WHERE CONCAT(schema_name, '.', table_name ) NOT IN 
(SELECT CONCAT(schemaname, '.', tablename) FROM pg_tables );

-- View v_orphan_tables
CREATE VIEW pgmetadata.v_orphan_tables AS
SELECT row_number() OVER() AS id, schemaname::text, tablename::text
FROM pg_tables 
WHERE CONCAT(schemaname, '.', tablename) NOT IN 
(SELECT CONCAT(schema_name, '.', table_name ) FROM pgmetadata.dataset )
AND schemaname NOT IN ('pg_catalog', 'information_schema');

-- VIEW v_orphan_dataset_items
COMMENT ON VIEW pgmetadata.v_orphan_dataset_items IS 'View containing the tables referenced in dataset but inexisting';


-- VIEW v_orphan_tables
COMMENT ON VIEW pgmetadata.v_orphan_tables IS 'View containing the existing tables but not referenced in dataset';
