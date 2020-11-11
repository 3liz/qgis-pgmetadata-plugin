"""Dock file."""

__copyright__ = 'Copyright 2020, 3Liz'
__license__ = 'GPL version 3'
__email__ = 'info@3liz.org'

import logging

from qgis.core import (
    NULL,
    QgsApplication,
    QgsProviderConnectionException,
    QgsProviderRegistry,
    QgsSettings,
    QgsVectorLayer,
)
from qgis.PyQt.QtCore import QUrl
from qgis.PyQt.QtGui import QDesktopServices, QIcon
from qgis.PyQt.QtWebKitWidgets import QWebPage
from qgis.PyQt.QtWidgets import QAction, QDockWidget, QMenu, QToolButton
from qgis.utils import iface

from pg_metadata.connection_manager import (
    check_pgmetadata_is_installed,
    connections_list,
)
from pg_metadata.qgis_plugin_tools.tools.i18n import tr
from pg_metadata.qgis_plugin_tools.tools.resources import (
    load_ui,
    resources_path,
)

DOCK_CLASS = load_ui('dock.ui')
LOGGER = logging.getLogger('pg_metadata')


class PgMetadataDock(QDockWidget, DOCK_CLASS):

    def __init__(self, parent=None):
        _ = parent
        super().__init__()
        self.setupUi(self)
        self.settings = QgsSettings()

        self.external_help.setText('')
        self.external_help.setIcon(QIcon(QgsApplication.iconPath('mActionHelpContents.svg')))
        self.external_help.clicked.connect(self.open_external_help)
        self.viewer.page().setLinkDelegationPolicy(QWebPage.DelegateAllLinks)
        self.viewer.page().linkClicked.connect(self.open_link)

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

        self.metadata = QgsProviderRegistry.instance().providerMetadata('postgres')

        self.default_html_content()

        iface.layerTreeView().currentLayerChanged.connect(self.layer_changed)

    def save_auto_open_dock(self):
        """ Save settings about the dock. """
        self.settings.setValue("pgmetadata/auto_open_dock", self.auto_open_dock_action.isChecked())

    def layer_changed(self, layer):
        if not isinstance(layer, QgsVectorLayer):
            self.default_html_content()
            return

        uri = layer.dataProvider().uri()
        if not uri.schema() or not uri.table():
            self.default_html_content()
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
                self.default_html_content()
                continue

            if not check_pgmetadata_is_installed(connection_name):
                LOGGER.critical(tr('PgMetadata is not installed on {}').format(connection_name))
                continue

            sql = (
                "SELECT pgmetadata.get_dataset_item_html_content('{schema}', '{table}');"
            ).format(schema=uri.schema(), table=uri.table())

            try:
                data = connection.executeSql(sql)
            except QgsProviderConnectionException as e:
                LOGGER.critical(tr('Error when querying the database : ') + str(e))
                self.default_html_content()
                return

            if not data:
                # Go to the next database
                continue

            if data[0] == NULL or data[0][0] == NULL:
                continue

            self.set_html_content(body=data[0][0])

            break

        else:
            origin = uri.database() if uri.database() else uri.service()
            self.set_html_content(
                'Missing metadata',
                tr('The layer {origin} {schema}.{table} is missing metadata.').format(
                    origin=origin, schema=uri.schema(), table=uri.table())
            )

    @staticmethod
    def open_external_help():
        QDesktopServices.openUrl(QUrl('https://docs.3liz.org/qgis-pgmetadata-plugin/'))

    @staticmethod
    def open_link(url):
        QDesktopServices.openUrl(url)

    def set_html_content(self, title=None, body=None):
        """ Set the content in the dock. """

        css_file = resources_path('css', 'dock.css')
        with open(css_file, 'r') as f:
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

    def default_html_content(self):
        self.set_html_content(
            'PgMetadata', tr('You should click on a layer in the legend which is stored in PostgreSQL.'))
