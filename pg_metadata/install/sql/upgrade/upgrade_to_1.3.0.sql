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


-- remaining INSPIRE contact roles

INSERT INTO pgmetadata.glossary (id, field, code, label_en, description_en, item_order, label_fr, description_fr, label_it, description_it, label_es, description_es, label_de, description_de) VALUES (146, 'contact.contact_role', 'AU', 'Author', 'Party who authored the resource', 45, 'Auteur', 'Partie qui est l’auteur de la ressource', NULL, NULL, NULL, NULL, 'Autor', 'Verfasser der Ressource');
INSERT INTO pgmetadata.glossary (id, field, code, label_en, description_en, item_order, label_fr, description_fr, label_it, description_it, label_es, description_es, label_de, description_de) VALUES (147, 'contact.contact_role', 'PC', 'Point of Contact', 'Party who can be contacted for acquiring knowledge about or acquisition of the resource', 5, 'Point de contact', 'Partie qu’il est possible de contacter pour s’informer sur la ressource ou en faire l’acquisition', NULL, NULL, NULL, NULL, 'Ansprechpartner', 'Kontakt für Informationen zur Ressource oder deren Bezugsmöglichkeiten');
INSERT INTO pgmetadata.glossary (id, field, code, label_en, description_en, item_order, label_fr, description_fr, label_it, description_it, label_es, description_es, label_de, description_de) VALUES (148, 'contact.contact_role', 'PI', 'Principal Investigator', 'Key party responsible for gathering information and conducting research', 47, 'Maître d’œuvre', 'Principale partie chargée de recueillir des informations et de mener les recherches', NULL, NULL, NULL, NULL, 'Projektleitung', 'Person oder Stelle, die verantwortlich für die Erhebung der Daten und die Untersuchung ist');
INSERT INTO pgmetadata.glossary (id, field, code, label_en, description_en, item_order, label_fr, description_fr, label_it, description_it, label_es, description_es, label_de, description_de) VALUES (149, 'contact.contact_role', 'PU', 'Publisher', 'Party who published the resource', 15, 'Éditeur', 'Partie qui a publié la ressource', NULL, NULL, NULL, NULL, 'Herausgeber', 'Person oder Stelle, welche die Ressource veröffentlicht');
INSERT INTO pgmetadata.glossary (id, field, code, label_en, description_en, item_order, label_fr, description_fr, label_it, description_it, label_es, description_es, label_de, description_de) VALUES (150, 'contact.contact_role', 'RP', 'Resource Provider', 'Party that supplies the resource.', 25, 'Fournisseur de la ressource', 'Partie qui fournit la ressource', NULL, NULL, NULL, NULL, 'Ressourcenanbieter', 'Anbieter der Ressource');
INSERT INTO pgmetadata.glossary (id, field, code, label_en, description_en, item_order, label_fr, description_fr, label_it, description_it, label_es, description_es, label_de, description_de) VALUES (151, 'contact.contact_role', 'US', 'User', 'Party who uses the resource', 80, 'Utilisateur', 'Partie qui utilise la ressource', NULL, NULL, NULL, NULL, 'Nutzer', 'Nutzer der Ressource');


-- UK Open Government Licence

INSERT INTO pgmetadata.glossary (id, field, code, label_en, description_en, item_order, label_fr, description_fr, label_it, description_it, label_es, description_es, label_de, description_de) VALUES (152, 'dataset.license', 'OGL-UK-3.0', 'Open Government Licence v3.0', 'https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/', 85, NULL, NULL, NULL, NULL, NULL, NULL, 'Open Government Licence v3.0', NULL);


-- additional non-ISO publication frequencies longer than 1 year

