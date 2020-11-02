"""Dock file."""

__copyright__ = 'Copyright 2020, 3Liz'
__license__ = 'GPL version 3'
__email__ = 'info@3liz.org'

import logging

from qgis.core import (
    QgsApplication,
    QgsProviderConnectionException,
    QgsProviderRegistry,
    QgsVectorLayer,
)
from qgis.PyQt.QtCore import QUrl
from qgis.PyQt.QtGui import QDesktopServices, QIcon
from qgis.PyQt.QtWidgets import QDockWidget
from qgis.utils import iface

from pg_metadata.connection_manager import connections_list
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

        self.external_help.setText('')
        self.external_help.setIcon(QIcon(QgsApplication.iconPath('mActionHelpContents.svg')))
        self.external_help.clicked.connect(self.open_external_help)

        self.metadata = QgsProviderRegistry.instance().providerMetadata('postgres')

        self.default_html_content()

        iface.layerTreeView().currentLayerChanged.connect(self.layer_changed)

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
                return

            sql = (
                "SELECT title, "
                "abstract, "
                "array_to_string(categories, ', '::text), "
                "array_to_string(keywords, ', '::text) "
                "FROM pgmetadata.dataset "
                "WHERE table_name = '{table}' "
                "AND schema_name = '{schema}' "
                "LIMIT 1;".format(schema=uri.schema(), table=uri.table()))

            try:
                data = connection.executeSql(sql)
            except QgsProviderConnectionException as e:
                LOGGER.critical('Error when querying the database : ' + str(e))
                self.default_html_content()
                return

            if not data:
                # Go to the next database
                continue

            metadata = data[0]
            html = (
                "<p>{abstract}</p>"
                "<p>Categories : {categories}</p>"
                "<p>Keywords : {keywords}</p>"
            ).format(
                abstract=metadata[1],
                categories=metadata[2],
                keywords=metadata[3],
            )
            self.set_html_content(metadata[0], html)

            break

        else:
            origin = uri.database() if uri.database() else uri.service()
            self.set_html_content(
                'Missing metadata',
                'The layer {origin} {schema}.{table} is missing metadata.'.format(
                    origin=origin, schema=uri.schema(), table=uri.table())
            )

    @staticmethod
    def open_external_help():
        QDesktopServices.openUrl(QUrl('https://docs.3liz.org/qgis-pgmetadata-plugin/'))

    def set_html_content(self, title, body):
        css = (
            '<style>'
            'body { font-family: '
            '\'Ubuntu\', \'Lucida Grande\', \'Segoe UI\', \'Arial\', sans-serif;'
            'margin-left: 0px; margin-right: 0px; margin-top: 0px;'
            'font-size: 14px;}'
            'img { max-width: 100%;}'
            'h2 { color: #fff; background-color: #014571; line-height: 2; padding-left:5px; }'
            '</style>'
        )
        html = (
            '<hmtl><head>{css}</head><body>'
            '<h2>{title}</h2>'
            '<p>{body}</p>'
            '</body></html>'
        ).format(title=title, body=body, css=css)

        # It must be a file, even if it does not exist on the file system.
        base_url = QUrl.fromLocalFile(resources_path('images', 'must_be_a_file.png'))
        self.viewer.setHtml(html, base_url)

    def default_html_content(self):
        self.set_html_content(
            'PgMetadata', 'You should click on a layer in the legend which is stored in PostgreSQL.')
