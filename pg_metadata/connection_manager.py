__copyright__ = "Copyright 2020, 3Liz"
__license__ = "GPL version 3"
__email__ = "info@3liz.org"
__revision__ = "$Format:%H$"

from qgis.core import (
    QgsExpressionContextUtils,
    QgsProviderConnectionException,
    QgsProviderRegistry,
)

from pg_metadata.qgis_plugin_tools.tools.i18n import tr


def add_connection(connection_name: str) -> None:
    """ Add a connection name in the QGIS configuration. """
    existing_names = QgsExpressionContextUtils.globalScope().variable(
        "pgmetadata_connection_names"
    )
    if not existing_names:
        new_string = connection_name
        QgsExpressionContextUtils.setGlobalVariable("pgmetadata_connection_names", new_string)

    elif connection_name not in existing_names.split(';'):
        new_string = f'{existing_names};{connection_name}'
        QgsExpressionContextUtils.setGlobalVariable("pgmetadata_connection_names", new_string)


def connections_list() -> tuple:
    """ List of available connections to PostgreSQL database. """
    metadata = QgsProviderRegistry.instance().providerMetadata('postgres')

    connection_names = QgsExpressionContextUtils.globalScope().variable(
        "pgmetadata_connection_names"
    )
    if not connection_names:
        message = tr(
                "One algorithm from PgMetadata must be used before. The plugin will be aware about the "
                "database to use."
        )
        return (), message

    connections = list()

    for name in connection_names.split(';'):
        try:
            metadata.findConnection(name)
        except QgsProviderConnectionException:
            # Todo, we must log something
            pass
        else:
            connections.append(name)

    return connections, None
