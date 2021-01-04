from qgis.PyQt.QtCore import NULL

from pg_metadata.test.base_database import DatabaseTestCase


class TestSql(DatabaseTestCase):

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
        }
        return_value = self._insert(dataset_feature, 'dataset', 'id')
        link_feature = {
            'name': "'test link'",
            'type': "'file'",
            'url': "'https://metadata.is.good'",
            'description': "''",
            'size': "0.5",
            'fk_id_dataset': "{}".format(return_value[0][0]),
        }
        self._insert(link_feature, 'link')

        # Remove previous template to have a smaller one
        sql = "DELETE FROM pgmetadata.html_template WHERE section IN ('main', 'link');"
        self._sql(sql)

        html_feature = {
            'section': "'main'",
            'content': (
                "'<p>[% \"title\" %]</p><b>[%\"abstract\"%]</b><p>[% meta_links %]</p>"
                "<p>[%\"themes\"%]</p>'"
            ),
        }
        self._insert(html_feature, 'html_template')
        html_feature = {
            'section': "'link'",
            'content': "'<p>[% \"name\" %] [% \"description\" %]</p><p>[% \"size\" %]</p>'",
        }
        self._insert(html_feature, 'html_template')

        result = (
            self._sql("SELECT pgmetadata.get_dataset_item_html_content('pgmetadata','lines')")
        )
        expected = (
            '<p>Test title</p><b>Test abstract.</b><p>\n'
            '            <p>test link </p><p>1</p></p><p>New test theme, test theme</p>'
        )
        self.assertEqual(expected, result[0][0])

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
        result = self._sql(sql)
        self.assertEqual(['LINESTRING', 'EPSG:4326', '3.854, 3.897, 43.5786, 43.622'], result[0])

        # Test update
        sql = "UPDATE pgmetadata.dataset SET title = 'test lines title' WHERE table_name = 'lines'"
        self._sql(sql)
        sql = "SELECT title, geometry_type, projection_authid, spatial_extent FROM pgmetadata.dataset"
        result = self._sql(sql)
        self.assertEqual(
            ['test lines title', 'LINESTRING', 'EPSG:4326', '3.854, 3.897, 43.5786, 43.622'],
            result[0]
        )

    def test_trigger_calculate_fields_when_removing_geom(self):
        """ Test the trigger on an existing table where we remove the geometry. """

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
