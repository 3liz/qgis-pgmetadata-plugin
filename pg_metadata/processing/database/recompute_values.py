__copyright__ = "Copyright 2020, 3Liz"
__license__ = "GPL version 3"
__email__ = "info@3liz.org"
__revision__ = "$Format:%H$"


from qgis.core import (
    QgsProcessingException,
    QgsProcessingParameterBoolean,
    QgsProcessingParameterProviderConnection,
    QgsProviderConnectionException,
    QgsProviderRegistry,
)

from pg_metadata.connection_manager import add_connection, connections_list
from pg_metadata.processing.database.base import BaseDatabaseAlgorithm
from pg_metadata.qgis_plugin_tools.tools.i18n import tr

SCHEMA = 'pgmetadata'


class RecomputeValues(BaseDatabaseAlgorithm):
    """
    Recompute values in the dataset table.
    """

    CONNECTION_NAME = "CONNECTION_NAME"
    RESET = "RESET"

    def name(self):
        return "recompute_values_dataset"

    def displayName(self):
        return tr("Recompute values in the dataset table")

    def shortHelpString(self):
        msg = tr("Recalculate spatial related fields for all dataset item")
        msg += '\n\n'
        msg += self.parameters_help_string()
        return msg

    def initAlgorithm(self, config):
        connections, _ = connections_list()
        if connections:
            connection_name = connections[0]
        else:
            connection_name = ''

        param = QgsProcessingParameterProviderConnection(
            self.CONNECTION_NAME,
            tr("Connection to the PostgreSQL database"),
            "postgres",
            defaultValue=connection_name,
            optional=False,
        )
        param.setHelp(tr("The database where the schema '{}' has been installed.").format(SCHEMA))
        self.addParameter(param)

        param = QgsProcessingParameterBoolean(
            self.RESET,
            tr("Recompute values in the dataset table"),
            defaultValue=False,
        )
        param.setHelp(tr("** Be careful ** This will recompute default values."))
        self.addParameter(param)

    def checkParameterValues(self, parameters, context):
        connection_name = self.parameterAsConnectionName(parameters, self.CONNECTION_NAME, context)

        metadata = QgsProviderRegistry.instance().providerMetadata('postgres')
        connection = metadata.findConnection(connection_name)
        if not connection:
            raise QgsProcessingException(tr("The connection {} does not exist.").format(connection_name))

        reset = self.parameterAsBool(parameters, self.RESET, context)
        if not reset:
            msg = tr("You must use the checkbox to do the reset !")
            return False, msg

        return super().checkParameterValues(parameters, context)

    def processAlgorithm(self, parameters, context, feedback):
        metadata = QgsProviderRegistry.instance().providerMetadata('postgres')
        connection_name = self.parameterAsConnectionName(parameters, self.CONNECTION_NAME, context)

        connection = metadata.findConnection(connection_name)
        if not connection:
            raise QgsProcessingException(tr("The connection {} does not exist.").format(connection_name))

        sql = "SELECT pgmetadata.refresh_dataset_calculated_fields();"
        try:
            connection.executeSql(sql)
        except QgsProviderConnectionException as e:
            feedback.reportError(str(e))

        add_connection(connection_name)

        results = {}
        return results
