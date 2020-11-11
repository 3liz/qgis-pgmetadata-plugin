__copyright__ = "Copyright 2020, 3Liz"
__license__ = "GPL version 3"
__email__ = "info@3liz.org"

from qgis.core import (
    Qgis,
    QgsDataSourceUri,
    QgsLocatorFilter,
    QgsLocatorResult,
    QgsProject,
    QgsProviderConnectionException,
    QgsProviderRegistry,
    QgsSettings,
    QgsVectorLayer,
)
from qgis.PyQt.QtWidgets import QDockWidget

from pg_metadata.connection_manager import (
    check_pgmetadata_is_installed,
    connections_list,
)
from pg_metadata.qgis_plugin_tools.tools.i18n import tr
from pg_metadata.tools import icon_for_geometry_type

SCHEMA = 'pgmetadata'


class LocatorFilter(QgsLocatorFilter):

    def __init__(self, iface):
        self.iface = iface
        self.metadata = QgsProviderRegistry.instance().providerMetadata('postgres')
        super(QgsLocatorFilter, self).__init__()

    def name(self):
        return self.__class__.__name__

    def clone(self):
        return LocatorFilter(self.iface)

    def displayName(self):
        return 'PgMetadata'

    def prefix(self):
        return 'meta'

    def fetchResults(self, search, context, feedback):

        if len(search) < 3:
            # Let's limit the number of request sent to the server
            return

        connections, message = connections_list()
        if not connections:
            self.logMessage(message, Qgis.Critical)

        for connection in connections:

            if not check_pgmetadata_is_installed(connection):
                self.logMessage(tr('PgMetadata is not installed on {}').format(connection), Qgis.Critical)
                continue

            self.fetch_result_single_database(search, connection)

    def fetch_result_single_database(self, search: str, connection_name: str):
        """ Fetch tables in the given database for a search. """
        connection = self.metadata.findConnection(connection_name)
        if not connection:
            self.logMessage(
                tr("The global variable {}_connection_name is not correct.").format(SCHEMA),
                Qgis.Critical
            )

        # Search items from pgmetadata.dataset
        sql = " SELECT concat(title, ' (', table_name, '.', schema_name, ')') AS displayString,"
        sql += " schema_name, table_name, geometry_type, title"
        sql += " FROM pgmetadata.dataset"
        sql += " WHERE concat(title, ' ', abstract, ' ', table_name) ILIKE '%{}%'".format(search)
        sql += " LIMIT 100"

        try:
            data = connection.executeSql(sql)
        except QgsProviderConnectionException as e:
            self.logMessage(str(e), Qgis.Critical)
            return

        if not data:
            return

        for item in data:
            result = QgsLocatorResult()
            result.filter = self
            result.displayString = item[0]
            result.icon = icon_for_geometry_type(item[3])
            result.userData = {
                'name': item[4],
                'connection': connection_name,
                'schema': item[1],
                'table': item[2],
            }
            self.resultFetched.emit(result)

    def triggerResult(self, result):

        metadata = QgsProviderRegistry.instance().providerMetadata('postgres')
        connection = metadata.findConnection(result.userData['connection'])

        schema_name = result.userData['schema']
        table_name = result.userData['table']

        if Qgis.QGIS_VERSION_INT < 31200:
            table = [t for t in connection.tables(schema_name) if t.tableName() == table_name][0]
        else:
            table = connection.table(schema_name, table_name)

        uri = QgsDataSourceUri(connection.uri())
        uri.setSchema(schema_name)
        uri.setTable(table_name)
        uri.setGeometryColumn(table.geometryColumn())

        layer = QgsVectorLayer(uri.uri(), result.userData['name'], 'postgres')
        QgsProject.instance().addMapLayer(layer)

        auto_open_dock = QgsSettings().value("pgmetadata/auto_open_dock", True, type=bool)
        if auto_open_dock:
            pgmetadata_dock = self.iface.mainWindow().findChildren(QDockWidget, "pgmetadata_dock")[0]
            pgmetadata_dock.show()
            pgmetadata_dock.raise_()

        self.iface.messageBar().pushSuccess(
            "PgMetadata",
            "Layer {} has been loaded.".format(result.displayString),
        )
