__copyright__ = "Copyright 2020, 3Liz"
__license__ = "GPL version 3"
__email__ = "info@3liz.org"

import os

from qgis.core import QgsProcessingProvider, QgsSettings
from qgis.PyQt.QtGui import QIcon

from pg_metadata.processing.administration.create_administration_project import (
    CreateAdministrationProject,
)
from pg_metadata.processing.administration.set_connections import (
    SetConnectionDatabase,
)
from pg_metadata.processing.database.create import CreateDatabaseStructure
from pg_metadata.processing.database.recompute_values import RecomputeValues
from pg_metadata.processing.database.reset_html_template import (
    ResetHtmlTemplate,
)
from pg_metadata.processing.database.upgrade import UpgradeDatabaseStructure
from pg_metadata.qgis_plugin_tools.tools.resources import resources_path


class PgMetadataProvider(QgsProcessingProvider):

    def loadAlgorithms(self):

        self.addAlgorithm(SetConnectionDatabase())

        environment = os.environ.get('QGIS_PGMETADATA_END_USER_ONLY', False)
        ini_file = QgsSettings().value("pgmetadata/end_user_only", False, type=bool)
        if environment or ini_file:
            return

        # Admin
        self.addAlgorithm(CreateAdministrationProject())

        # Database
        self.addAlgorithm(CreateDatabaseStructure())
        self.addAlgorithm(RecomputeValues())
        self.addAlgorithm(ResetHtmlTemplate())
        self.addAlgorithm(UpgradeDatabaseStructure())

    def id(self):  # NOQA
        return "pg_metadata"

    def icon(self):
        return QIcon(resources_path("icons", "icon.png"))

    def name(self):
        return "PgMetadata"
