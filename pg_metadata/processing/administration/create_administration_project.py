__copyright__ = "Copyright 2020, 3Liz"
__license__ = "GPL version 3"
__email__ = "info@3liz.org"
__revision__ = "$Format:%H$"

from qgis.core import (
    Qgis,
    QgsExpressionContextUtils,
    QgsProcessingParameterString,
    QgsProcessingParameterFileDestination,
    QgsProviderRegistry,
)
if Qgis.QGIS_VERSION_INT >= 31400:
    from qgis.core import QgsProcessingParameterProviderConnection

from pg_metadata.qgis_plugin_tools.tools.i18n import tr
from pg_metadata.qgis_plugin_tools.tools.algorithm_processing import BaseProcessingAlgorithm
from pg_metadata.qgis_plugin_tools.tools.resources import resources_path


SCHEMA = 'pgmetadata'


class CreateAdministrationProject(BaseProcessingAlgorithm):

    CONNECTION_NAME = 'CONNECTION_NAME'
    PROJECT_FILE = 'PROJECT_FILE'

    OUTPUT_STATUS = 'OUTPUT_STATUS'
    OUTPUT_STRING = 'OUTPUT_STRING'

    def name(self):
        return 'create_administration_project'

    def displayName(self):
        return tr('Create metadata administration project')

    def group(self):
        return tr('Administration')

    def groupId(self):
        return 'pg_metadata_administration'

    def shortHelpString(self):
        short_help = tr(
            'This algorithm will create a new QGIS project file for PgMetadata administration purpose.'
            '\n'
            '\n'
            'The generated QGIS project must then be opened by the administrator '
            'to create the needed metadata by using QGIS editing capabilities.'
            '\n'
            '\n'
            '* PostgreSQL connection to the database: name of the connection to use for the new QGIS project.'
            '\n'
            '* QGIS project file to create: choose the output file destination.'
        )
        return short_help

    def initAlgorithm(self, config):
        connection_name = QgsExpressionContextUtils.globalScope().variable(
            "{}_connection_name".format(SCHEMA)
        )
        label = tr("Connexion to the PostgreSQL database")
        tooltip = label
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

        # target project file
        self.addParameter(
            QgsProcessingParameterFileDestination(
                self.PROJECT_FILE,
                tr('QGIS project file to create'),
                defaultValue='',
                optional=False,
                fileFilter='qgs'
            )
        )

    def checkParameterValues(self, parameters, context):

        # Check if the target project file ends with qgs
        project_file = self.parameterAsString(parameters, self.PROJECT_FILE, context)
        if not project_file.endswith('.qgs'):
            return False, tr('The QGIS project file name must end with extension ".qgs"')

        return super().checkParameterValues(parameters, context)

    def processAlgorithm(self, parameters, context, feedback):

        if Qgis.QGIS_VERSION_INT >= 31400:
            connection_name = self.parameterAsConnectionName(
                parameters, self.CONNECTION_NAME, context)
        else:
            connection_name = self.parameterAsString(
                parameters, self.CONNECTION_NAME, context)

        # Write the file out again
        project_file = self.parameterAsString(parameters, self.PROJECT_FILE, context)

        metadata = QgsProviderRegistry.instance().providerMetadata('postgres')
        connection = metadata.findConnection(connection_name)

        # Read in the template file
        template_file = resources_path('projects', 'pg_metadata_administration.qgs')
        with open(template_file, 'r') as fin:
            file_data = fin.read()

        # Replace the database connection information
        file_data = file_data.replace(
            "service='pgmetadata'",
            connection.uri()
        )

        with open(project_file, 'w') as fout:
            fout.write(file_data)

        msg = tr('QGIS Administration project has been successfully created from database connection')
        msg += ': {}'.format(connection_name)
        feedback.pushInfo(msg)

        return {}
