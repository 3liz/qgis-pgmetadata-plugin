__copyright__ = "Copyright 2020, 3Liz"
__license__ = "GPL version 3"
__email__ = "info@3liz.org"

from qgis.core import (
    Qgis,
    QgsDataSourceUri,
    QgsExpressionContextUtils,
    QgsLocatorFilter,
    QgsLocatorResult,
    QgsProject,
    QgsProviderRegistry,
    QgsProviderConnectionException,
    QgsVectorLayer,
)
from qgis.PyQt.QtGui import QIcon

from pg_metadata.qgis_plugin_tools.tools.i18n import tr
from pg_metadata.qgis_plugin_tools.tools.resources import resources_path

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

        connection_name = QgsExpressionContextUtils.globalScope().variable(
            "{}_connection_name".format(SCHEMA)
        )
        if not connection_name:
            self.logMessage(
                tr(
                    "One algorithm from PgMetadata must be used before. The plugin will be aware about the "
                    "database to use."
                ),
                Qgis.Critical
            )

        connection = self.metadata.findConnection(connection_name)
        if not connection:
            self.logMessage(
                tr("The global variable {}_connection_name is not correct.").format(SCHEMA),
                Qgis.Critical
            )

        # Search items from pgmetadata.dataset
        sql = " SELECT concat(title, ' (', table_name, '.', schema_name, ')') AS displayString,"
        sql += " schema_name, table_name"
        sql += " FROM pgmetadata.dataset"
        sql += " WHERE concat(title, ' ', abstract, ' ', table_name) ILIKE '%{}%'".format(search)
        sql += " LIMIT 100"

        self.logMessage(sql, Qgis.Critical)

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
            result.displayString = '{}'.format(item[0])
            result.icon = QIcon(resources_path('icons', 'icon.png'))
            result.userData = {
                'name': item[0],
                'connection': connection_name,
                'schema': item[1],
                'table': item[2],
            }
            self.resultFetched.emit(result)

    def triggerResult(self, result):

        metadata = QgsProviderRegistry.instance().providerMetadata('postgres')
        connection = metadata.findConnection(result.userData['connection'])

        uri = QgsDataSourceUri(connection.uri())
        uri.setSchema(result.userData['schema'])
        uri.setTable(result.userData['table'])

        sql = (
            "SELECT f_geometry_column "
            "FROM public.geometry_columns "
            "WHERE f_table_catalog = '{db}' "
            "AND f_table_schema = '{schema}' "
            "AND f_table_name = '{table}';"
        ).format(db=uri.database(), schema=uri.schema(), table=uri.table())
        data = connection.executeSql(sql)
        if data:
            uri.setGeometryColumn(data[0][0])

        layer = QgsVectorLayer(uri.uri(), result.userData['name'], 'postgres')
        QgsProject.instance().addMapLayer(layer)

        self.iface.messageBar().pushSuccess(
            "PgMetadata",
            "Layer {} has been loaded.".format(result.displayString),
        )
