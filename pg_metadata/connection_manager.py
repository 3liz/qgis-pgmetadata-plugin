__copyright__ = "Copyright 2020, 3Liz"
__license__ = "GPL version 3"
__email__ = "info@3liz.org"
__revision__ = "$Format:%H$"

from qgis.core import (
    QgsExpressionContextUtils,
    QgsProviderConnectionException,
    QgsProviderRegistry,
    QgsSettings,
)

from pg_metadata.qgis_plugin_tools.tools.i18n import tr


def check_pgmetadata_is_installed(connection_name: str) -> bool:
    """ Test if a given connection has PgMetadata installed. """

    if connection_name not in connections_list()[0]:
        return False

    metadata = QgsProviderRegistry.instance().providerMetadata('postgres')
    connection = metadata.findConnection(connection_name)

    if not connection:
        return False

    try:
        if 'pgmetadata' not in connection.schemas():
            return False
    except QgsProviderConnectionException:
        # The connection is registered in QGIS but the server is currently not reachable
        return False

    if len([t for t in connection.tables('pgmetadata') if t.tableName() == 'dataset']) < 1:
        return False

    return True


def reset_connections() -> None:
    """ Reset connections to an empty list. """
    QgsSettings().setValue("pgmetadata/connection_names", "")


def add_connection(connection_name: str) -> None:
    """ Add a connection name in the QGIS configuration. """
    settings = QgsSettings()
    existing_names = settings.value("pgmetadata/connection_names", "", type=str)
    if not existing_names:
        settings.setValue("pgmetadata/connection_names", connection_name)

    elif connection_name not in existing_names.split(';'):
        new_string = f'{existing_names};{connection_name}'
        settings.setValue("pgmetadata/connection_names", new_string)


def migrate_from_global_variables_to_pgmetadata_section():
    """ Let's migrate from global variables to pgmetadata section in INI file. """
    connection_names = QgsExpressionContextUtils.globalScope().variable("pgmetadata_connection_names")
    if not connection_names:
        return

    QgsSettings().setValue("pgmetadata/connection_names", connection_names)
    QgsExpressionContextUtils.removeGlobalVariable("pgmetadata_connection_names")


def settings_connections_names() -> tuple:
    """ Fetch in the QGIS Settings for the list of connections. """
    return QgsSettings().value("pgmetadata/connection_names", "", type=str)


def connections_list() -> tuple:
    """ List of available connections to PostgreSQL database. """
    migrate_from_global_variables_to_pgmetadata_section()

    metadata = QgsProviderRegistry.instance().providerMetadata('postgres')

    connection_names = settings_connections_names()
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
