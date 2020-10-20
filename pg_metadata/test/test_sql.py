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
            'content': "'<p>[% \"title\" %]</p><b>[%\"title\"%]</b>'",
        }
        self._insert(html_feature, 'html_template')

        result = (
            self.connection.executeSql(
                "SELECT pgmetadata.get_dataset_item_html_content('pgmetadata','lines','main')")
        )
        self.assertEqual("<p>Test title</p><b>Test title</b>", result[0][0])
