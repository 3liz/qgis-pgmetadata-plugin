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
        os.environ['QGIS_PGMETADATA_END_USER_ONLY'] = 'yes'
        registry = QgsApplication.processingRegistry()
        provider = Provider()
        provider.id = lambda: 'fake_pgmetadata_id_user'
        registry.addProvider(provider)
        self.assertEqual(1, len(provider.algorithms()))
        QgsApplication.processingRegistry().removeProvider(provider)
        del os.environ['QGIS_PGMETADATA_END_USER_ONLY']

    def test_as_admin(self):
        """ Test Processing provider as an admin. """
        registry = QgsApplication.processingRegistry()
        provider = Provider()
        provider.id = lambda: 'fake_pgmetadata_id_admin'
        registry.addProvider(provider)
        self.assertEqual(6, len(provider.algorithms()))
