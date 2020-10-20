"""Base class for tests using a database."""

import time

from qgis import processing
from qgis.core import (
    QgsApplication,
    QgsAbstractDatabaseProviderConnection,
    QgsDataSourceUri,
    QgsProviderRegistry,
    QgsVectorLayer,
    QgsVectorLayerExporter,
)

from pg_metadata.qgis_plugin_tools.tools.logger_processing import LoggerProcessingFeedBack
from pg_metadata.qgis_plugin_tools.tools.resources import plugin_test_data_path
from pg_metadata.processing.provider import PgMetadataProvider as ProcessingProvider
from pg_metadata.test.base import BaseTestProcessing

__copyright__ = "Copyright 2020, 3Liz"
__license__ = "GPL version 3"
__email__ = "info@3liz.org"
__revision__ = "$Format:%H$"

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

        super().setUp()

    def tearDown(self) -> None:
        time.sleep(1)
        super().tearDown()
