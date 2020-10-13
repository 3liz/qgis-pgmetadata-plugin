__copyright__ = "Copyright 2020, 3Liz"
__license__ = "GPL version 3"
__email__ = "info@3liz.org"
__revision__ = "$Format:%H$"

from pg_metadata.qgis_plugin_tools.tools.resources import plugin_path
from qgis.core import QgsSettings
from processing.tools.postgis import uri_from_name


def getPostgisConnectionList():
    """Get a list of the PostGIS connection names"""

    s = QgsSettings()
    s.beginGroup("PostgreSQL/connections")
    connections = list(set([a.split('/')[0] for a in s.allKeys()]))
    s.endGroup()

    # In QGIS 3.16, we will use
    # metadata = QgsProviderRegistry.instance().providerMetadata('postgres')
    # find a connection by name
    # postgres_connections = metadata.connections()
    # connections = postgres_connections.keys()

    return connections


def getPostgisConnectionUriFromName(connection_name):
    """
    Return a QgsDatasourceUri from a PostgreSQL connection name
    """

    uri = uri_from_name(connection_name)

    # In QGIS 3.10, we will use
    # metadata = QgsProviderRegistry.instance().providerMetadata('postgres')
    # find a connection by name
    # connection = metadata.findConnection(connection_name)
    # uri_str = connection.uri()
    # uri = QgsDataSourceUri(uri)

    return uri


def createAdministrationProjectFromTemplate(connection_name, project_file_path):
    """
    Creates a new administration project from template
    for the given connection name
    to the given target path
    """
    # Get connection information
    uri = getPostgisConnectionUriFromName(connection_name)
    connection_info = uri.connectionInfo()

    # Read in the template file
    template_file = plugin_path('resources', 'projects', 'pg_metadata_administration.qgs')
    with open(template_file, 'r') as fin:
        filedata = fin.read()

    # Replace the database connection information
    filedata = filedata.replace(
        "service='pgmetadata'",
        connection_info
    )

    with open(project_file_path, 'w') as fout:
        fout.write(filedata)
