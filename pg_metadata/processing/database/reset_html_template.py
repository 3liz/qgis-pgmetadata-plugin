__copyright__ = "Copyright 2020, 3Liz"
__license__ = "GPL version 3"
__email__ = "info@3liz.org"
__revision__ = "$Format:%H$"


from qgis.core import (
    Qgis,
    QgsProcessingException,
    QgsProcessingParameterBoolean,
    QgsProcessingParameterString,
    QgsProviderConnectionException,
    QgsProviderRegistry,
)

if Qgis.QGIS_VERSION_INT >= 31400:
    from qgis.core import QgsProcessingParameterProviderConnection

from pg_metadata.connection_manager import add_connection, connections_list
from pg_metadata.processing.database.base import BaseDatabaseAlgorithm
from pg_metadata.qgis_plugin_tools.tools.i18n import tr
from pg_metadata.qgis_plugin_tools.tools.resources import resources_path

SCHEMA = 'pgmetadata'


class ResetHtmlTemplate(BaseDatabaseAlgorithm):
    """
    Reset HTML templates which are in the database.
    """

    CONNECTION_NAME = "CONNECTION_NAME"
    RESET = "RESET"

    def name(self):
        return "reset_html_templates"

    def displayName(self):
        return tr("Reset HTML templates in the database")

    def shortHelpString(self):
        msg = tr("Reset HTML templates in the database")
        msg += '\n\n'
        msg += "It will erase and/or create the schema '{}'.".format(SCHEMA)
        msg += '\n\n'
        msg += self.parameters_help_string()
        return msg

    def initAlgorithm(self, config):
        connections, _ = connections_list()
        if connections:
            connection_name = connections[0]
        else:
            connection_name = ''

        label = tr("Connection to the PostgreSQL database")
        tooltip = tr("The database where the schema '{}' has been installed.").format(SCHEMA)
        if Qgis.QGIS_VERSION_INT >= 31400:
            param = QgsProcessingParameterProviderConnection(
                self.CONNECTION_NAME,
                label,
                "postgres",
                defaultValue=connection_name,
                optional=False,
            )
        else:
            param = QgsProcessingParameterString(
                self.CONNECTION_NAME,
                label,
                defaultValue=connection_name,
                optional=False,
            )
            param.setMetadata(
                {
                    "widget_wrapper": {
                        "class": "processing.gui.wrappers_postgis.ConnectionWidgetWrapper"
                    }
                }
            )
        if Qgis.QGIS_VERSION_INT >= 31600:
            param.setHelp(tooltip)
        else:
            param.tooltip_3liz = tooltip
        self.addParameter(param)

        param = QgsProcessingParameterBoolean(
            self.RESET,
            tr("Reset HTML templates"),
            defaultValue=False,
        )
        tooltip = tr("** Be careful ** This will reset existing HTML templates !")
        if Qgis.QGIS_VERSION_INT >= 31600:
            param.setHelp(tooltip)
        else:
            param.tooltip_3liz = tooltip
        self.addParameter(param)

    def checkParameterValues(self, parameters, context):
        if Qgis.QGIS_VERSION_INT >= 31400:
            connection_name = self.parameterAsConnectionName(
                parameters, self.CONNECTION_NAME, context)
        else:
            connection_name = self.parameterAsString(
                parameters, self.CONNECTION_NAME, context)

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
        if Qgis.QGIS_VERSION_INT >= 31400:
            connection_name = self.parameterAsConnectionName(
                parameters, self.CONNECTION_NAME, context)
        else:
            connection_name = self.parameterAsString(
                parameters, self.CONNECTION_NAME, context)

        connection = metadata.findConnection(connection_name)
        if not connection:
            raise QgsProcessingException(tr("The connection {} does not exist.").format(connection_name))

        for template in ["contact", "link", "main"]:
            feedback.pushInfo(tr('Reset {}.html').format(template))

            sql = (
                "DELETE FROM pgmetadata.html_template "
                "WHERE section = '{}'").format(template)
            try:
                connection.executeSql(sql)
            except QgsProviderConnectionException as e:
                feedback.reportError(str(e))

            html_file = resources_path("html", "{}.html".format(template))
            with open(html_file, "r") as f:
                sql = (
                    "INSERT INTO pgmetadata.html_template (section, content) "
                    "VALUES ('{section}', '{value}');".format(section=template, value=f.read())
                )
            try:
                connection.executeSql(sql)
            except QgsProviderConnectionException as e:
                feedback.reportError(str(e))

        add_connection(connection_name)

        results = {}
        return results
