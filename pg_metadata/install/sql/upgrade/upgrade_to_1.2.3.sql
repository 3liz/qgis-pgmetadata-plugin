BEGIN;

-- GLOSSARY

-- additional publication frequencies

INSERT INTO pgmetadata.glossary (id, field, code, label_en, description_en, item_order, label_fr, description_fr, label_it, description_it, label_es, description_es, label_de, description_de) VALUES (137, 'dataset.publication_frequency', 'QUA', 'Quarterly', 'Update data every three months', 4, NULL, NULL, NULL, NULL, NULL, NULL, 'Vierteljährlich', 'Daten werden vierteljährlich aktualisiert');
INSERT INTO pgmetadata.glossary (id, field, code, label_en, description_en, item_order, label_fr, description_fr, label_it, description_it, label_es, description_es, label_de, description_de) VALUES (138, 'dataset.publication_frequency', 'FTN', 'Fortnightly', 'Update data every two weeks', 6, NULL, NULL, NULL, NULL, NULL, NULL, 'Zweiwöchentlich', 'Daten werden vierzehntägig aktualisiert');
INSERT INTO pgmetadata.glossary (id, field, code, label_en, description_en, item_order, label_fr, description_fr, label_it, description_it, label_es, description_es, label_de, description_de) VALUES (139, 'dataset.publication_frequency', 'CON', 'Continual', 'Data is repeatedly and frequently updated', 9, NULL, NULL, NULL, NULL, NULL, NULL, 'Kontinuierlich', 'Daten werden ständig aktualisiert');
INSERT INTO pgmetadata.glossary (id, field, code, label_en, description_en, item_order, label_fr, description_fr, label_it, description_it, label_es, description_es, label_de, description_de) VALUES (140, 'dataset.publication_frequency', 'UNK', 'Unknown', 'Frequency of maintenance for the data is not known', 90, NULL, NULL, NULL, NULL, NULL, NULL, 'Unbekannt', 'Ein Aktualisierungsintervall ist nicht bekannt');


-- additional link types

