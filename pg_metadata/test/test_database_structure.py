"""Tests for Processing algorithms."""

import time

import processing

from qgis.core import (
    QgsAbstractDatabaseProviderConnection,
    QgsApplication,
    QgsProcessingException,
    QgsProviderRegistry,
)
from qgis.testing import unittest

from pg_metadata.processing.provider import PgMetadataProvider as ProcessingProvider
from pg_metadata.qgis_plugin_tools.tools.logger_processing import LoggerProcessingFeedBack

__copyright__ = "Copyright 2020, 3Liz"
__license__ = "GPL version 3"
__email__ = "info@3liz.org"
__revision__ = "$Format:%H$"

SCHEMA = ProcessingProvider.schema()


class TestProcessing(unittest.TestCase):

    def setUp(self) -> None:
        self.metadata = QgsProviderRegistry.instance().providerMetadata('postgres')
        self.connection = self.metadata.findConnection('test_database')
        self.connection: QgsAbstractDatabaseProviderConnection
        if SCHEMA in self.connection.schemas():
            self.connection.dropSchema(SCHEMA, True)
        self.feedback = LoggerProcessingFeedBack()

    def tearDown(self) -> None:
        del self.connection
        time.sleep(1)

    def test_upgrade_without_create(self):
        """ Test to upgrade a not existing database structure. """
        provider = ProcessingProvider()
        registry = QgsApplication.processingRegistry()
        if not registry.providerById(provider.id()):
            registry.addProvider(provider)

        params = {
            "CONNECTION_NAME": "test_database",
            "RUN_MIGRATIONS": True,
        }
        alg = "{}:upgrade_database_structure".format(provider.id())
        with self.assertRaises(QgsProcessingException):
            processing.run(alg, params, feedback=self.feedback)
        self.assertIn(
            "The table pgmetadata.qgis_plugin does not exist. You must first create the database structure.",
            self.feedback.history
        )

    def test_install_database(self):
        """ Test we can install the database. """
        provider = ProcessingProvider()
        registry = QgsApplication.processingRegistry()
        if not registry.providerById(provider.id()):
            registry.addProvider(provider)

        params = {
            "CONNECTION_NAME": "test_database",
            "OVERRIDE": True,
        }
        alg = "{}:create_database_structure".format(provider.id())
        results = processing.run(alg, params, feedback=self.feedback)
        self.assertEqual('0.0.1', results['DATABASE_VERSION'])

        expected = [
            'dataset',
            'link',
            'glossary',
            'qgis_plugin',
            'contact',
            'dataset_contact',
        ]
        tables = self.connection.tables(SCHEMA)
        tables = [t.tableName() for t in tables]
        self.assertCountEqual(expected, tables)

        params = {
            "CONNECTION_NAME": "test_database",
            "OVERRIDE": False,
        }
        with self.assertRaises(QgsProcessingException):
            processing.run(alg, params, feedback=self.feedback)
        self.assertTrue(
            any("If you really want to remove and recreate the schema" in s for s in self.feedback.history))


if __name__ == "__main__":
    unittest.main()
