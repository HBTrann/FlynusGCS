import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import QGroundControl
import QGroundControl.FactControls
import QGroundControl.Controls
import QGroundControl.VehicleSetup
import QGroundControl.AutoPilotPlugins.Common

// Flynus GCS override of the stock Common/RadioComponent.qml (Configure > Radio, PX4 and ArduPilot).
// One "Radio" page with four tabs:
//   1. Pairing         - pair the air unit with the Flynus remote          (needs Flynus remote firmware)
//   2. Channels & Mode - output channel order / stick mode of the remote   (needs Flynus remote firmware)
//   3. Calibration     - the stock QGC radio calibration, unchanged
//   4. Check           - remote output vs. channels received by the vehicle, with mapping warnings
// Tabs 1/2 and the "remote" column of tab 4 show a placeholder until the remote protocol
// (docs/FlynusRemoteProtocol.md) is implemented in the remote firmware.
SetupPage {
    id:             radioPage
    pageComponent:  pageComponent

    // ---- Placeholder used while no Flynus remote is detected ----------
    component RemotePlaceholder: Rectangle {
        id:                 placeholder
        implicitHeight:     placeholderColumn.implicitHeight + ScreenTools.defaultFontPixelHeight * 2
        radius:             ScreenTools.defaultFontPixelWidth * 1.4
        color:              Qt.rgba(1, 1, 1, 0.035)
        border.width:       1
        border.color:       Qt.rgba(1, 1, 1, 0.10)

        property string title
        property string body

        ColumnLayout {
            id:                 placeholderColumn
            anchors.left:       parent.left
            anchors.right:      parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins:    ScreenTools.defaultFontPixelWidth * 2
            spacing:            ScreenTools.defaultFontPixelHeight * 0.4

            QGCLabel {
                text:               placeholder.title
                font.bold:          true
                font.letterSpacing: 1.5
                color:              "#9AA59D"
            }
            QGCLabel {
                Layout.fillWidth:   true
                wrapMode:           Text.WordWrap
                text:               placeholder.body
            }
        }
    }


    Component {
        id: pageComponent

        ColumnLayout {
            id:         radioRoot
            width:      availableWidth
            spacing:    ScreenTools.defaultFontPixelHeight * 0.8

            property int  currentTab:       2           // open on Calibration by default
            property bool remoteDetected:   false       // TODO: set from the Flynus remote link (phase 2)

            property var  _vehicle:         QGroundControl.multiVehicleManager.activeVehicle
            property bool _px4:             _vehicle ? _vehicle.px4Firmware : false

            readonly property color _green:     "#2FBF4A"
            readonly property color _amber:     "#F5B700"
            readonly property color _red:       "#E0303B"
            readonly property color _muted:     "#9AA59D"
            readonly property color _cardColor: Qt.rgba(1, 1, 1, 0.035)
            readonly property color _cardBorder: Qt.rgba(1, 1, 1, 0.10)

            FactPanelController { id: paramController }

            // Channel (1-based) assigned to each stick function on the flight controller; 0 = not mapped
            function _mapParam(px4Name, apmName) {
                var name = _px4 ? px4Name : apmName
                if (name === "" || !paramController.parameterExists(-1, name)) {
                    return 0
                }
                return paramController.getParameterFact(-1, name, false).rawValue
            }
            property int _mapRoll:      _mapParam("RC_MAP_ROLL",     "RCMAP_ROLL")
            property int _mapPitch:     _mapParam("RC_MAP_PITCH",    "RCMAP_PITCH")
            property int _mapThrottle:  _mapParam("RC_MAP_THROTTLE", "RCMAP_THROTTLE")
            property int _mapYaw:       _mapParam("RC_MAP_YAW",      "RCMAP_YAW")
            property int _mapFltMode:   _mapParam("RC_MAP_FLTMODE",  "FLTMODE_CH")
            property int _mapReturn:    _mapParam("RC_MAP_RETURN_SW", "")

            // Flynus remotes ship with AETR (CH1 Roll, CH2 Pitch, CH3 Throttle, CH4 Yaw)
            property bool _vehicleIsAETR: _mapRoll === 1 && _mapPitch === 2 && _mapThrottle === 3 && _mapYaw === 4
            property bool _vehicleMapped: _mapRoll > 0 && _mapPitch > 0 && _mapThrottle > 0 && _mapYaw > 0

            function _functionForChannel(ch) {      // ch is 1-based
                if (ch === _mapRoll)        return qsTr("Roll")
                if (ch === _mapPitch)       return qsTr("Pitch")
                if (ch === _mapThrottle)    return qsTr("Throttle")
                if (ch === _mapYaw)         return qsTr("Yaw")
                if (ch === _mapFltMode)     return qsTr("Flight Mode")
                if (ch === _mapReturn)      return qsTr("Return Switch")
                return ""
            }

            // ---- Tab bar ----------------------------------------------------
            Row {
                Layout.fillWidth:   true
                spacing:            ScreenTools.defaultFontPixelWidth

                Repeater {
                    model: [ qsTr("Pairing"), qsTr("Channels & Mode"), qsTr("Calibration"), qsTr("Check") ]

                    Item {
                        width:  tabRow.width + ScreenTools.defaultFontPixelWidth * 3
                        height: tabRow.height + ScreenTools.defaultFontPixelHeight

                        property bool active: radioRoot.currentTab === index

                        Row {
                            id:                 tabRow
                            anchors.centerIn:   parent
                            spacing:            ScreenTools.defaultFontPixelWidth

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width:          ScreenTools.defaultFontPixelHeight * 1.2
                                height:         width
                                radius:         width / 2
                                color:          "transparent"
                                border.width:   2
                                border.color:   parent.parent.active ? radioRoot._green : radioRoot._muted

                                QGCLabel {
                                    anchors.centerIn:   parent
                                    text:               index + 1
                                    font.pointSize:     ScreenTools.smallFontPointSize
                                    font.bold:          true
                                    color:              parent.border.color
                                }
                            }
                            QGCLabel {
                                anchors.verticalCenter: parent.verticalCenter
                                text:                   modelData
                                font.bold:              true
                                font.pointSize:         ScreenTools.mediumFontPointSize
                                color:                  parent.parent.active ? radioRoot._green : radioRoot._muted
                            }
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width:          parent.width
                            height:         3
                            radius:         1.5
                            color:          radioRoot._green
                            visible:        parent.active
                        }

                        QGCMouseArea {
                            anchors.fill:   parent
                            onClicked:      radioRoot.currentTab = index
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth:       true
                Layout.topMargin:       -radioRoot.spacing
                implicitHeight:         1
                color:                  radioRoot._cardBorder
            }

            // ---- Mapping banner (shown on every tab) ------------------------
            Rectangle {
                id:                 mappingBanner
                Layout.fillWidth:   true
                implicitHeight:     bannerRow.implicitHeight + ScreenTools.defaultFontPixelHeight
                radius:             ScreenTools.defaultFontPixelWidth
                visible:            radioRoot._vehicle !== null
                color:              Qt.rgba(bannerColor.r, bannerColor.g, bannerColor.b, 0.12)
                border.width:       1
                border.color:       Qt.rgba(bannerColor.r, bannerColor.g, bannerColor.b, 0.6)

                property color bannerColor: !radioRoot._vehicleMapped ? radioRoot._red : (radioRoot._vehicleIsAETR ? radioRoot._green : radioRoot._amber)

                RowLayout {
                    id:                 bannerRow
                    anchors.left:       parent.left
                    anchors.right:      parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins:    ScreenTools.defaultFontPixelWidth * 1.5
                    spacing:            ScreenTools.defaultFontPixelWidth * 1.5

                    Rectangle {
                        width:      ScreenTools.defaultFontPixelHeight * 1.6
                        height:     width
                        radius:     width / 2
                        color:      mappingBanner.bannerColor
                        QGCLabel {
                            anchors.centerIn:   parent
                            text:               radioRoot._vehicleMapped && radioRoot._vehicleIsAETR ? "✓" : "!"
                            font.bold:          true
                            color:              "#0B0D0C"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth:   true
                        spacing:            0
                        QGCLabel {
                            Layout.fillWidth:   true
                            font.bold:          true
                            text: !radioRoot._vehicleMapped
                                  ? qsTr("Stick channels are not fully mapped on the vehicle")
                                  : (radioRoot._vehicleIsAETR
                                     ? qsTr("Vehicle uses the standard AETR order (CH1 Roll, CH2 Pitch, CH3 Throttle, CH4 Yaw)")
                                     : qsTr("Vehicle channel order is not AETR"))
                        }
                        QGCLabel {
                            Layout.fillWidth:   true
                            wrapMode:           Text.WordWrap
                            color:              radioRoot._muted
                            text: !radioRoot._vehicleMapped
                                  ? qsTr("Run the calibration in tab 3 before flying.")
                                  : (radioRoot._vehicleIsAETR
                                     ? (radioRoot.remoteDetected ? "" : qsTr("Flynus remote not detected yet: the remote side cannot be compared."))
                                     : qsTr("Vehicle: Roll CH%1, Pitch CH%2, Throttle CH%3, Yaw CH%4. Flynus remotes output AETR by default - make sure the remote and the vehicle match, or the sticks will control the wrong axes.")
                                           .arg(radioRoot._mapRoll).arg(radioRoot._mapPitch).arg(radioRoot._mapThrottle).arg(radioRoot._mapYaw))
                            visible:            text !== ""
                        }
                    }
                }
            }

            // ---- Tab content ------------------------------------------------
            Loader {
                id:                     tabLoader
                Layout.fillWidth:       true
                Layout.preferredHeight: item ? item.height : 0
                sourceComponent:        [ pairingTab, channelsTab, calibrationTab, checkTab ][radioRoot.currentTab]
                onLoaded:               item.width = Qt.binding(function() { return tabLoader.width })
            }

            Component {
                id: pairingTab

                ColumnLayout {
                    spacing: ScreenTools.defaultFontPixelHeight * 0.8

                    RemotePlaceholder {
                        Layout.fillWidth:   true
                        title:              qsTr("PAIR AIR UNIT")
                        body:               qsTr("Flynus remote not detected. Connect the Flynus remote (USB or network) to pair the air unit with the ground unit. Pairing requires remote firmware with the Flynus GCS protocol.")
                    }

                    RowLayout {
                        spacing:    ScreenTools.defaultFontPixelWidth
                        enabled:    radioRoot.remoteDetected
                        opacity:    enabled ? 1 : 0.4

                        QGCButton { text: qsTr("Start Pairing"); primary: true }
                        QGCButton { text: qsTr("Cancel") }
                    }
                }
            }

            Component {
                id: channelsTab

                ColumnLayout {
                    spacing: ScreenTools.defaultFontPixelHeight * 0.8

                    RemotePlaceholder {
                        Layout.fillWidth:   true
                        title:              qsTr("REMOTE CHANNEL ORDER")
                        body:               qsTr("Flynus remote not detected. Here you will set the channel order the remote outputs (AETR / TAER), the stick mode (Mode 1 / Mode 2) and which button or knob drives each channel. Settings are saved in the remote.")
                    }

                    Row {
                        spacing:    ScreenTools.defaultFontPixelWidth
                        enabled:    radioRoot.remoteDetected
                        opacity:    enabled ? 1 : 0.4

                        Repeater {
                            model: [ "AETR", "TAER", qsTr("Mode 2"), qsTr("Mode 1") ]
                            Rectangle {
                                width:          presetLabel.contentWidth + ScreenTools.defaultFontPixelWidth * 3
                                height:         presetLabel.contentHeight + ScreenTools.defaultFontPixelHeight * 0.6
                                radius:         height / 2
                                color:          "transparent"
                                border.width:   1
                                border.color:   radioRoot._cardBorder
                                QGCLabel {
                                    id:                 presetLabel
                                    anchors.centerIn:   parent
                                    text:               modelData
                                    font.bold:          true
                                }
                            }
                        }
                    }
                }
            }

            Component {
                id: calibrationTab

                Item {
                    height: calibrationLoader.item ? calibrationLoader.item.height : 0

                    Loader {
                        id:                 calibrationLoader
                        width:              parent.width
                        sourceComponent:    stockCalibration
                    }
                }
            }

            Component {
                id: checkTab

                RowLayout {
                    spacing: ScreenTools.defaultFontPixelWidth * 2

                    RCChannelMonitorController { id: monitorController }

                    // Remote output (phase 2)
                    RemotePlaceholder {
                        Layout.fillWidth:       true
                        Layout.alignment:       Qt.AlignTop
                        Layout.preferredWidth:  1
                        title:                  qsTr("REMOTE OUTPUT")
                        body:                   qsTr("Flynus remote not detected. When connected, the channels the remote sends are shown here next to the vehicle's, and mismatches are highlighted in red.")
                    }

                    // Vehicle input
                    Rectangle {
                        Layout.fillWidth:       true
                        Layout.alignment:       Qt.AlignTop
                        Layout.preferredWidth:  1
                        implicitHeight:         vehicleColumn.implicitHeight + ScreenTools.defaultFontPixelHeight * 2
                        radius:                 ScreenTools.defaultFontPixelWidth * 1.4
                        color:                  radioRoot._cardColor
                        border.width:           1
                        border.color:           radioRoot._cardBorder

                        ColumnLayout {
                            id:                 vehicleColumn
                            anchors.left:       parent.left
                            anchors.right:      parent.right
                            anchors.top:        parent.top
                            anchors.margins:    ScreenTools.defaultFontPixelWidth * 2
                            spacing:            ScreenTools.defaultFontPixelHeight * 0.3

                            QGCLabel {
                                text:               qsTr("VEHICLE RECEIVES")
                                font.bold:          true
                                font.letterSpacing: 1.5
                                color:              radioRoot._muted
                            }

                            Connections {
                                target: monitorController
                                function onChannelValueChanged(channel, rcValue) {
                                    var row = channelRepeater.itemAt(channel)
                                    if (row) {
                                        row.rcValue = rcValue
                                    }
                                }
                            }

                            Repeater {
                                id:     channelRepeater
                                model:  monitorController.channelCount

                                RowLayout {
                                    Layout.fillWidth:   true
                                    spacing:            ScreenTools.defaultFontPixelWidth

                                    property int    rcValue:    1500
                                    property string func:       radioRoot._functionForChannel(index + 1)

                                    QGCLabel {
                                        Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 5
                                        text:                   "CH" + (index + 1)
                                    }
                                    QGCLabel {
                                        Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 13
                                        text:                   parent.func
                                        font.bold:              parent.func !== ""
                                        color:                  parent.func !== "" ? qgcPal.text : radioRoot._muted
                                    }
                                    Item {
                                        Layout.fillWidth:       true
                                        implicitHeight:         ScreenTools.defaultFontPixelHeight * 0.6

                                        Rectangle {
                                            anchors.fill:   parent
                                            radius:         height / 2
                                            color:          Qt.rgba(1, 1, 1, 0.08)
                                        }
                                        Rectangle {
                                            height:     parent.height
                                            radius:     height / 2
                                            color:      radioRoot._green
                                            readonly property real _frac: Math.max(0, Math.min(1, (parent.parent.rcValue - 1000) / 1000))
                                            x:          0
                                            width:      parent.width * _frac
                                        }
                                    }
                                    QGCLabel {
                                        Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 5
                                        horizontalAlignment:    Text.AlignRight
                                        text:                   parent.rcValue
                                        color:                  radioRoot._muted
                                        font.pointSize:         ScreenTools.smallFontPointSize
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ---- Stock QGC calibration (unchanged) ---------------------------
            Component {
                id: stockCalibration

                RemoteControlCalibration {
                    id: remoteControlCalibration

                    useDeadband: false

                    controller: RadioComponentController {
                        statusText: remoteControlCalibration.statusText
                        cancelButton: remoteControlCalibration.cancelButton
                        nextButton: remoteControlCalibration.nextButton
                        joystickMode: false

                        onThrottleReversedCalFailure: QGroundControl.showMessageDialog(radioPage, qsTr("Throttle channel reversed"), qsTr("Calibration failed. The throttle channel on your transmitter is reversed. You must correct this on your transmitter in order to complete calibration."))
                    }

                    Component.onCompleted: controller.start()

                    additionalSetupComponent: ColumnLayout {
                        spacing: ScreenTools.defaultFontPixelHeight / 2

                        ColumnLayout {
                            id: switchSettings
                            Layout.fillWidth: true

                            Repeater {
                                model: QGroundControl.multiVehicleManager.activeVehicle.px4Firmware ?
                                            (QGroundControl.multiVehicleManager.activeVehicle.multiRotor ?
                                                [ "RC_MAP_AUX1", "RC_MAP_AUX2", "RC_MAP_PARAM1", "RC_MAP_PARAM2", "RC_MAP_PARAM3", "RC_MAP_PAY_SW"] :
                                                [ "RC_MAP_FLAPS", "RC_MAP_AUX1", "RC_MAP_AUX2", "RC_MAP_PARAM1", "RC_MAP_PARAM2", "RC_MAP_PARAM3", "RC_MAP_PAY_SW"]) :
                                            0

                                LabelledFactComboBox {
                                    label: fact.shortDescription
                                    fact: controller.getParameterFact(-1, modelData)
                                    indexModel: false
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 1
                            color: qgcPal.text
                        }

                        RowLayout {
                            spacing: ScreenTools.defaultFontPixelWidth

                            QGCButton {
                                id: bindButton
                                text: qsTr("Spektrum Bind")
                                onClicked: spektrumBindDialogFactory.open()
                            }

                            QGCButton {
                                text: qsTr("CRSF Bind")
                                onClicked: QGroundControl.showMessageDialog(radioPage, qsTr("CRSF Bind"),
                                                                        qsTr("Click Ok to place your CRSF receiver in the bind mode."),
                                                                        Dialog.Ok | Dialog.Cancel,
                                                                        function() { controller.crsfBindMode() })
                            }

                            QGCButton {
                                text: qsTr("Copy Trims")
                                onClicked: QGroundControl.showMessageDialog(radioPage, qsTr("Copy Trims"),
                                                                        qsTr("Center your sticks and move throttle all the way down, then press Ok to copy trims. After pressing Ok, reset the trims on your radio back to zero."),
                                                                        Dialog.Ok | Dialog.Cancel,
                                                                        function() { controller.copyTrims() })
                            }
                        }

                        QGCPopupDialogFactory {
                            id: spektrumBindDialogFactory

                            dialogComponent: spektrumBindDialogComponent
                        }

                        Component {
                            id: spektrumBindDialogComponent

                            QGCPopupDialog {
                                title: qsTr("Spektrum Bind")
                                buttons: Dialog.Ok | Dialog.Cancel

                                onAccepted: { controller.spektrumBindMode(radioGroup.checkedButton.bindMode) }

                                ButtonGroup { id: radioGroup }

                                ColumnLayout {
                                    spacing: ScreenTools.defaultFontPixelHeight / 2

                                    QGCLabel {
                                        wrapMode: Text.WordWrap
                                        text: qsTr("Click Ok to place your Spektrum receiver in the bind mode.")
                                    }

                                    QGCLabel {
                                        wrapMode: Text.WordWrap
                                        text: qsTr("Select the specific receiver type below:")
                                    }

                                    QGCRadioButton {
                                        text: qsTr("DSM2 Mode")
                                        ButtonGroup.group: radioGroup
                                        property int bindMode: RadioComponentController.DSM2
                                    }

                                    QGCRadioButton {
                                        text: qsTr("DSMX (7 channels or less)")
                                        ButtonGroup.group: radioGroup
                                        property int bindMode: RadioComponentController.DSMX7
                                    }

                                    QGCRadioButton {
                                        checked: true
                                        text: qsTr("DSMX (8 channels or more)")
                                        ButtonGroup.group: radioGroup
                                        property int bindMode: RadioComponentController.DSMX8
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
