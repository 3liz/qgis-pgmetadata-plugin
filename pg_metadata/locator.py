__copyright__ = "Copyright 2020, 3Liz"
__license__ = "GPL version 3"
__email__ = "info@3liz.org"

from qgis.core import (
    QgsLocatorFilter,
    QgsLocatorResult,
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

    def fetchResults(self, search, context, feedback):

        if len(search) < 3:
            # Let's limit the number of request sent to the server
            return

        result = QgsLocatorResult()
        result.filter = self
        result.displayString = 'Result {}'.format(search)
        result.userData = 'Result {}'.format(search)
        self.resultFetched.emit(result)

    def triggerResult(self, result):
        self.iface.messageBar().pushWarning(
            "PgMetadata",
            "User clicked: {}".format(result.displayString))
