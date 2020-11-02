from qgis.PyQt.QtCore import NULL

from pg_metadata.test.base_database import DatabaseTestCase


class TestSql(DatabaseTestCase):

    def _insert(self, feature_map, table='dataset'):
        fields = []
        values = []
        for f, v in feature_map.items():
            fields.append(f)
            values.append(v)
        sql = 'INSERT INTO pgmetadata.{table} ({fields}) VALUES ({values});'.format(
            table=table,
            fields=','.join(fields),
            values=','.join(values))
        self.connection.executeSql(sql)

    def test_html_template(self):
        """ Test HTML template. """
        dataset_feature = {
            'table_name': "'lines'",
            'schema_name': "'pgmetadata'",
            'title': "'Test title'",
            'abstract': "'Test abstract.'",
        }
        self._insert(dataset_feature, 'dataset')

        html_feature = {
            'section': "'main'",
            'content': "'<p>[% \"title\" %]</p><b>[%\"abstract\"%]</b>'",
        }
        self._insert(html_feature, 'html_template')

        result = (
            self.connection.executeSql(
                "SELECT pgmetadata.get_dataset_item_html_content('pgmetadata','lines')")
        )
        self.assertEqual("<p>Test title</p><b>Test abstract.</b>", result[0][0])

    def test_trigger_calculate_fields(self):
        """ Test if fields are correctly calculated on a layer having
        a geometry """

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
        result = self.connection.executeSql(sql)
        self.assertEqual(['LINESTRING', 'EPSG:4326', '3.854, 3.897, 43.5786, 43.622'], result[0])

        # Test update
        sql = "UPDATE pgmetadata.dataset SET title = 'test lines title' WHERE table_name = 'lines'"
        self.connection.executeSql(sql)
        sql = "SELECT title, geometry_type, projection_authid, spatial_extent FROM pgmetadata.dataset"
        result = self.connection.executeSql(sql)
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
        self.connection.executeSql(sql)
        sql = "UPDATE pgmetadata.dataset SET title = 'test after drop geom column'"
        self.connection.executeSql(sql)
        sql = "SELECT title, geometry_type, projection_authid, spatial_extent, geom FROM pgmetadata.dataset"
        result = self.connection.executeSql(sql)
        self.assertEqual(['test after drop geom column', NULL, NULL, NULL, NULL], result[0])

    def test_trigger_calculate_fields_without_geom(self):
        """ Test compute fields on a geometry less table. """

        # Test with new table whithout geom column
        sql = "CREATE TABLE pgmetadata.testwithoutgeom (id serial, name text)"
        self.connection.executeSql(sql)
        dataset_feature = {
            'table_name': "'testwithoutgeom'",
            'schema_name': "'pgmetadata'",
            'title': "'Test title'",
            'abstract': "'Test abstract.'",
        }
        self._insert(dataset_feature, 'dataset')
        sql = (
            "SELECT geometry_type, projection_authid, spatial_extent, geom FROM pgmetadata.dataset WHERE"
            " table_name = 'testwithoutgeom'"
        )
        result = self.connection.executeSql(sql)
        self.assertEqual([NULL, NULL, NULL, NULL], result[0])
