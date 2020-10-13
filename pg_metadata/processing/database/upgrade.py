__copyright__ = "Copyright 2020, 3Liz"
__license__ = "GPL version 3"
__email__ = "info@3liz.org"
__revision__ = "$Format:%H$"

import os

from qgis.core import (
    Qgis,
    QgsAbstractDatabaseProviderConnection,
    QgsExpressionContextUtils,
    QgsProcessingException,
    QgsProcessingParameterString,
    QgsProcessingParameterBoolean,
    QgsProcessingOutputString,
    QgsProviderRegistry,
    QgsProviderConnectionException,
)
if Qgis.QGIS_VERSION_INT >= 31400:
    from qgis.core import QgsProcessingParameterProviderConnection

from pg_metadata.processing.database.base import BaseDatabaseAlgorithm
from pg_metadata.qgis_plugin_tools.tools.database import (
    available_migrations,
)
from pg_metadata.qgis_plugin_tools.tools.i18n import tr
from pg_metadata.qgis_plugin_tools.tools.resources import plugin_path
from pg_metadata.qgis_plugin_tools.tools.version import format_version_integer, version

SCHEMA = 'pgmetadata'


class UpgradeDatabaseStructure(BaseDatabaseAlgorithm):

    CONNECTION_NAME = "CONNECTION_NAME"
    RUN_MIGRATIONS = "RUN_MIGRATIONS"
    DATABASE_VERSION = "DATABASE_VERSION"

    def name(self):
        return "upgrade_database_structure"

    def displayName(self):
        return tr("Upgrade the database structure")

    def shortHelpString(self):
        return tr(
            "Upgrade of the database structure to the latest version."
        )

    def initAlgorithm(self, config):
        connection_name = QgsExpressionContextUtils.globalScope().variable(
            "{}_connection_name".format(SCHEMA)
        )
        label = tr("Connection to the PostgreSQL database")
        tooltip = label
        if Qgis.QGIS_VERSION_INT >= 31400:
            param = QgsProcessingParameterProviderConnection(
                self.CONNECTION_NAME,
                label,
                "postgres",
                defaultValue=connection_name,
                optional=False,
            )
        else:
            param = QgsProcessingParameterString(
                self.CONNECTION_NAME,
                label,
                defaultValue=connection_name,
                optional=False,
            )
            param.setMetadata(
                {
                    "widget_wrapper": {
                        "class": "processing.gui.wrappers_postgis.ConnectionWidgetWrapper"
                    }
                }
            )
        if Qgis.QGIS_VERSION_INT >= 31600:
            param.setHelp(tooltip)
        else:
            param.tooltip_3liz = tooltip
        self.addParameter(param)

        self.addParameter(
            QgsProcessingParameterBoolean(
                self.RUN_MIGRATIONS,
                tr("Use this checkbox to upgrade."),
                defaultValue=False,
            )
        )

        self.addOutput(
            QgsProcessingOutputString(self.DATABASE_VERSION, tr("Database version"))
        )

    def checkParameterValues(self, parameters, context):
        # Check if run migrations is checked
        run_migrations = self.parameterAsBool(parameters, self.RUN_MIGRATIONS, context)
        if not run_migrations:
            msg = tr("You must use the checkbox to do the upgrade !")
            return False, msg

        if Qgis.QGIS_VERSION_INT >= 31400:
            connection_name = self.parameterAsConnectionName(
                parameters, self.CONNECTION_NAME, context)
        else:
            connection_name = self.parameterAsString(
                parameters, self.CONNECTION_NAME, context)

        metadata = QgsProviderRegistry.instance().providerMetadata('postgres')
        connection = metadata.findConnection(connection_name)
        if not connection:
            raise QgsProcessingException(tr("The connection {} does not exist.").format(connection_name))

        if SCHEMA in connection.schemas():
            override = self.parameterAsBool(parameters, self.RUN_MIGRATIONS, context)
            if not override:
                msg = tr(
                    "The schema {} already exists in the database {} ! "
                    "If you really want to remove and recreate the schema (and remove its data),"
                    " use the checkbox.").format(SCHEMA, connection_name)
                return False, msg

        return super().checkParameterValues(parameters, context)

    def processAlgorithm(self, parameters, context, feedback):
        if Qgis.QGIS_VERSION_INT >= 31400:
            connection_name = self.parameterAsConnectionName(
                parameters, self.CONNECTION_NAME, context)
        else:
            connection_name = self.parameterAsString(
                parameters, self.CONNECTION_NAME, context)

        metadata = QgsProviderRegistry.instance().providerMetadata('postgres')

        connection = metadata.findConnection(connection_name)
        connection: QgsAbstractDatabaseProviderConnection
        if not connection:
            raise QgsProcessingException(tr("The connection {} does not exist.").format(connection_name))

        if not connection.tableExists(SCHEMA, 'qgis_plugin'):
            raise QgsProcessingException(tr(
                "The table {}.{} does not exist. You must first create the database structure.").format(
                SCHEMA, 'qgis_plugin'))

        # Get database version
        sql = (
            "SELECT version "
            "FROM {}.qgis_plugin "
            "WHERE status = 1 "
            "ORDER BY version_date DESC "
            "LIMIT 1;").format(SCHEMA)
        try:
            data = connection.executeSql(sql)
        except QgsProviderConnectionException as e:
            raise QgsProcessingException(str(e))

        db_version = None
        for a in data:
            db_version = a[0]
        if not db_version:
            error_message = tr("No version has been found in the database !")
            raise QgsProcessingException(error_message)

        feedback.pushInfo("Current database version '{}'.".format(db_version))

        # Get plugin version
        plugin_version = version()
        if plugin_version in ["master", "dev"]:
            migrations = available_migrations(000000)
            last_migration = migrations[-1]
            plugin_version = (
                last_migration.replace("upgrade_to_", "").replace(".sql", "").strip()
            )
            feedback.reportError(
                tr("Be careful, running the migrations on a development branch!")
            )
            feedback.reportError(
                tr("Latest available migration is {}").format(plugin_version)
            )
        else:
            feedback.pushInfo(tr("Plugin's version is {}").format(plugin_version))

        results = {
            self.DATABASE_VERSION: plugin_version
        }

        # Return if nothing to do
        if db_version == plugin_version:
            feedback.pushInfo(tr(
                "The database version and the plugin version are the same, version {}. There isn't any "
                "upgrade to do.").format(plugin_version))
            return results

        db_version_integer = format_version_integer(db_version)
        sql_files = available_migrations(db_version_integer)

        # Loop sql files and run SQL code
        for sf in sql_files:
            sql_file = os.path.join(plugin_path(), "install/sql/upgrade/{}".format(sf))
            with open(sql_file, "r") as f:
                sql = f.read()
                if len(sql.strip()) == 0:
                    feedback.pushInfo("* " + sf + " -- " + tr("SKIPPING, EMPTY FILE"))
                    continue

                new_db_version = (sf.replace("upgrade_to_", "").replace(".sql", "").strip())
                sql += (
                    "UPDATE {}.qgis_plugin "
                    "SET (version, version_date) = ( '{}', now()::timestamp(0) )").format(
                    SCHEMA, new_db_version)

                try:
                    connection.executeSql(sql)
                except QgsProviderConnectionException as e:
                    raise QgsProcessingException(str(e))
                else:
                    feedback.pushInfo("Database version {} -- OK !".format(new_db_version))

        # Everything is fine, we now update to the plugin version
        sql = (
            "UPDATE {}.metadata "
            "SET (me_version, me_version_date) = ( '{}', now()::timestamp(0) );").format(
            SCHEMA, plugin_version)
        try:
            connection.executeSql(sql)
        except QgsProviderConnectionException as e:
            raise QgsProcessingException(str(e))
        else:
            feedback.pushInfo("Database upgraded to the current plugin version {}!".format(plugin_version))

        return results
