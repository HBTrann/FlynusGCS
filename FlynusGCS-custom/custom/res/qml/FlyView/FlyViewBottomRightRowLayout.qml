import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlyView

// Flynus GCS override of the stock FlyViewBottomRightRowLayout.qml.
// Bottom-center telemetry in a compact "label + big number" style:
//   [ H   H.S  ]                [ D     ⏱    ]
//   [ V.S ASL  ]   ( compass )  [ DIST  HDG  ]
// Values come straight from the vehicle Facts, so units follow the user's settings.
//
// FlyViewWidgetLayer anchors this item bottom/right and uses width/height as tool
// insets. Nothing is drawn at the bottom-right corner, so the item has zero width;
// its height reserves the bottom-center area.
Item {
    id: _root

    property real spacing: 0    // set by FlyViewWidgetLayer, kept for API compatibility

    property var _vehicle: QGroundControl.multiVehicleManager.activeVehicle

    width:  0
    height: telemetryPanel.height

    component TelemetryValue: Row {
        id:         cell
        spacing:    ScreenTools.defaultFontPixelWidth * 0.5

        property string label
        property var    fact            // Fact or null
        property bool   showUnits: true

        QGCLabel {
            anchors.baseline:   valueLabel.baseline
            text:               cell.label
            color:              "#9AA59D"
            font.pointSize:     ScreenTools.smallFontPointSize
            font.bold:          true
            font.letterSpacing: 1
        }
        QGCLabel {
            id:                 valueLabel
            text:               cell.fact ? cell.fact.valueString : "--"
            font.pointSize:     ScreenTools.largeFontPointSize
            font.bold:          true
        }
        QGCLabel {
            anchors.baseline:   valueLabel.baseline
            text:               cell.fact ? cell.fact.units : ""
            visible:            cell.showUnits && text !== ""
            color:              "#9AA59D"
            font.pointSize:     ScreenTools.smallFontPointSize
        }
    }

    Rectangle {
        id:             telemetryPanel
        anchors.bottom: parent.bottom
        // Centered in the whole Fly View (our parent), not in this zero-width item.
        x:              _root.parent ? Math.max(0, (_root.parent.width - width) / 2) - _root.x : 0
        width:          panelRow.width + ScreenTools.defaultFontPixelWidth * 4
        height:         panelRow.height + ScreenTools.defaultFontPixelHeight * 0.8
        radius:         ScreenTools.defaultFontPixelWidth * 1.4
        color:          Qt.rgba(0.07, 0.086, 0.078, 0.78)
        border.width:   1
        border.color:   Qt.rgba(1, 1, 1, 0.10)

        RowLayout {
            id:                 panelRow
            anchors.centerIn:   parent
            spacing:            ScreenTools.defaultFontPixelWidth * 2.5

            GridLayout {
                columns:        2
                columnSpacing:  ScreenTools.defaultFontPixelWidth * 2.5
                rowSpacing:     0

                TelemetryValue { label: "H";   fact: _vehicle ? _vehicle.altitudeRelative : null }
                TelemetryValue { label: "H.S"; fact: _vehicle ? _vehicle.groundSpeed : null }
                TelemetryValue { label: "V.S"; fact: _vehicle ? _vehicle.climbRate : null }
                TelemetryValue { label: "ASL"; fact: _vehicle ? _vehicle.altitudeAMSL : null }
            }

            FlyViewInstrumentPanel {
                Layout.alignment:   Qt.AlignVCenter
                visible:            QGroundControl.corePlugin.options.flyView.showInstrumentPanel && _showSingleVehicleUI
            }

            GridLayout {
                columns:        2
                columnSpacing:  ScreenTools.defaultFontPixelWidth * 2.5
                rowSpacing:     0

                TelemetryValue { label: "D";    fact: _vehicle ? _vehicle.distanceToHome : null }
                TelemetryValue { label: "TIME"; fact: _vehicle ? _vehicle.getFact("flightTime") : null; showUnits: false }
                TelemetryValue { label: "DIST"; fact: _vehicle ? _vehicle.flightDistance : null }
                TelemetryValue { label: "HDG";  fact: _vehicle ? _vehicle.heading : null }
            }
        }
    }
}
