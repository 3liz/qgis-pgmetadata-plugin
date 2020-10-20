__copyright__ = 'Copyright 2020, 3Liz'
__license__ = 'GPL version 3'
__email__ = 'info@3liz.org'


from qgis.core import (
    QgsApplication,
)
from qgis.PyQt.QtCore import (
    QCoreApplication,
    QSettings,
)
from qgis.testing import unittest
from processing.core.Processing import Processing

from pg_metadata.processing.provider import PgMetadataProvider as Provider


class BaseTestProcessing(unittest.TestCase):

    """ Base test class for Processing. """

    # noinspection PyCallByClass,PyArgumentList
    @classmethod
    def setUpClass(cls):
        """ Run before all tests and set up environment. """
        # Don't mess with actual user settings
        QCoreApplication.setOrganizationName('3Liz')
        QCoreApplication.setOrganizationDomain('3Liz.com')
        QCoreApplication.setApplicationName('PgMetadata')
        QSettings().clear()

        Processing.initialize()

    def setUp(self) -> None:
        registry = QgsApplication.processingRegistry()

        self.provider = Provider()
        if not registry.providerById(self.provider.id()):
            registry.addProvider(self.provider)

    def tearDown(self) -> None:
        if self.provider:
            QgsApplication.processingRegistry().removeProvider(self.provider)
