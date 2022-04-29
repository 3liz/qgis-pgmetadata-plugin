"""Dock file."""

__copyright__ = 'Copyright 2020, 3Liz'
__license__ = 'GPL version 3'
__email__ = 'info@3liz.org'

import logging
import os

from collections import namedtuple
from enum import Enum
from functools import partial
from pathlib import Path
from xml.dom.minidom import parseString

from qgis.core import (
    NULL,
    QgsApplication,
    QgsDataSourceUri,
    QgsProject,
    QgsProviderConnectionException,
    QgsProviderRegistry,
    QgsRasterLayer,
    QgsSettings,
    QgsVectorLayer,
)
from qgis.PyQt.QtCore import QLocale, QUrl
from qgis.PyQt.QtGui import QDesktopServices, QIcon
from qgis.PyQt.QtPrintSupport import QPrinter
from qgis.PyQt.QtWebKitWidgets import QWebPage
from qgis.PyQt.QtWidgets import (
    QAction,
    QDockWidget,
    QFileDialog,
    QInputDialog,
    QMenu,
    QToolButton,
)
from qgis.utils import iface

from pg_metadata.connection_manager import (
    check_pgmetadata_is_installed,
    connections_list,
    settings_connections_names,
)
from pg_metadata.qgis_plugin_tools.tools.i18n import tr
from pg_metadata.qgis_plugin_tools.tools.resources import (
    load_ui,
    resources_path,
)

DOCK_CLASS = load_ui('dock.ui')
LOGGER = logging.getLogger('pg_metadata')


class Format(namedtuple('Format', ['label', 'ext'])):
    """ Format available for exporting metadata. """
    pass


class OutputFormats(Format, Enum):
    """ Output format for a metadata sheet. """
    PDF = Format(label='PDF', ext='pdf')
    HTML = Format(label='HTML', ext='html')
    DCAT = Format(label='DCAT', ext='xml')


