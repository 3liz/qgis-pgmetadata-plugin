"""Base class for tests using a database."""

import time

from qgis import processing
from qgis.core import (
    QgsAbstractDatabaseProviderConnection,
    QgsApplication,
    QgsDataSourceUri,
    QgsFeature,
    QgsProviderRegistry,
    QgsVectorLayer,
    QgsVectorLayerExporter,
    edit,
)

from pg_metadata.processing.provider import (
    PgMetadataProvider as ProcessingProvider,
)
from pg_metadata.qgis_plugin_tools.tools.logger_processing import (
    LoggerProcessingFeedBack,
)
from pg_metadata.qgis_plugin_tools.tools.resources import plugin_test_data_path
from pg_metadata.test.base import BaseTestProcessing

__copyright__ = "Copyright 2020, 3Liz"
__license__ = "GPL version 3"
__email__ = "info@3liz.org"

SCHEMA = "pgmetadata"


class DatabaseTestCase(BaseTestProcessing):

    """Base class for tests using a database with data."""

    def setUp(self) -> None:
        self.provider = None
        self.metadata = QgsProviderRegistry.instance().providerMetadata('postgres')

        self.connection = self.metadata.findConnection('test_database')
        self.connection: QgsAbstractDatabaseProviderConnection
        if SCHEMA in self.connection.schemas():
            self.connection.dropSchema(SCHEMA, True)
        self.feedback = LoggerProcessingFeedBack()

        self.provider = ProcessingProvider()
        QgsApplication.processingRegistry().addProvider(self.provider)

        self.feedback = LoggerProcessingFeedBack()

        params = {
            "CONNECTION_NAME": "test_database",
            "OVERRIDE": True,
        }
        processing.run(
            "{}:create_database_structure".format(self.provider.id()), params, feedback=None,
        )

        # Insert a layer with vector geometry
        layer = QgsVectorLayer(plugin_test_data_path('lines.geojson'), 'lines', 'ogr')

        uri = QgsDataSourceUri(self.connection.uri())
        uri.setSchema(SCHEMA)
        uri.setTable(layer.name())
        uri.setGeometryColumn('geom')

        result = QgsVectorLayerExporter.exportLayer(
            layer,
            uri.uri(),
            'postgres',
            layer.crs(),
            False)
        if result[0] != 0:
            raise Exception('Layer exported did not work')

        # Insert a layer with raster geometry
        with open(plugin_test_data_path('raster.sql')) as f:
            for line in f:
                self.connection.executeSql(line)

        # Insert a layer without geometry
        layer = QgsVectorLayer(
            'None?field=id:integer&field=name:string(20)&index=yes', 'tabular', 'memory')
        uri = QgsDataSourceUri(self.connection.uri())
        uri.setSchema(SCHEMA)
        uri.setTable(layer.name())

        with edit(layer):
            feature = QgsFeature()
            feature.setAttributes([0, 'A feature'])
            layer.addFeature(feature)

        result = QgsVectorLayerExporter.exportLayer(
            layer,
            uri.uri(),
            'postgres',
            layer.crs(),
            False)
        if result[0] != 0:
            raise Exception('Layer exported did not work')

        for table_name in ['tabular', 'lines', 'raster']:
            # When QGIS >= 3.12, use table()
            table = [t for t in self.connection.tables(SCHEMA) if t.tableName() == table_name]
            self.assertEqual(len(table), 1)
            self.assertIsInstance(table[0], QgsAbstractDatabaseProviderConnection.TableProperty)

        super().setUp()

    def tearDown(self) -> None:
        time.sleep(1)
        super().tearDown()
