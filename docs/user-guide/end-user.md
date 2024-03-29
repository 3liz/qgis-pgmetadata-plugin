# End user

## Locator

Type ++ctrl+k++ in QGIS to open the locator widget. You can start type `meta` then you should see layers in the
list.

![Locator](../media/locator.gif)

## Datasource manager

This works without the plugin installed on the computer. It's native in QGIS.

![Search with comment](../media/datasource_manager.png)

## Panel

The PgMetadata panel can be opened. If set, the layer metadata will be displayed according to the layer 
selected in the legend.

![Panel](../media/dock_qgis.png)

## Export a single metadata

To export a metadata sheet as PDF, HTML or DCAT, you need to select a layer in your layer tree saved in the 
metadata table `dataset`. Then in the dock you have a button to open the `export menu` and choose the output
format.

![Button Export](../media/dockpgmetadata_with_metadata.png)

If no layer with metadata are selected, you can't click on the button of the `export menu`.

![Button Export without metadata](../media/dockpgmetadatawithoutmetadata.png)

## Export the catalog

From the dock, it's possible to add a layer in the legend showing the full catalog. The main **dataset** table
is flatten to show **contacts** and **links** as well.

The user can export this non-spatial layer as CSV by right clicking on the layer then **Export**.
