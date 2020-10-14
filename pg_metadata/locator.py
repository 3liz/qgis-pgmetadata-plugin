__copyright__ = "Copyright 2020, 3Liz"
__license__ = "GPL version 3"
__email__ = "info@3liz.org"

from qgis.core import (
    QgsLocatorFilter,
    QgsLocatorResult,
    QgsProviderRegistry,
    QgsProviderConnectionException,
)


class LocatorFilter(QgsLocatorFilter):

    def __init__(self, iface):
        self.iface = iface
        super(QgsLocatorFilter, self).__init__()

    def name(self):
        return self.__class__.__name__

    def clone(self):
        return LocatorFilter(self.iface)

    def displayName(self):
        return 'PgMetadata'

    def prefix(self):
        return 'meta'

    @staticmethod
    def query(connection_name, sql):
        """
        Runs a query on PostgreSQL connection and returns data
        """
        metadata = QgsProviderRegistry.instance().providerMetadata('postgres')
        connection = metadata.findConnection(connection_name)
        if not connection:
            return

        try:
            data = connection.executeSql(sql)
        except QgsProviderConnectionException as e:
            msg = str(e)
            print(msg)
            return
        else:
            return data

    def fetchResults(self, search, context, feedback):

        if len(search) < 3:
            # Let's limit the number of request sent to the server
            return

        # Search items from pgmetadata.dataset
        sql = " SELECT concat(title, ' (', table_name, '.', schema_name, ')') AS displayString,"
        sql += " table_name, schema_name"
        sql += " FROM pgmetadata.dataset"
        sql += " WHERE concat(title, ' ', abstract, ' ', table_name) ILIKE '%{}%'".format(search)
        sql += " LIMIT 100"

        data = self.query('pgmetadata', sql)
        if not data:
            return

        for item in data:
            result = QgsLocatorResult()
            result.filter = self
            result.displayString = '{}'.format(item[0])
            result.userData = {
                'schema': item[1],
                'table': item[2],
            }
            self.resultFetched.emit(result)

    def triggerResult(self, result):
        self.iface.messageBar().pushSuccess(
            "PgMetadata",
            "And the winner is: {}".format(result.displayString),
        )
