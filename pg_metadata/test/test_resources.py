__copyright__ = 'Copyright 2020, 3Liz'
__license__ = 'GPL version 3'
__email__ = 'info@3liz.org'

import configparser

from qgis.testing import unittest

from pg_metadata.qgis_plugin_tools.tools.resources import (
    plugin_path,
    resources_path,
)


class TestResources(unittest.TestCase):

    def test_qgis_version(self):
        """ Test QGIS versions are correct in metadata and provided QGIS version. """
        expected_qgis_version = "3.10"

        # Test the QGIS project
        qgis_project = resources_path('projects', 'pg_metadata_administration.qgs')
        with open(qgis_project, encoding='utf8') as f:
            first_line = f.readline()
            self.assertTrue(
                'version="{}'.format(expected_qgis_version) in first_line, 'The QGIS project is wrong.')

        # Test the minimum version to match the project
        config = configparser.ConfigParser()
        config.read(plugin_path('metadata.txt'))
        self.assertEqual(
            config["general"]["qgisMinimumVersion"], expected_qgis_version, 'The metadata.txt is wrong')
