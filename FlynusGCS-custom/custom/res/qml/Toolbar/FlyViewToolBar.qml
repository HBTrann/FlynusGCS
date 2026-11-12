import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlyView
import QGroundControl.Toolbar

// Flynus GCS override of the stock FlyViewToolBar.qml:
// the top bar shows the logo (menu) and guided action confirmations on a
// transparent gradient. Status, battery, GPS,
// RC/telemetry signal and the other indicators live in the left side panel
// (see custom/res/qml/FlyView/FlyViewCustomLayer.qml).
Item {
    required property var guidedValueSlider

    id:     control
    width:  parent.width
    height: ScreenTools.toolbarHeight

    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle
    property bool   _communicationLost: _activeVehicle ? _activeVehicle.vehicleLinkManager.communicationLost : false
    property color  _mainStatusBGColor: qgcPal.brandingPurple
    property real   _leftRightMargin:   ScreenTools.defaultFontPixelWidth * 0.75
    property var    _guidedController:  globals.guidedControllerFlyView

    function dropMainStatusIndicatorTool() {
        mainStatusIndicator.dropMainStatusIndicator();
    }

    QGCPalette { id: qgcPal }

    // Flynus: transparent top bar with a soft dark gradient instead of a solid bar
    Rectangle {
        anchors.fill:   parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.75) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.0) }
        }
    }

    QGCFlickable {
        anchors.fill:       parent
        contentWidth:       toolBarLayout.width
        flickableDirection: Flickable.HorizontalFlick

        Row {
            id:         toolBarLayout
            height:     parent.height
            spacing:    0

            Item {
                id:     leftPanel
                width:  leftPanelLayout.implicitWidth
                height: parent.height

                RowLayout {
                    id:         leftPanelLayout
                    height:     parent.height
                    spacing:    ScreenTools.defaultFontPixelWidth * 2

                    RowLayout {
                        id:         mainStatusLayout
                        height:     parent.height
                        spacing:    0

                        QGCToolBarButton {
                            id:                 qgcButton
                            objectName:         "toolbar_qgcLogo"
                            Layout.fillHeight:  true
                            icon.source:        "/res/QGCLogoFull.svg"
                            logo:               true
                            showPageNavigation: !guidedActionConfirm.visible
                            onClicked:          mainWindow.showToolSelectDialog()
                        }

                        // Kept (hidden) so dropMainStatusIndicatorTool() keeps working;
                        // the visible status indicator is in the left side panel.
                        MainStatusIndicator {
                            id:                 mainStatusIndicator
                            objectName:         "toolbar_mainStatusIndicator"
                            Layout.fillHeight:  true
                            visible:            false
                        }
                    }

                    QGCButton {
                        id:         disconnectButton
                        text:       qsTr("Disconnect")
                        onClicked:  _activeVehicle.closeVehicle()
                        visible:    _activeVehicle && _communicationLost
                    }

                }
            }
            Item {
                id:     centerPanel
                // center panel takes up all remaining space in toolbar between left and right panels
                width:  Math.max(guidedActionConfirm.visible ? guidedActionConfirm.width : 0, control.width - (leftPanel.width + rightPanel.width))
                height: parent.height

                GuidedActionConfirm {
                    id:                         guidedActionConfirm
                    height:                     parent.height
                    anchors.horizontalCenter:   parent.horizontalCenter
                    guidedController:           control._guidedController
                    guidedValueSlider:          control.guidedValueSlider
                    messageDisplay:             guidedActionMessageDisplay
                }
            }

            // Indicators moved to the left side panel
            Item {
                id:     rightPanel
                width:  0
                height: parent.height
            }
        }
    }

    // The guided action message display is outside of the GuidedActionConfirm control so that it doesn't end up as
    // part of the Flickable
    Rectangle {
        id:                         guidedActionMessageDisplay
        anchors.top:                control.bottom
        anchors.topMargin:          _margins
        x:                          control.mapFromItem(guidedActionConfirm.parent, guidedActionConfirm.x, 0).x + (guidedActionConfirm.width - guidedActionMessageDisplay.width) / 2
        width:                      messageLabel.contentWidth + (_margins * 2)
        height:                     messageLabel.contentHeight + (_margins * 2)
        color:                      qgcPal.windowTransparent
        radius:                     ScreenTools.defaultBorderRadius
        visible:                    guidedActionConfirm.visible

        QGCLabel {
            id:         messageLabel
            x:          _margins
            y:          _margins
            width:      ScreenTools.defaultFontPixelWidth * 30
            wrapMode:   Text.WordWrap
            text:       guidedActionConfirm.message
        }

        PropertyAnimation {
            id:         messageOpacityAnimation
            target:     guidedActionMessageDisplay
            property:   "opacity"
            from:       1
            to:         0
            duration:   500
        }

        Timer {
            id:             messageFadeTimer
            interval:       4000
            onTriggered:    messageOpacityAnimation.start()
        }
    }

    ParameterDownloadProgress {
        anchors.fill: parent
    }
}
