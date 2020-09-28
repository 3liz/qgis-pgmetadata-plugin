__copyright__ = "Copyright 2020, 3Liz"
__license__ = "GPL version 3"
__email__ = "info@3liz.org"
__revision__ = "$Format:%H$"


from qgis.core import QgsApplication

from pg_metadata.processing.provider import PgMetadataProvider


class PgMetadata:
    def __init__(self, iface):
        self.iface = iface
        self.provider = None

    def initProcessing(self):
        self.provider = PgMetadataProvider()
        QgsApplication.processingRegistry().addProvider(self.provider)

    def initGui(self):
        self.initProcessing()

    def unload(self):
        QgsApplication.processingRegistry().removeProvider(self.provider)
