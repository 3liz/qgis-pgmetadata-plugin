__copyright__ = 'Copyright 2020, 3Liz'
__license__ = 'GPL version 3'
__email__ = 'info@3liz.org'

import tempfile

import processing

from pg_metadata.qgis_plugin_tools.tools.resources import resources_path
from pg_metadata.test.base import BaseTestProcessing


class TestProcessing(BaseTestProcessing):

    def test_generating_admin_project(self):
        """ Test generating the QGIS admin project. """

        template_file = resources_path('projects', 'pg_metadata_administration.qgs')
        with open(template_file, 'r') as fin:
            file_data = fin.read()

        self.assertGreater(file_data.count("estimatedmetadata=true"), 20)

        self.assertIn("service='pgmetadata'", file_data)
        self.assertNotIn("host=db", file_data)

        temp = tempfile.NamedTemporaryFile(suffix='.qgs')
        qgs_file = temp.name
        temp.close()

        params = {
            'CONNECTION_NAME': 'test_database',
            'PROJECT_FILE': qgs_file,
        }
        processing.run("pg_metadata:create_administration_project", params)

        with open(qgs_file, 'r') as fin:
            file_data = fin.read()

        self.assertNotIn("service='pgmetadata'", file_data)
        self.assertIn("host=db", file_data)
