__copyright__ = "Copyright 2020, 3Liz"
__license__ = "GPL version 3"
__email__ = "info@3liz.org"
__revision__ = "$Format:%H$"

from qgis.core import (
    QgsProcessingParameterString,
    QgsProcessingParameterFileDestination,
    QgsProcessingOutputString,
    QgsProcessingOutputNumber,
)

from pg_metadata.qgis_plugin_tools.tools.i18n import tr
from pg_metadata.qgis_plugin_tools.tools.algorithm_processing import BaseProcessingAlgorithm

from pg_metadata.processing.tools import (
    createAdministrationProjectFromTemplate,
)


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
            'to create the needed metadata by using QGIS editing capabilities'
            '\n'
            '\n'
            '* PostgreSQL connection to the database: name of the connection to use for the new QGIS project.'
            '\n'
            '* QGIS project file to create: choose the output file destination.'
        )
        return short_help

    def initAlgorithm(self, config):
        # INPUTS

        # connection name
        db_param = QgsProcessingParameterString(
            self.CONNECTION_NAME,
            tr('PostgreSQL connection to G-Obs database'),
            defaultValue='',
            optional=False
        )
        db_param.setMetadata({
            'widget_wrapper': {
                'class': 'processing.gui.wrappers_postgis.ConnectionWidgetWrapper'
            }
        })
        self.addParameter(db_param)

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

        # OUTPUTS
        # Add output for status (integer)
        self.addOutput(
            QgsProcessingOutputNumber(
                self.OUTPUT_STATUS,
                tr('Output status')
            )
        )
        # Add output for message
        self.addOutput(
            QgsProcessingOutputString(
                self.OUTPUT_STRING,
                tr('Output message')
            )
        )

    def checkParameterValues(self, parameters, context):

        # Check if the target project file ends with qgs
        project_file = self.parameterAsString(parameters, self.PROJECT_FILE, context)
        if not project_file.endswith('.qgs'):
            return False, tr('The QGIS project file name must end with extension ".qgs"')

        return super(CreateAdministrationProject, self).checkParameterValues(parameters, context)

    def processAlgorithm(self, parameters, context, feedback):

        # Database connection parameters
        connection_name = parameters[self.CONNECTION_NAME]

        # Write the file out again
        project_file = self.parameterAsString(parameters, self.PROJECT_FILE, context)
        createAdministrationProjectFromTemplate(
            connection_name,
            project_file
        )

        msg = tr('QGIS Administration project has been successfully created from database connection')
        msg += ': {}'.format(connection_name)
        feedback.pushInfo(msg)
        status = 1

        return {
            self.OUTPUT_STATUS: status,
            self.OUTPUT_STRING: msg
        }
