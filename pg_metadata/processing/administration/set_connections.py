__copyright__ = "Copyright 2020, 3Liz"
__license__ = "GPL version 3"
__email__ = "info@3liz.org"
__revision__ = "$Format:%H$"

from qgis.core import Qgis, QgsProcessingParameterEnum, QgsProviderRegistry

from pg_metadata.connection_manager import (
    add_connection,
    connections_list,
    reset_connections,
)
from pg_metadata.qgis_plugin_tools.tools.algorithm_processing import (
    BaseProcessingAlgorithm,
)
from pg_metadata.qgis_plugin_tools.tools.i18n import tr


class SetConnectionDatabase(BaseProcessingAlgorithm):

    DATABASES = 'DATABASES'

    def name(self):
        return 'set_connections'

    def displayName(self):
        return tr('Set connections to databases')

    def group(self):
        return tr('Administration')

    def groupId(self):
        return 'administration'

    def shortHelpString(self):
        short_help = tr('This algorithm will enable different databases where to look for metadata.')
        short_help += '\n\n'
        short_help += self.parameters_help_string()
        return short_help

    def initAlgorithm(self, config):
        # Get existing connections
        metadata = QgsProviderRegistry.instance().providerMetadata('postgres')
        names = list(metadata.connections().keys())

        existing_connections = []
        for i, name in enumerate(names):
            if name in connections_list()[0]:
                existing_connections.append(i)

        param = QgsProcessingParameterEnum(
            self.DATABASES,
            tr('List of databases to look for metadata'),
            options=names,
            defaultValue=existing_connections,
        )
        param.setAllowMultiple(True)

        tooltip = tr("PgMetadata can be installed on different databases.")
        if Qgis.QGIS_VERSION_INT >= 31600:
            param.setHelp(tooltip)
        else:
            param.tooltip_3liz = tooltip
        self.addParameter(param)

    def processAlgorithm(self, parameters, context, feedback):
        metadata = QgsProviderRegistry.instance().providerMetadata('postgres')
        names = list(metadata.connections().keys())

        databases = self.parameterAsEnums(parameters, self.DATABASES, context)
        database_names = [names[i] for i in databases]

        reset_connections()
        for database in database_names:
            feedback.pushDebugInfo(tr("Setting up : {}").format(database))
            add_connection(database)

        return {}
