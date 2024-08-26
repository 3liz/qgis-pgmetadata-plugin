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
        expected_qgis_version = "3.22"

        # Test the QGIS project
        qgis_project = resources_path('projects', 'pg_metadata_administration.qgs')
        with open(qgis_project, encoding='utf8') as f:
            first_line = f.readline()
            self.assertTrue(
                f'version="{expected_qgis_version}' in first_line,
                f'The QGIS project is wrong, {expected_qgis_version} not found in {first_line}.'
            )

        # Test the minimum version to match the project
        config = configparser.ConfigParser()
        config.read(plugin_path('metadata.txt'))
        self.assertEqual(
            expected_qgis_version,
            config["general"]["qgisMinimumVersion"],
            f'The metadata.txt is wrong, {expected_qgis_version} not found in '
            f'{config["general"]["qgisMinimumVersion"]}'
        )
