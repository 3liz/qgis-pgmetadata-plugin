__copyright__ = 'Copyright 2020, 3Liz'
__license__ = 'GPL version 3'
__email__ = 'info@3liz.org'

from qgis.core import (
    QgsAbstractDatabaseProviderConnection,
    QgsProcessingFeedback,
    QgsProviderConnectionException,
)

from pg_metadata.qgis_plugin_tools.tools.algorithm_processing import (
    BaseProcessingAlgorithm,
)
from pg_metadata.qgis_plugin_tools.tools.i18n import tr


class BaseDatabaseAlgorithm(BaseProcessingAlgorithm):

    def group(self):
        return tr('Database')

    def groupId(self):
        return 'database'

    @staticmethod
    def vacuum_all_tables(
            connection: QgsAbstractDatabaseProviderConnection, feedback: QgsProcessingFeedback):
        """ Execute a vacuum to recompute the feature count. """
        for table in connection.tables('pgmetadata'):

            sql = 'VACUUM ANALYSE {}.{};'.format('pgmetadata', table.tableName())
            feedback.pushDebugInfo(sql)
            try:
                connection.executeSql(sql)
            except QgsProviderConnectionException as e:
                feedback.reportError(str(e))
