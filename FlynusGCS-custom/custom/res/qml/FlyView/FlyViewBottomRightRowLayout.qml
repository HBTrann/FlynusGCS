import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlyView
import QGroundControl.Toolbar

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
    height: telemetryPanel.height + (modePill.visible ? modePill.height + modePill.anchors.bottomMargin : 0)

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

        // Keep the stock flight-mode control centered above the compass.
        Rectangle {
            id:                         modePill
            anchors.bottom:             parent.top
            anchors.bottomMargin:       ScreenTools.defaultFontPixelHeight * 0.25
            height:                     ScreenTools.toolbarHeight * 0.66
            width:                      modePillRow.width + height
            x:                          compass.visible ? panelRow.x + compass.x + (compass.width - width) / 2 : (parent.width - width) / 2
            radius:                     height / 2
            color:                      Qt.rgba(0.055, 0.067, 0.059, 0.85)
            border.width:               1
            border.color:               _armed ? "#2FBF4A" : Qt.rgba(1, 1, 1, 0.25)
            visible:                    !!_root._vehicle && !QGroundControl.videoManager.fullScreen

            property bool _armed: _root._vehicle ? _root._vehicle.armed : false

            RowLayout {
                id:                         modePillRow
                anchors.centerIn:           parent
                height:                     parent.height
                spacing:                    ScreenTools.defaultFontPixelWidth

                Rectangle {
                    Layout.alignment:       Qt.AlignVCenter
                    implicitWidth:          armedLabel.contentWidth + ScreenTools.defaultFontPixelWidth * 1.6
                    implicitHeight:         armedLabel.contentHeight + ScreenTools.defaultFontPixelHeight * 0.2
                    radius:                 height / 2
                    color:                  modePill._armed ? "#2FBF4A" : "#3A403C"

                    QGCLabel {
                        id:                 armedLabel
                        anchors.centerIn:   parent
                        text:               modePill._armed ? qsTr("ARMED") : qsTr("DISARMED")
                        font.pointSize:     ScreenTools.smallFontPointSize
                        font.bold:          true
                        font.letterSpacing: 1
                        color:              modePill._armed ? "#0B0D0C" : "#DDDDDD"
                    }
                }

                FlightModeIndicator {
                    objectName:         "toolbar_flightModeIndicator"
                    Layout.fillHeight:  true
                }
            }
        }

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
                id:                 compass
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
