__copyright__ = "Copyright 2020, 3Liz"
__license__ = "GPL version 3"
__email__ = "info@3liz.org"
__revision__ = "$Format:%H$"


# noinspection PyPep8Naming
def classFactory(iface):  # pylint: disable=invalid-name
    """Load LayerIntersecter class from file LayerIntersecter.

    :param iface: A QGIS interface instance.
    :type iface: QgsInterface
    """
    #
    from pg_metadata.pg_metadata import PgMetadata

    return PgMetadata(iface)
