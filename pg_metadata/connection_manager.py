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


def check_pgmetadata_is_installed(connection_name: str) -> bool:
    """ Test if a given connection has PgMetadata installed. """

    if connection_name not in connections_list()[0]:
        return False

    metadata = QgsProviderRegistry.instance().providerMetadata('postgres')
    connection = metadata.findConnection(connection_name)

    if 'pgmetadata' not in connection.schemas():
        return False

    if len([t for t in connection.tables('pgmetadata') if t.tableName() == 'dataset']) < 1:
        return False

    return True


def reset_connections() -> None:
    """ Reset connections to an empty list. """
    QgsExpressionContextUtils.setGlobalVariable("pgmetadata_connection_names", '')


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
            "You must use the 'Set Connections' algorithm in the Processing toolbox. The plugin must be "
            "aware about the database to use. Multiple databases can be set."
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