INSERT INTO pgmetadata.glossary (id, field, code, label_en, description_en, item_order, label_fr, description_fr, label_it, description_it, label_es, description_es, label_de, description_de) VALUES (153, 'dataset.publication_frequency', 'Y02', 'Every 2 years', 'Update data every two years', 22, NULL, NULL, NULL, NULL, NULL, NULL, 'Alle 2 Jahre', 'Daten werden alle zwei Jahre aktualisiert') ON CONFLICT DO NOTHING;
INSERT INTO pgmetadata.glossary (id, field, code, label_en, description_en, item_order, label_fr, description_fr, label_it, description_it, label_es, description_es, label_de, description_de) VALUES (154, 'dataset.publication_frequency', 'Y03', 'Every 3 years', 'Update data every three years', 23, NULL, NULL, NULL, NULL, NULL, NULL, 'Alle 3 Jahre', 'Daten werden alle drei Jahre aktualisiert') ON CONFLICT DO NOTHING;
INSERT INTO pgmetadata.glossary (id, field, code, label_en, description_en, item_order, label_fr, description_fr, label_it, description_it, label_es, description_es, label_de, description_de) VALUES (155, 'dataset.publication_frequency', 'Y04', 'Every 4 years', 'Update data every four years', 24, NULL, NULL, NULL, NULL, NULL, NULL, 'Alle 4 Jahre', 'Daten werden alle vier Jahre aktualisiert') ON CONFLICT DO NOTHING;
INSERT INTO pgmetadata.glossary (id, field, code, label_en, description_en, item_order, label_fr, description_fr, label_it, description_it, label_es, description_es, label_de, description_de) VALUES (156, 'dataset.publication_frequency', 'Y05', 'Every 5 years', 'Update data every five years', 25, NULL, NULL, NULL, NULL, NULL, NULL, 'Alle 5 Jahre', 'Daten werden alle fünf Jahre aktualisiert') ON CONFLICT DO NOTHING;
INSERT INTO pgmetadata.glossary (id, field, code, label_en, description_en, item_order, label_fr, description_fr, label_it, description_it, label_es, description_es, label_de, description_de) VALUES (157, 'dataset.publication_frequency', 'Y06', 'Every 6 years', 'Update data every six years', 26, NULL, NULL, NULL, NULL, NULL, NULL, 'Alle 6 Jahre', 'Daten werden alle sechs Jahre aktualisiert') ON CONFLICT DO NOTHING;


-- additional non-standard contact roles used by German governments

INSERT INTO pgmetadata.glossary (id, field, code, label_en, description_en, item_order, label_fr, description_fr, label_it, description_it, label_es, description_es, label_de, description_de) VALUES (158, 'contact.contact_role', 'WA', 'WMS/WFS Administrator', 'Person or party who can aid with WMS/WFS issues', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'WMS/WFS-Ansprechpartner', 'Person oder Stelle, die bei WMS/WFS-Problemen weiterhelfen kann') ON CONFLICT DO NOTHING;
INSERT INTO pgmetadata.glossary (id, field, code, label_en, description_en, item_order, label_fr, description_fr, label_it, description_it, label_es, description_es, label_de, description_de) VALUES (159, 'contact.contact_role', 'GA', 'GIS Administrator', 'Person or party who can aid with GIS-related issues', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'GIS-technischer Ansprechpartner', 'Person oder Stelle, die bei GIS-technischen Angelegenheiten weiterhelfen kann') ON CONFLICT DO NOTHING;

-- unspecified license for free use

INSERT INTO pgmetadata.glossary (id, field, code, label_en, description_en, item_order, label_fr, description_fr, label_it, description_it, label_es, description_es, label_de, description_de) VALUES (160, 'dataset.license', 'free_notspec', 'Free use, no detailed license terms specified', NULL, 85, NULL, NULL, NULL, NULL, NULL, NULL, 'Frei nutzbar, keine konkreten Lizenzbedingungen angegeben', NULL);


SELECT pg_catalog.setval('pgmetadata.glossary_id_seq', 160 , true);


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
('dataset.categories', 'OCE', 'Meere', 'Merkmale und Charakteristika von salzhaltigen Gewässern (außer Binnengewässern)'),
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
('dataset.license', 'proj', 'Nur für Projektbearbeitung', 'Daten wurden nur für projektinterne Nutzung freigegeben'),
('dataset.license', 'CC-BY-SA-4.0', 'Creative Commons Namensnennung – Weitergabe unter gleichen Bedingungen – Version 4.0', NULL)
ON CONFLICT DO NOTHING;

UPDATE pgmetadata.glossary AS g
SET (label_de, description_de) = (t.label_de, t.description_de)
FROM pgmetadata.t_glossary AS t
WHERE g.field = t.field AND g.code = t.code;

DROP TABLE pgmetadata.t_glossary;

COMMIT;
