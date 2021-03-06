__copyright__ = "Copyright 2020, 3Liz"
__license__ = "GPL version 3"
__email__ = "info@3liz.org"

from qgis.core import QgsLayerItem
from qgis.PyQt.QtCore import NULL
from qgis.PyQt.QtGui import QIcon

from pg_metadata.qgis_plugin_tools.tools.resources import resources_path


def icon_for_geometry_type(geometry_type: str) -> QIcon():
    """ Return the correct icon according to the geometry type. """
    if geometry_type == NULL:
        return QgsLayerItem.iconTable()

    elif geometry_type == 'POINT':
        return QgsLayerItem.iconPoint()

    elif geometry_type == 'LINESTRING':
        return QgsLayerItem.iconLine()

    elif geometry_type == 'MULTIPOLYGON':
        return QgsLayerItem.iconPolygon()

    # Default icon
    return QIcon(resources_path('icons', 'icon.png'))
