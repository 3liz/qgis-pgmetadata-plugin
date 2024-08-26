import re

from xml.dom.minidom import parseString

from qgis.core import QgsDataSourceUri, QgsVectorLayer
from qgis.PyQt.QtCore import NULL
from qgis_plugin_tools.tools.resources import resources_path

from pg_metadata.test.base_database import DatabaseTestCase


class TestSql(DatabaseTestCase):

    # For the DCAT output, diffs can be long.
    maxDiff = None

    def _sql(self, sql):
        return self.connection.executeSql(sql)

    def _insert(self, feature_map, table='dataset', return_value=None):
        fields = []
        values = []
        for column, value in feature_map.items():
            fields.append(column)
            values.append(value)
        sql = 'INSERT INTO pgmetadata.{table} ({fields}) VALUES ({values})'.format(
            table=table,
            fields=','.join(fields),
            values=','.join(values),
        )
        if return_value:
            sql += ' RETURNING {};'.format(return_value)
        return self._sql(sql)

    def test_translation(self):
        """ Test to translate some glossary terms. """
        # Insert a feature
        dataset_feature = {
            'table_name': "'lines'",
            'schema_name': "'pgmetadata'",
            'title': "'Test title'",
            'abstract': "'Test abstract.'",
            'publication_frequency': "'NEC'",  # Available in EN and FR
            'license': "'CC0'",  # Available in EN only, not in FR
        }
        self._insert(dataset_feature, 'dataset')

        # Remove previous template to have a smaller one
        sql = "DELETE FROM pgmetadata.html_template WHERE section IN ('main');"
        self._sql(sql)

        html_feature = {
            'section': "'main'",
            'content': "'<p>[% publication_frequency %]</p><p>[% license %]</p>'",
        }
        self._insert(html_feature, 'html_template')

        # To English by default
        result = self._sql("SELECT pgmetadata.get_dataset_item_html_content('pgmetadata','lines')")
        self.assertEqual('<p>When necessary</p><p>Creative Commons CC Zero</p>', result[0][0])

        # To English
        result = self._sql("SELECT pgmetadata.get_dataset_item_html_content('pgmetadata','lines', 'en')")
        self.assertEqual('<p>When necessary</p><p>Creative Commons CC Zero</p>', result[0][0])

        # To French
        result = self._sql("SELECT pgmetadata.get_dataset_item_html_content('pgmetadata','lines', 'fr')")
        self.assertEqual('<p>Lorsque nécessaire</p><p>Creative Commons CC Zero</p>', result[0][0])

        # To French, capital letter
        result = self._sql("SELECT pgmetadata.get_dataset_item_html_content('pgmetadata','lines', 'FR')")
        self.assertEqual('<p>Lorsque nécessaire</p><p>Creative Commons CC Zero</p>', result[0][0])

        # To leet, https://en.wikipedia.org/wiki/Leet ;-)
        result = self._sql("SELECT pgmetadata.get_dataset_item_html_content('pgmetadata','lines', 'leet')")
        self.assertEqual('<p>When necessary</p><p>Creative Commons CC Zero</p>', result[0][0])

    def test_html_template(self):
        """ Test HTML template. """
        theme_feature = {
            'code': "'A01'",
            'label': "'test theme'",
        }
        self._insert(theme_feature, 'theme')
        theme_feature = {
            'code': "'A02'",
            'label': "'New test theme'",
        }
        self._insert(theme_feature, 'theme')
        dataset_feature = {
            'table_name': "'lines'",
            'schema_name': "'pgmetadata'",
            'title': "'Test title'",
            'abstract': "'Test abstract.'",
            'themes': "'{\"A01\", \"A02\"}'",
            'data_last_update': "'2020-12-25T20:35:59'::timestamp",
        }
        return_value = self._insert(dataset_feature, 'dataset', 'id')
        web_link_feature = {
            'name': "'test web link'",
            'type': "'file'",
            'url': "'https://metadata.is.good'",
            'description': "''",
            'size': "0.5",
            'fk_id_dataset': "{}".format(return_value[0][0]),
        }
        self._insert(web_link_feature, 'link')
        file_link_feature = {
            'name': "'test file link'",
            'type': "'file'",
            'url': r"'file:///C:\Users\test\1file.txt'",
            'description': "''",
            'size': "0.5",
            'fk_id_dataset': "{}".format(return_value[0][0]),
        }
        self._insert(file_link_feature, 'link')

        # Remove previous template to have a smaller one
        sql = "DELETE FROM pgmetadata.html_template WHERE section IN ('main', 'link');"
        self._sql(sql)

        html_feature = {
            'section': "'main'",
            'content': (
                "'"
                "<p>[% \"title\" %]</p><b>[%\"abstract\"%]</b>"
                "<p>[%\"data_last_update\"%]</p>"
                "<p>[% meta_links %]</p>"
                "<p>[%\"themes\"%]</p>"
                "'"
            ),
        }
        self._insert(html_feature, 'html_template')
        html_feature = {
            'section': "'link'",
            'content': "'<p>[% \"name\" %] [% \"description\" %]</p><p>[% url %] [% \"size\" %]</p>'",
        }
        self._insert(html_feature, 'html_template')

        result = (
            self._sql("SELECT pgmetadata.get_dataset_item_html_content('pgmetadata','lines')")
        )
        expected = (
            '<p>Test title</p><b>Test abstract.</b><p>2020-12-25T20:35:59</p><p>\n'
            '            <p>test web link </p><p>https://metadata.is.good 1</p>\n'
            r'            <p>test file link </p><p>file:///C:\Users\test\1file.txt 1</p>'
            '</p><p>New test theme, test theme</p>'
        )
        self.assertEqual(expected, result[0][0])

    def test_dcat_export(self):
        """ Test DCAT export. """
        theme_feature = {
            'code': "'A01'",
            'label': "'test theme'",
        }
        self._insert(theme_feature, 'theme')
        theme_feature = {
            'code': "'A02'",
            'label': "'New test theme'",
        }
        self._insert(theme_feature, 'theme')
        dataset_feature = {
            'table_name': "'lines'",
            'schema_name': "'pgmetadata'",
            'title': "'Test title'",
            'abstract': "'Test abstract.'",
            'themes': "'{\"A01\", \"A02\"}'",
            'keywords': "'tag_one, tag_two'",
            'confidentiality': "'OPE'",
            'publication_frequency': "'YEA'",
            'license': "'LO-2.1'",
            'publication_date': "'2020-12-31T09:16:16.980258'",
        }
        return_value = self._insert(dataset_feature, 'dataset', 'id, uid')

        web_link_feature = {
            'name': "'test web link'",
            'type': "'file'",
            'mime': "'pdf'",
            'url': "'https://metadata.is.good'",
            'description': "'Link description'",
            'size': "590",
            'fk_id_dataset': "{}".format(return_value[0][0]),
        }
        self._insert(web_link_feature, 'link')
        file_link_feature = {
            'name': "'test file link'",
            'type': "'file'",
            'mime': "'plain'",
            'url': r"'file:///C:\Users\test\1file.txt'",
            'description': "'File description'",
            'size': "590",
            'fk_id_dataset': "{}".format(return_value[0][0]),
        }
        self._insert(file_link_feature, 'link')
        contact_feature = {
            'name': "'Jane Doe'",
            'organisation_name': "'Acme'",
            'organisation_unit': "'GIS'",
            'email': "'jane.doe@acme.gis'",
        }
        contact_a = self._insert(contact_feature, 'contact', 'id')
        contact_feature = {
            'name': "'Bob Robert'",
            'organisation_name': "'Corp'",
            'organisation_unit': "'Spatial div'",
            'email': "'bob.bob@corp.spa'",
        }
        contact_b = self._insert(contact_feature, 'contact', 'id')
        dataset_contact_feature = {
            'fk_id_contact': "{}".format(contact_a[0][0]),
            'fk_id_dataset': "{}".format(return_value[0][0]),
            'contact_role': "'OW'",
        }
        self._insert(dataset_contact_feature, 'dataset_contact')
        dataset_contact_feature = {
            'fk_id_contact': "{}".format(contact_b[0][0]),
            'fk_id_dataset': "{}".format(return_value[0][0]),
            'contact_role': "'DI'",
        }
        self._insert(dataset_contact_feature, 'dataset_contact')

        sql = (
            "SELECT table_name, schema_name, uid, dataset"
            " FROM pgmetadata.get_datasets_as_dcat_xml("
            "    'en',"
            "    ARRAY['{}'::uuid]"
            ")"
        ).format(return_value[0][1])
        result = (
            self._sql(sql)
        )
        # Table name
        self.assertEqual('lines', result[0][0])

        # Schema name
        self.assertEqual('pgmetadata', result[0][1])

        # UUID
        self.assertEqual(return_value[0][1], result[0][2])

        # DCAT
        expected = (
            '<dcat:dataset><dcat:Dataset>'
            '<dct:identifier>{uid}</dct:identifier><dct:title>Test title</dct:title>'
            '<dct:description>Test abstract.</dct:description>'
            '<dct:language>en</dct:language>'
            '<dct:license>Licence Ouverte Version 2.1</dct:license>'
            '<dct:rights>Open</dct:rights>'
            '<dct:accrualPeriodicity>Yearly</dct:accrualPeriodicity>'
            '<dct:spatial>{polygon}</dct:spatial>'

            '<dct:created rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">'
            'XXX'
            '</dct:created>'
            '<dct:issued rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">'
            'XXX'
            '</dct:issued>'
            '<dct:modified rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">'
            'XXX'
            '</dct:modified>'

            '<dcat:contactPoint><vcard:Organization><vcard:fn>Jane Doe - Acme (GIS)</vcard:fn>'
            '<vcard:hasEmail rdf:resource="jane.doe@acme.gis">jane.doe@acme.gis</vcard:hasEmail>'
            '</vcard:Organization></dcat:contactPoint>'

            '<dct:creator><foaf:Organization>'
            '<foaf:name>Jane Doe - Acme (GIS)</foaf:name><foaf:mbox>jane.doe@acme.gis</foaf:mbox>'
            '</foaf:Organization></dct:creator>'

            '<dct:publisher><foaf:Organization>'
            '<foaf:name>Bob Robert - Corp (Spatial div)</foaf:name>'
            '<foaf:mbox>bob.bob@corp.spa</foaf:mbox>'
            '</foaf:Organization></dct:publisher>'

            '<dcat:distribution><dcat:Distribution><dct:title>test web link</dct:title>'
            '<dct:description>Link description</dct:description>'
            '<dcat:downloadURL>https://metadata.is.good</dcat:downloadURL>'
            '<dcat:mediaType>application/pdf</dcat:mediaType><dct:format>a file</dct:format>'
            '<dct:bytesize>590</dct:bytesize>'
            '<dct:license>Licence Ouverte Version 2.1</dct:license>'
            '</dcat:Distribution></dcat:distribution>'
            '<dcat:distribution><dcat:Distribution><dct:title>test file link</dct:title>'
            '<dct:description>File description</dct:description>'
            r'<dcat:downloadURL>file:///C:\Users\test\1file.txt</dcat:downloadURL>'
            '<dcat:mediaType>text/plain</dcat:mediaType><dct:format>a file</dct:format>'
            '<dct:bytesize>590</dct:bytesize>'
            '<dct:license>Licence Ouverte Version 2.1</dct:license>'
            '</dcat:Distribution></dcat:distribution>'

            '<dcat:keyword>tag_one</dcat:keyword><dcat:keyword>tag_two</dcat:keyword>'
            '<dcat:theme>test theme</dcat:theme><dcat:theme>New test theme</dcat:theme>'
            '</dcat:Dataset></dcat:dataset>'
        ).format(
            polygon=(
                '{"type":"Polygon","coordinates":[[[3.854,43.5786],[3.854,43.622],[3.897,43.622],'
                '[3.897,43.5786],[3.854,43.5786]]]}'
            ),
            uid=return_value[0][1]
        )
        result = re.sub(r"(dateTime\">)([0-9\-T:.]*)(</dct)", r'\1XXX\3', result[0][3])
        self.assertEqual(
            expected,
            result,
            '\nTest expected\n{}\nbut got\n{}\nare different'.format(expected, result)
        )

        # Test XML validity
        with open(resources_path('xml', 'dcat.xml'), encoding='utf8') as xml_file:
            xml_template = xml_file.read()

        # An exception is raised if the validity is not correct
        parseString(xml_template.format(locale='fr', content=result))

    def test_export_catalog_as_flat_table(self):
        """ Test to export the catalog as a flat table. """
        dataset_feature = {
            'table_name': "'lines'",
            'schema_name': "'pgmetadata'",
            'title': "'Test title'",
            'abstract': "'Test abstract.'",
        }
        self._insert(dataset_feature, 'dataset')
        dataset_feature = {
            'table_name': "'does_not_exist'",
            'schema_name': "'pgmetadata'",
            'title': "'Test title'",
            'abstract': "'Test abstract.'",
        }
        self._insert(dataset_feature, 'dataset')

        uri = QgsDataSourceUri(self.connection.uri())
        uri.setTable('(SELECT * FROM pgmetadata.export_datasets_as_flat_table(\'fr\'))')
        uri.setKeyColumn('uid')
        layer = QgsVectorLayer(uri.uri(False), 'export catalog', 'postgres')

        self.assertTrue(layer.isValid())
        self.assertEqual(2, layer.featureCount())  # We count invalid dataset as well
        self.assertNotEqual(-1, layer.fields().indexFromName('links'))
        self.assertNotEqual(-1, layer.fields().indexFromName('contacts'))

    def test_trigger_calculate_fields(self):
        """ Test if fields are correctly calculated on a layer having a geometry. """

        # Adding data
        dataset_feature = {
            'table_name': "'lines'",
            'schema_name': "'pgmetadata'",
            'title': "'Test title'",
            'abstract': "'Test abstract.'",
        }
        self._insert(dataset_feature, 'dataset')

        # Test insert
        sql = "SELECT geometry_type, projection_authid, spatial_extent FROM pgmetadata.dataset"
        result = self._sql(sql)[0]
        self.assertEqual('LINESTRING', result[0])
        self.assertEqual('EPSG:4326', result[1])
        coordinates = [f.strip()[0:6] for f in result[2].split(',')]
        self.assertListEqual(['3.854', '3.897', '43.578', '43.622'], coordinates)

        # Test date, creation_date is equal to update_date
        sql = "SELECT creation_date, update_date FROM pgmetadata.dataset"
        result = self._sql(sql)
        self.assertEqual(result[0][0], result[0][1])

        # Test update
        sql = "UPDATE pgmetadata.dataset SET title = 'test lines title' WHERE table_name = 'lines'"
        self._sql(sql)
        sql = "SELECT title, geometry_type, projection_authid, spatial_extent FROM pgmetadata.dataset"
        result = self._sql(sql)[0]
        self.assertEqual('test lines title', result[0])
        self.assertEqual('LINESTRING', result[1])
        self.assertEqual('EPSG:4326', result[2])
        coordinates = [f.strip()[0:6] for f in result[3].split(',')]
        self.assertListEqual(['3.8540', '3.8969', '43.578', '43.621'], coordinates)

        # Test date, creation_date is not equal to update_date
        sql = "SELECT creation_date, update_date FROM pgmetadata.dataset"
        result = self._sql(sql)
        self.assertNotEqual(result[0][0], result[0][1])

    def test_sql_view(self):
        """ Basic test on a SQL view. """
        sql = "CREATE VIEW pgmetadata.test_view AS SELECT 1 AS id, 'test' AS label;"
        self._sql(sql)
        dataset_feature = {
            'table_name': "'test_view'",
            'schema_name': "'pgmetadata'",
            'title': "'Test title SQL view'",
            'abstract': "'Test abstract SQL view.'",
        }
        self._insert(dataset_feature, 'dataset')
        sql = (
            "SELECT geometry_type, projection_authid, spatial_extent, geom, feature_count "
            "FROM pgmetadata.dataset "
            "WHERE table_name = 'test_view'"
        )
        result = self._sql(sql)
        self.assertEqual([NULL, NULL, NULL, NULL, 1], result[0])

        sql = (
            "SELECT table_comment "
            "FROM pgmetadata.v_table_comment_from_metadata "
            "WHERE table_name = 'test_view'"
        )
        result = self._sql(sql)
        self.assertEqual(["Test title SQL view - Test abstract SQL view. ()"], result[0])

    def test_trigger_calculate_fields_when_removing_geom(self):
        """ Test the trigger on an existing vector table where we remove the geometry. """

        # Adding data
        dataset_feature = {
            'table_name': "'lines'",
            'schema_name': "'pgmetadata'",
            'title': "'Test title'",
            'abstract': "'Test abstract.'",
        }
        self._insert(dataset_feature, 'dataset')

        # Test with removing the geom column
        sql = "ALTER TABLE pgmetadata.lines DROP COLUMN geom"
        self._sql(sql)
        sql = "UPDATE pgmetadata.dataset SET title = 'test after drop geom column'"
        self._sql(sql)
        sql = "SELECT title, geometry_type, projection_authid, spatial_extent, geom FROM pgmetadata.dataset"
        result = self._sql(sql)
        self.assertEqual(['test after drop geom column', NULL, NULL, NULL, NULL], result[0])

    def test_trigger_calculate_fields_without_geom(self):
        """ Test compute fields on a geometry less table. """

        # Test with new table without geom column
        sql = "CREATE TABLE pgmetadata.test_without_geom (id serial, name text)"
        self._sql(sql)
        dataset_feature = {
            'table_name': "'test_without_geom'",
            'schema_name': "'pgmetadata'",
            'title': "'Test title'",
            'abstract': "'Test abstract.'",
        }
        self._insert(dataset_feature, 'dataset')
        sql = (
            "SELECT geometry_type, projection_authid, spatial_extent, geom "
            "FROM pgmetadata.dataset "
            "WHERE table_name = 'test_without_geom'"
        )
        result = self._sql(sql)
        self.assertEqual([NULL, NULL, NULL, NULL], result[0])

    def test_trigger_calculate_geom_z(self):
        """ Test compute fields on a table with Z values. """
        sql = "CREATE TABLE pgmetadata.test_geom_z (id serial, geom geometry(POINTZ, 4326) );"
        self._sql(sql)
        sql = "INSERT INTO pgmetadata.test_geom_z (\"geom\") VALUES (ST_GeomFromText('POINTZ(0 0 0)', 4326))"
        self._sql(sql)

        dataset_feature = {
            'table_name': "'test_geom_z'",
            'schema_name': "'pgmetadata'",
            'title': "'Test title Z'",
            'abstract': "'Test abstract Z.'",
        }
        self._insert(dataset_feature, 'dataset')

        sql = (
            "SELECT geometry_type, projection_authid, spatial_extent "
            "FROM pgmetadata.dataset "
            "WHERE table_name = 'test_geom_z'"
        )
        result = self._sql(sql)
        self.assertListEqual(['POINT', 'EPSG:4326', '0, 0, 0, 0'], result[0])

    def test_trigger_calculate_fields_raster(self):
        """ Test if fields are correctly calculated on a raster layer (having a rast column). """

        # Adding data
        dataset_feature = {
            'table_name': "'raster'",
            'schema_name': "'pgmetadata'",
            'title': "'Test title'",
            'abstract': "'Test abstract.'",
        }
        self._insert(dataset_feature, 'dataset')

        # Test insert
        sql = "SELECT geometry_type, projection_authid, spatial_extent FROM pgmetadata.dataset"
        result = self._sql(sql)
        self.assertEqual(['RASTER', 'EPSG:25833', '300000, 300800, 5700000, 5700800'], result[0])

        # Test date, creation_date is equal to update_date
        sql = "SELECT creation_date, update_date FROM pgmetadata.dataset"
        result = self._sql(sql)
        self.assertEqual(result[0][0], result[0][1])

        # Test update
        sql = "UPDATE pgmetadata.dataset SET title = 'test raster title' WHERE table_name = 'raster'"
        self._sql(sql)
        sql = "SELECT title, geometry_type, projection_authid, spatial_extent FROM pgmetadata.dataset"
        result = self._sql(sql)
        self.assertEqual(
            ['test raster title', 'RASTER', 'EPSG:25833', '300000, 300800, 5700000, 5700800'],
            result[0]
        )

        # Test date, creation_date is not equal to update_date
        sql = "SELECT creation_date, update_date FROM pgmetadata.dataset"
        result = self._sql(sql)
        self.assertNotEqual(result[0][0], result[0][1])

    def test_trigger_calculate_fields_when_removing_rast(self):
        """ Test the trigger on an existing raster table where we remove the geometry. """

        # Adding data
        dataset_feature = {
            'table_name': "'raster'",
            'schema_name': "'pgmetadata'",
            'title': "'Test title'",
            'abstract': "'Test abstract.'",
        }
        self._insert(dataset_feature, 'dataset')

        # Test with removing the rast column
        sql = "ALTER TABLE pgmetadata.raster DROP COLUMN rast"
        self._sql(sql)
        sql = "UPDATE pgmetadata.dataset SET title = 'test after drop rast column'"
        self._sql(sql)
        sql = "SELECT title, geometry_type, projection_authid, spatial_extent, geom FROM pgmetadata.dataset"
        result = self._sql(sql)
        self.assertEqual(['test after drop rast column', NULL, NULL, NULL, NULL], result[0])
