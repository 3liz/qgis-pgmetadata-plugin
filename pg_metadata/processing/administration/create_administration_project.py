__copyright__ = "Copyright 2020, 3Liz"
__license__ = "GPL version 3"
__email__ = "info@3liz.org"
__revision__ = "$Format:%H$"

from qgis.core import (
    QgsProcessingParameterFileDestination,
    QgsProcessingParameterProviderConnection,
    QgsProviderRegistry,
)

from pg_metadata.connection_manager import add_connection, connections_list
from pg_metadata.qgis_plugin_tools.tools.algorithm_processing import (
    BaseProcessingAlgorithm,
)
from pg_metadata.qgis_plugin_tools.tools.i18n import tr
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
        return 'administration'

    def shortHelpString(self):
        short_help = tr(
            'This algorithm will create a new QGIS project file for PgMetadata administration purpose.')
        short_help += '\n\n'
        short_help += tr(
            'The generated QGIS project must then be opened by the administrator '
            'to create the needed metadata by using QGIS editing capabilities.')
        short_help += '\n\n'
        short_help += self.parameters_help_string()
        return short_help

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
        param.setHelp(tr("The database where the schema '{}' is installed.").format(SCHEMA))
        self.addParameter(param)

        # target project file
        param = QgsProcessingParameterFileDestination(
            self.PROJECT_FILE,
            tr('QGIS project file to create'),
            defaultValue='',
            optional=False,
            fileFilter='QGS project (*.qgs)',
        )
        param.setHelp(tr("The destination file where to create the QGIS project.").format(SCHEMA))
        self.addParameter(param)

    def checkParameterValues(self, parameters, context):

        # Check if the target project file ends with qgs
        project_file = self.parameterAsString(parameters, self.PROJECT_FILE, context)
        if not project_file.endswith('.qgs'):
            return False, tr('The QGIS project file name must end with extension ".qgs"')

        return super().checkParameterValues(parameters, context)

    def processAlgorithm(self, parameters, context, feedback):

        connection_name = self.parameterAsConnectionName(parameters, self.CONNECTION_NAME, context)

        # Write the file out again
        project_file = self.parameterAsString(parameters, self.PROJECT_FILE, context)

        metadata = QgsProviderRegistry.instance().providerMetadata('postgres')
        connection = metadata.findConnection(connection_name)

        # Read in the template file
        template_file = resources_path('projects', 'pg_metadata_administration.qgs')
        with open(template_file, 'r', encoding='utf8') as fin:
            file_data = fin.read()

        # Replace the database connection information
        file_data = file_data.replace("service='pgmetadata'", connection.uri())

        with open(project_file, 'w', encoding='utf8') as fout:
            fout.write(file_data)

        add_connection(connection_name)

        msg = tr('QGIS Administration project has been successfully created from the database connection')
        msg += ': {}'.format(connection_name)
        feedback.pushInfo(msg)

        return {}
