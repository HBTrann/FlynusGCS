import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlyView

// Flynus GCS override of the stock FlyViewBottomRightRowLayout.qml.
// Layout at the bottom-center of the Fly View:
//   [ telemetry (left) ]  [ compass / instrument panel ]  [ telemetry (right) ]
// The two telemetry bars use their own settings groups; their default values are
// defined in CustomPlugin::factValueGridCreateDefaultSettings(). Each bar can still
// be edited by the user (right-click / long-press on it).
//
// FlyViewWidgetLayer anchors this item bottom/right and uses width/height as tool
// insets. Nothing is drawn at the bottom-right corner any more, so the item has
// zero width; its height reserves the bottom-center area.
Item {
    id: _root

    property real spacing: 0    // set by FlyViewWidgetLayer, kept for API compatibility

    readonly property string leftSettingsGroup:  "FlynusTelemetryLeft"
    readonly property string rightSettingsGroup: "FlynusTelemetryRight"

    width:  0
    height: centerRow.height

    RowLayout {
        id:             centerRow
        anchors.bottom: parent.bottom
        spacing:        ScreenTools.defaultFontPixelWidth
        // Centered in the whole Fly View (our parent), not in this zero-width item.
        x:              _root.parent ? Math.max(0, (_root.parent.width - width) / 2) - _root.x : 0

        TelemetryValuesBar {
            Layout.alignment:       Qt.AlignBottom
            settingsGroup:          _root.leftSettingsGroup
            specificVehicleForCard: null // Tracks active vehicle
        }

        FlyViewInstrumentPanel {
            Layout.alignment:   Qt.AlignBottom
            visible:            QGroundControl.corePlugin.options.flyView.showInstrumentPanel && _showSingleVehicleUI
        }

        TelemetryValuesBar {
            Layout.alignment:       Qt.AlignBottom
            settingsGroup:          _root.rightSettingsGroup
            specificVehicleForCard: null // Tracks active vehicle
        }
    }
}
