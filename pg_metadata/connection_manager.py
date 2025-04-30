__copyright__ = "Copyright 2022, 3Liz"
__license__ = "GPL version 3"
__email__ = "info@3liz.org"

import logging

from typing import List, Tuple

from qgis.core import (
    Qgis,
    QgsExpressionContextUtils,
    QgsProviderConnectionException,
    QgsProviderRegistry,
    QgsSettings,
)
from qgis.utils import iface

from pg_metadata.qgis_plugin_tools.tools.i18n import tr

LOGGER = logging.getLogger('pg_metadata')
CON_SEPARATOR = '!!::!!'  # separate connection names in settings string; same as in QGIS core


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
        # Adding the separator at the beginning is an ugly hack to tell new
        # and old strings apart.
        # Otherwise, migrate_connection_name_separator() would not know if a string
        # with semicolon but without new separator is a single connection in the
        # new style or two in the old style.
        settings.setValue("pgmetadata/connection_names", f'{CON_SEPARATOR}{connection_name}')

    elif connection_name not in existing_names.split(CON_SEPARATOR):
        new_string = f'{existing_names}{CON_SEPARATOR}{connection_name}'
        settings.setValue("pgmetadata/connection_names", new_string)


def store_connections(connection_names: List[str]) -> None:
    """ Store a list of connection names in the QGIS configuration.

    It overwrites existing connections.
    """
    reset_connections()
    for name in connection_names:
        add_connection(name)


def migrate_from_global_variables_to_pgmetadata_section() -> None:
    """ Let's migrate from global variables to pgmetadata section in INI file. """
    connection_names = QgsExpressionContextUtils.globalScope().variable("pgmetadata_connection_names")
    if not connection_names:
        return

    QgsSettings().setValue("pgmetadata/connection_names", connection_names)
    QgsExpressionContextUtils.removeGlobalVariable("pgmetadata_connection_names")


def migrate_connection_name_separator() -> None:
    """ Migrate from semicolon to CON_SEPARATOR = '!!::!!' as separator for connection names. """
    settings_string = settings_connections_names()
    if ';' in settings_string and CON_SEPARATOR not in settings_string:
        LOGGER.info(f'Migrating {settings_string} from ";" to "{CON_SEPARATOR}"')
        store_connections(settings_string.split(';'))


def settings_connections_names() -> str:
    """ Fetch in the QGIS Settings for the list of connections. """
    return QgsSettings().value("pgmetadata/connection_names", "", type=str)


def validate_connections_names() -> Tuple[List[str], List[str]]:
    """Check all connections if the database is valid or not. """

    # Do some legacy migrations first
    migrate_from_global_variables_to_pgmetadata_section()
    migrate_connection_name_separator()

    metadata = QgsProviderRegistry.instance().providerMetadata('postgres')

    connection_names = settings_connections_names()
    if not connection_names:  # no connection is a valid situation
        return [], []

    valid = []
    invalid = []
    # First element of split string is empty, see comment in add_connection()
    for name in connection_names.split(CON_SEPARATOR)[1:]:
        try:
            connection = metadata.findConnection(name)
        except QgsProviderConnectionException:
            invalid.append(name)
        else:
            if connection:
                valid.append(name)
            else:
                invalid.append(name)
    return valid, invalid


def connections_list() -> Tuple[Tuple, str]:
    """ List of available connections to PostgreSQL database.

    Returns a tuple:
        * list of connections
        * list of connection error messages
    """
    migrate_from_global_variables_to_pgmetadata_section()
    migrate_connection_name_separator()

    metadata = QgsProviderRegistry.instance().providerMetadata('postgres')

    connection_names = settings_connections_names()
    if not connection_names:
        message = tr(
            "You must use the 'Set Connections' algorithm in the Processing toolbox. The plugin must be "
            "aware about the database to use. Multiple databases can be set."
        )
        return tuple(), message

    connections = list()
    messages = list()
    # First element of split string is empty, see comment in add_connection()
    for name in connection_names.split(CON_SEPARATOR)[1:]:
        try:
            connection = metadata.findConnection(name)
        except QgsProviderConnectionException:
            # Todo, we must log something
            # TODO suggestion:
            mess = f'QgsProviderConnectionException when looking for connection {name}.'
            iface.messageBar().pushMessage(mess, level=Qgis.MessageLevel.Critical)
            # FIXME: show message bar here or just return message to higher level?
            messages.append(mess)
        else:
            if connection:
                connections.append(name)
            else:
                mess = f'Unknown database connection {name} in PgMetadata settings.'
                iface.messageBar().pushMessage(mess, level=Qgis.MessageLevel.Warning)
                # FIXME: show message bar here or just return message to higher level?
                messages.append(mess)
    if messages:
        message = '\n'.join(messages)
    else:
        message = None

    return tuple(connections), message
