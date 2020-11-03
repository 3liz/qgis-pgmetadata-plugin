__copyright__ = 'Copyright 2020, 3Liz'
__license__ = 'GPL version 3'
__email__ = 'info@3liz.org'

import os

from qgis.core import QgsApplication
from qgis.testing import unittest

from pg_metadata.processing.provider import PgMetadataProvider as Provider


class TestUserVersusAdmin(unittest.TestCase):

    def test_as_user(self):
        """ Test Processing provider as a user. """
        os.environ['PGMETADATA_USER'] = 'yes'
        registry = QgsApplication.processingRegistry()
        provider = Provider()
        provider.id = lambda: 'fake_pgmetadata_id_user'
        registry.addProvider(provider)
        self.assertEqual(0, len(provider.algorithms()))
        QgsApplication.processingRegistry().removeProvider(provider)
        del os.environ['PGMETADATA_USER']

    def test_as_admin(self):
        """ Test Processing provider as an admin. """
        registry = QgsApplication.processingRegistry()
        provider = Provider()
        provider.id = lambda: 'fake_pgmetadata_id_admin'
        registry.addProvider(provider)
        self.assertEqual(4, len(provider.algorithms()))