INSERT INTO pgmetadata.glossary (id, field, code, label_en, description_en, item_order, label_fr, description_fr, label_it, description_it, label_es, description_es, label_de, description_de) VALUES (141, 'link.type', 'directory', 'A directory', 'Directory on the local filesystem', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Ein Ordner', 'Ein Ordner auf dem lokalen Dateisystem');
INSERT INTO pgmetadata.glossary (id, field, code, label_en, description_en, item_order, label_fr, description_fr, label_it, description_it, label_es, description_es, label_de, description_de) VALUES (142, 'link.mime', 'directory', 'inode/directory', 'Directory (not an official MIME type)',  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO pgmetadata.glossary (id, field, code, label_en, description_en, item_order, label_fr, description_fr, label_it, description_it, label_es, description_es, label_de, description_de) VALUES (143, 'link.type', 'ESRI:SHP', 'ESRI Shapefile', 'Vector layer in Shapefile format (.shp)', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'ESRI Shapefile', 'Vektorlayer im Shapefile-Format (.shp)');

-- codes for unknown license and confidentiality

INSERT INTO pgmetadata.glossary (id, field, code, label_en, description_en, item_order, label_fr, description_fr, label_it, description_it, label_es, description_es, label_de, description_de) VALUES (144, 'dataset.license', 'NO', 'No or unknown license', 'Dataset has been published explicitly without license or no license conditions have been documented', 100, NULL, NULL, NULL, NULL, NULL, NULL, 'Keine oder unbekannte Lizenz', 'Die Daten wurden explizit ohne Lizenz freigegeben oder die Lizenz ist nicht bekannt') ON CONFLICT DO NOTHING;
INSERT INTO pgmetadata.glossary (id, field, code, label_en, description_en, item_order, label_fr, description_fr, label_it, description_it, label_es, description_es, label_de, description_de) VALUES (145, 'dataset.confidentiality', 'UNK', 'Unknown', 'Access restrictions for this dataset are not known', 30, NULL, NULL, NULL, NULL, NULL, NULL, 'Unbekannt', 'Zugriffsbeschränkungen für diese Daten sind nicht bekannt') ON CONFLICT DO NOTHING;


SELECT pg_catalog.setval('pgmetadata.glossary_id_seq', 145, true);


-- new item_order for existing publication frequencies

CREATE TABLE pgmetadata.t_glossary (field text, code text, item_order smallint);
INSERT INTO pgmetadata.t_glossary (field, code, item_order)
VALUES
('dataset.publication_frequency', 'MON', 5),
('dataset.publication_frequency', 'WEE', 7),
('dataset.publication_frequency', 'DAY', 8),
('dataset.publication_frequency', 'IRR', 10),
('dataset.publication_frequency', 'NOP', 11)
ON CONFLICT DO NOTHING;

UPDATE pgmetadata.glossary AS g
SET item_order = t.item_order
FROM pgmetadata.t_glossary AS t
WHERE g.field = t.field AND g.code = t.code;

DROP TABLE pgmetadata.t_glossary;


-- capitalise existing German translations

CREATE TABLE pgmetadata.t_glossary (field text, code text, label_de text, description_de text);
INSERT INTO pgmetadata.t_glossary (field, code, label_de, description_de)
VALUES
('dataset.categories', 'BOU', 'Grenzen', 'Gesetzlich festgelegte Grenzen'),
('dataset.categories', 'STR', 'Bauwerke', 'Anthropogene Bauten'),
('dataset.categories', 'GEO', 'Geowissenschaften', 'Geowissenschaftliche Informationen'),
('dataset.categories', 'SOC', 'Gesellschaft', 'Kulturelle und gesellschaftliche Merkmale'),
('dataset.categories', 'ECO', 'Wirtschaft', 'Wirtschaftliche Aktivitäten, Verhältnisse und Beschäftigung'),
('link.type', 'file', 'Eine Datei', 'CKAN Metadata Vocabulary, um die Typattribute einer CKAN-Ressource zu füllen; zeigt an, dass ein http:GET dieses URL einen Bitstream liefern sollte'),
('dataset.confidentiality', 'OPE', 'Offen', 'Keine Einschränkungen des Zugriffs auf diese Daten'),
('dataset.confidentiality', 'RES', 'Eingeschränkt', 'Der Zugriff auf die Daten ist auf ausgewählte Nutzer beschränkt'),
('dataset.publication_frequency', 'DAY', 'Täglich', 'Daten werden täglich aktualisiert'),
('dataset.publication_frequency', 'MON', 'Monatlich', 'Daten werden monatlich aktualisiert'),
('dataset.publication_frequency', 'YEA', 'Jährlich', 'Daten werden jährlich aktualisiert'),
('dataset.publication_frequency', 'NEC', 'Bei Bedarf', 'Daten werden bei Bedarf aktualisiert'),
('dataset.publication_frequency', 'WEE', 'Wöchentlich', 'Daten werden wöchentlich aktualisiert'),
('dataset.publication_frequency', 'BIA', 'Halbjährlich', 'Daten werden halbjährlich aktualisiert'),
('dataset.publication_frequency', 'IRR', 'Unregelmäßig', 'Daten werden unregelmäßig aktualisiert'),
('dataset.publication_frequency', 'NOP', 'Nicht geplant', 'Eine Aktualisierung der Daten ist nicht geplant'),
('dataset.license', 'proj', 'Nur für Projektbearbeitung', NULL)
ON CONFLICT DO NOTHING;

UPDATE pgmetadata.glossary AS g
SET (label_de, description_de) = (t.label_de, t.description_de)
FROM pgmetadata.t_glossary AS t
WHERE g.field = t.field AND g.code = t.code;

DROP TABLE pgmetadata.t_glossary;

COMMIT;
