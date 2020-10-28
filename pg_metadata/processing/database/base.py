__copyright__ = 'Copyright 2020, 3Liz'
__license__ = 'GPL version 3'
__email__ = 'info@3liz.org'

from pg_metadata.qgis_plugin_tools.tools.algorithm_processing import (
    BaseProcessingAlgorithm,
)
from pg_metadata.qgis_plugin_tools.tools.i18n import tr


class BaseDatabaseAlgorithm(BaseProcessingAlgorithm):

    def group(self):
        return tr('Database')

    def groupId(self):
        return 'databse'