class PgMetadataDock(QDockWidget, DOCK_CLASS):

    def __init__(self, parent=None):
        _ = parent
        super().__init__()
        self.setupUi(self)
        self.settings = QgsSettings()

        self.current_datasource_uri = None
        self.current_connection = None

        self.viewer.page().setLinkDelegationPolicy(QWebPage.DelegateAllLinks)
        self.viewer.page().linkClicked.connect(self.open_link)

        # Help button
        self.external_help.setText('')
        self.external_help.setIcon(QIcon(QgsApplication.iconPath('mActionHelpContents.svg')))
        self.external_help.clicked.connect(self.open_external_help)

        # Flat table button
        self.flatten_dataset_table.setText('')
        self.flatten_dataset_table.setToolTip(tr("Add the catalog table"))
        self.flatten_dataset_table.setIcon(QgsApplication.getThemeIcon("/mActionAddHtml.svg"))
        self.flatten_dataset_table.clicked.connect(self.add_flatten_dataset_table)

        # Settings menu
        self.config.setAutoRaise(True)
        self.config.setToolTip(tr("Settings"))
        self.config.setPopupMode(QToolButton.InstantPopup)
        self.config.setIcon(QgsApplication.getThemeIcon("/mActionOptions.svg"))

        self.auto_open_dock_action = QAction(
            tr('Auto open dock from locator'),
            iface.mainWindow())
        self.auto_open_dock_action.setCheckable(True)
        self.auto_open_dock_action.setChecked(
            self.settings.value("pgmetadata/auto_open_dock", True, type=bool)
        )
        self.auto_open_dock_action.triggered.connect(self.save_auto_open_dock)
        menu = QMenu()
        menu.addAction(self.auto_open_dock_action)
        self.config.setMenu(menu)

        # Setting PDF/HTML menu
        self.save_button.setAutoRaise(True)
        self.save_button.setToolTip(tr("Save metadata"))
        self.save_button.setPopupMode(QToolButton.InstantPopup)
        self.save_button.setIcon(QIcon(QgsApplication.iconPath('mActionFileSave.svg')))

        self.save_as_pdf = QAction(
            tr('Save as PDF') + '…',
            iface.mainWindow())
        self.save_as_pdf.triggered.connect(partial(self.export_dock_content, OutputFormats.PDF))

        self.save_as_html = QAction(
            tr('Save as HTML') + '…',
            iface.mainWindow())
        self.save_as_html.triggered.connect(partial(self.export_dock_content, OutputFormats.HTML))

        self.save_as_dcat = QAction(
            tr('Save as DCAT') + '…',
            iface.mainWindow())
        self.save_as_dcat.triggered.connect(partial(self.export_dock_content, OutputFormats.DCAT))

        self.menu_save = QMenu()
        self.menu_save.addAction(self.save_as_pdf)
        self.menu_save.addAction(self.save_as_html)
        self.menu_save.addAction(self.save_as_dcat)
        self.save_button.setMenu(self.menu_save)
        self.save_button.setEnabled(False)

        self.metadata = QgsProviderRegistry.instance().providerMetadata('postgres')

        # Display message in the dock
        if not settings_connections_names():
            self.default_html_content_not_installed()
        else:
            self.default_html_content_not_pg_layer()

        iface.layerTreeView().currentLayerChanged.connect(self.layer_changed)

    def export_dock_content(self, output_format: OutputFormats):
        """ Export the current displayed metadata sheet to the given format. """
        layer_name = iface.activeLayer().name()

        file_path = os.path.join(
            self.settings.value("UI/lastFileNameWidgetDir"),
            '{name}.{ext}'.format(name=layer_name, ext=output_format.ext)
        )
        output_file = QFileDialog.getSaveFileName(
            self,
            tr("Save File as {format}").format(format=output_format.label),
            file_path,
            "{label} (*.{ext})".format(
                label=output_format.label,
                ext=output_format.ext,
            )
        )
        if output_file[0] == '':
            return

        self.settings.setValue("UI/lastFileNameWidgetDir", os.path.dirname(output_file[0]))

        output_file_path = output_file[0]
        parent_folder = str(Path(output_file_path).parent)

        if output_format == OutputFormats.PDF:
            printer = QPrinter()
            printer.setOutputFormat(QPrinter.PdfFormat)
            printer.setPageMargins(20, 20, 20, 20, QPrinter.Millimeter)
            printer.setOutputFileName(output_file_path)
            self.viewer.print(printer)
            iface.messageBar().pushSuccess(
                tr("Export PDF"),
                tr(
                    "The metadata has been exported as PDF successfully in "
                    "<a href=\"{}\">{}</a>").format(parent_folder, output_file_path)
            )

        elif output_format in [OutputFormats.HTML, OutputFormats.DCAT]:
            if output_format == OutputFormats.HTML:
                data_str = self.viewer.page().currentFrame().toHtml()
            else:
                sql = self.sql_for_layer(
                    self.current_datasource_uri, output_format=OutputFormats.DCAT)
                data = self.current_connection.executeSql(sql)
                with open(resources_path('xml', 'dcat.xml'), encoding='utf8') as xml_file:
                    xml_template = xml_file.read()

                locale = QgsSettings().value("locale/userLocale", QLocale().name())
                locale = locale.split('_')[0].lower()

                xml = parseString(xml_template.format(locale=locale, content=data[0][0]))
                data_str = xml.toprettyxml()

            with open(output_file[0], "w", encoding='utf8') as file_writer:
                file_writer.write(data_str)
            iface.messageBar().pushSuccess(
                tr("Export") + ' ' + output_format.label,
                tr(
                    "The metadata has been exported as {format} successfully in "
                    "<a href=\"{folder}\">{path}</a>").format(
                    format=output_format.label, folder=parent_folder, path=output_file_path)
            )

    def save_auto_open_dock(self):
        """ Save settings about the dock. """
        self.settings.setValue("pgmetadata/auto_open_dock", self.auto_open_dock_action.isChecked())

    @staticmethod
    def sql_for_layer(uri, output_format: OutputFormats):
        """ Get the SQL query for a given layer and output format. """
        locale = QgsSettings().value("locale/userLocale", QLocale().name())
        locale = locale.split('_')[0].lower()

        if output_format == OutputFormats.HTML:
            sql = (
                "SELECT pgmetadata.get_dataset_item_html_content('{schema}', '{table}', '{locale}');"
            ).format(schema=uri.schema(), table=uri.table(), locale=locale)
        elif output_format == OutputFormats.DCAT:
            sql = (
                "SELECT dataset FROM pgmetadata.get_datasets_as_dcat_xml("
                "    '{locale}',"
                "    ("
                "    SELECT array_agg(uid)"
                "    FROM pgmetadata.dataset AS d"
                "    WHERE d.schema_name = '{schema}' "
                "    AND d.table_name = '{table}'"
                "    )"
                ") "

            ).format(schema=uri.schema(), table=uri.table(), locale=locale)
        else:
            raise NotImplementedError('Output format is not yet implemented.')

        return sql

    def layer_changed(self, layer):
        """ When the layer has changed in the legend, we must check this new layer. """
        self.save_button.setEnabled(False)
        self.current_datasource_uri = None
        self.current_connection = None

        if not settings_connections_names():
            self.default_html_content_not_installed()
            return

        if not isinstance(layer, (QgsVectorLayer, QgsRasterLayer)):
            self.default_html_content_not_pg_layer()
            return

        uri = layer.dataProvider().uri()
        if not uri.schema() or not uri.table():
            self.default_html_content_not_pg_layer()
            return

        connections, message = connections_list()
        if not connections:
            LOGGER.critical(message)
            self.set_html_content('PgMetadata', message)
            return

        # TODO, find the correct connection to query according to the datasource
        # The metadata HTML is wrong if there are many pgmetadata in different databases

        for connection_name in connections:
            connection = self.metadata.findConnection(connection_name)
            if not connection:
                LOGGER.critical("The global variable pgmetadata_connection_names is not correct.")
                self.default_html_content_not_installed()
                continue

            if not check_pgmetadata_is_installed(connection_name):
                LOGGER.critical(tr('PgMetadata is not installed on {}').format(connection_name))
                continue

            sql = self.sql_for_layer(uri, output_format=OutputFormats.HTML)

            try:
                data = connection.executeSql(sql)
            except QgsProviderConnectionException as e:
                LOGGER.critical(tr('Error when querying the database : ') + str(e))
                self.default_html_content_not_installed()
                return

            if not data:
                # Go to the next database
                continue

            if data[0] == NULL or data[0][0] == NULL:
                continue

            self.set_html_content(body=data[0][0])
            self.save_button.setEnabled(True)
            self.current_datasource_uri = uri
            self.current_connection = connection

            break

        else:
            origin = uri.database() if uri.database() else uri.service()
            self.set_html_content(
                tr('Missing metadata'),
                tr('The layer {origin} {schema}.{table} is missing metadata.').format(
                    origin=origin, schema=uri.schema(), table=uri.table())
            )

    def add_flatten_dataset_table(self):
        """ Add a flatten dataset table with all links and contacts. """
        connections, message = connections_list()
        if not connections:
            LOGGER.critical(message)
            self.set_html_content('PgMetadata', message)
            return

        if len(connections) > 1:
            dialog = QInputDialog()
            dialog.setComboBoxItems(connections)
            dialog.setWindowTitle(tr("Database"))
            dialog.setLabelText(tr("Choose the database to add the catalog"))
            if not dialog.exec_():
                return
            connection_name = dialog.textValue()
        else:
            connection_name = connections[0]

        metadata = QgsProviderRegistry.instance().providerMetadata('postgres')
        connection = metadata.findConnection(connection_name)

        locale = QgsSettings().value("locale/userLocale", QLocale().name())
        locale = locale.split('_')[0].lower()

        uri = QgsDataSourceUri(connection.uri())
        uri.setTable(f'(SELECT * FROM pgmetadata.export_datasets_as_flat_table(\'{locale}\'))')
        uri.setKeyColumn('uid')

        layer = QgsVectorLayer(uri.uri(), '{} - {}'.format(tr("Catalog"), connection_name), 'postgres')
        QgsProject.instance().addMapLayer(layer)

    @staticmethod
    def open_external_help():
        QDesktopServices.openUrl(QUrl('https://docs.3liz.org/qgis-pgmetadata-plugin/'))

    @staticmethod
    def open_link(url):
        QDesktopServices.openUrl(url)

    def set_html_content(self, title=None, body=None):
        """ Set the content in the dock. """

        css_file = resources_path('css', 'dock.css')
        with open(css_file, 'r', encoding='utf8') as f:
            css = f.read()

        html = '<html><head><style>{css}</style></head><body>'.format(css=css)

        if title:
            html += '<h2>{title}</h2>'.format(title=title)

        if body:
            html += body

        html += '</body></html>'

        # It must be a file, even if it does not exist on the file system.
        base_url = QUrl.fromLocalFile(resources_path('images', 'must_be_a_file.png'))
        self.viewer.setHtml(html, base_url)

    def default_html_content_not_installed(self):
        """ When PgMetadata is not installed correctly or not at all. """
        message = "<p>"
        message += tr("The 'pgmetadata' schema is not installed or configured.")
        message += "</p>"
        message += "<p>"
        message += tr(
            "Either install PgMetadata on a database (Processing → Database → Installation of the "
            "database structure) or make the link to an existing PgMetadata database (Processing → "
            "Administration → Set connections to database)."
        )
        message += "</p>"
        message += "<p>"
        message += tr(
            "Visit the documentation on <a href=\"https://docs.3liz.org/qgis-pgmetadata-plugin/\">"
            "docs.3liz.org</a> to check how to setup PgMetadata."
        )
        message += "</p>"
        self.set_html_content('PgMetadata', message)

    def default_html_content_not_pg_layer(self):
        """ When it's not a PostgreSQL layer. """
        self.set_html_content(
            'PgMetadata', tr('You should click on a layer in the legend which is stored in PostgreSQL.'))
