import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import QtLocation
import QtPositioning
import QtQuick.Window
import QtQml.Models

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlyView
import QGroundControl.FlightMap
import QGroundControl.Viewer3D
import QGroundControl.Toolbar

// This is the ui overlay layer for the widgets/tools for Fly View
// Flynus GCS override: a status/indicator panel (Ready, flight-time ring, battery, GPS, RC, telemetry, ...)
// sits at the top-left; the Takeoff/Return tool strip is placed below it in the same
// column, so extra tool strip buttons never move the status panel.
// Navigation buttons: Plan/Configure/Analyze/Settings bottom-left, Close bottom-right.
Item {
    id: _root

    property var    parentToolInsets
    property var    totalToolInsets:        _totalToolInsets
    property var    mapControl
    property var    viewer3DCameraController

    property var    _activeVehicle:         QGroundControl.multiVehicleManager.activeVehicle
    property var    _planMasterController:  globals.planMasterControllerFlyView
    property var    _missionController:     _planMasterController.missionController
    property var    _geoFenceController:    _planMasterController.geoFenceController
    property var    _rallyPointController:  _planMasterController.rallyPointController
    property var    _guidedController:      globals.guidedControllerFlyView
    property real   _margins:               ScreenTools.defaultFontPixelWidth / 2
    property real   _toolsMargin:           ScreenTools.defaultFontPixelWidth * 0.75
    property rect   _centerViewport:        Qt.rect(0, 0, width, height)
    property real   _rightPanelWidth:       ScreenTools.defaultFontPixelWidth * 30
    property real   _layoutMargin:          ScreenTools.defaultFontPixelWidth * 0.75
    property bool   _layoutSpacing:         ScreenTools.defaultFontPixelWidth
    property bool   _showSingleVehicleUI:   true

    QGCToolInsets {
        id:                     _totalToolInsets
        leftEdgeTopInset:       Math.max(toolStrip.leftEdgeTopInset, statusPanel.leftEdgeTopInset)
        leftEdgeCenterInset:    toolStrip.leftEdgeCenterInset
        leftEdgeBottomInset:    Math.max(navPanelLeft.visible ? navPanelLeft.width : 0, virtualJoystickMultiTouch.visible ? virtualJoystickMultiTouch.leftEdgeBottomInset : parentToolInsets.leftEdgeBottomInset)
        rightEdgeTopInset:      topRightPanel.rightEdgeTopInset
        rightEdgeCenterInset:   topRightPanel.rightEdgeCenterInset
        rightEdgeBottomInset:   Math.max(bottomRightRowLayout.rightEdgeBottomInset, navPanelRight.visible ? navPanelRight.width + _layoutMargin : 0)
        topEdgeLeftInset:       toolStrip.topEdgeLeftInset
        topEdgeCenterInset:     mapScale.topEdgeCenterInset
        topEdgeRightInset:      topRightPanel.topEdgeRightInset
        bottomEdgeLeftInset:    Math.max(navPanelLeft.visible ? navPanelLeft.height + navPanelLeft.anchors.bottomMargin : 0, virtualJoystickMultiTouch.visible ? virtualJoystickMultiTouch.bottomEdgeLeftInset : parentToolInsets.bottomEdgeLeftInset)
        bottomEdgeCenterInset:  bottomRightRowLayout.bottomEdgeCenterInset
        bottomEdgeRightInset:   Math.max(navPanelRight.visible ? navPanelRight.height + _layoutMargin : 0, virtualJoystickMultiTouch.visible ? virtualJoystickMultiTouch.bottomEdgeRightInset : bottomRightRowLayout.bottomEdgeRightInset)
    }

    FlyViewTopRightPanel {
        id:                     topRightPanel
        anchors.top:            parent.top
        anchors.right:          parent.right
        maximumHeight:          parent.height - (bottomRightRowLayout.height + _margins * 4)

        property real topEdgeRightInset:    height + _layoutMargin
        property real rightEdgeTopInset:    width + _layoutMargin
        property real rightEdgeCenterInset: rightEdgeTopInset
    }

    FlyViewTopRightColumnLayout {
        id:                 topRightColumnLayout
        anchors.top:        parent.top
        anchors.right:      parent.right
        spacing:            _layoutSpacing
        visible:           !topRightPanel.visible

        property real topEdgeRightInset:    childrenRect.height + _layoutMargin
        property real rightEdgeTopInset:    width + _layoutMargin
        property real rightEdgeCenterInset: rightEdgeTopInset
    }

    FlyViewBottomRightRowLayout {
        id:                 bottomRightRowLayout
        anchors.bottom:     parent.bottom
        anchors.right:      parent.right
        spacing:            _layoutSpacing

        property real bottomEdgeRightInset:     height + _layoutMargin
        property real bottomEdgeCenterInset:    bottomEdgeRightInset
        property real rightEdgeBottomInset:     width + _layoutMargin
    }

    FlyViewMissionCompleteDialog {
        missionController:      _missionController
        geoFenceController:     _geoFenceController
        rallyPointController:   _rallyPointController
    }

    // Prevent the map's PinchHandler from stealing touch grabs from the joystick pads (issue #13450)
    Binding {
        target:   mapControl
        property: "pinchZoomDisabledByVirtualJoysticks"
        value:    virtualJoystickMultiTouch.visible && virtualJoystickMultiTouch.item && virtualJoystickMultiTouch.item.stickActive
    }

    //-- Virtual Joystick
    Loader {
        id:                         virtualJoystickMultiTouch
        z:                          QGroundControl.zOrderTopMost + 1
        anchors.right:              parent.right
        anchors.rightMargin:        anchors.leftMargin
        height:                     Math.min(parent.height * 0.25, ScreenTools.defaultFontPixelWidth * 16)
        visible:                    _virtualJoystickEnabled && !QGroundControl.videoManager.fullScreen && !(_activeVehicle ? _activeVehicle.usingHighLatencyLink : false)
        anchors.bottom:             parent.bottom
        anchors.bottomMargin:       bottomLoaderMargin
        anchors.left:               parent.left
        anchors.leftMargin:         ( y > toolStrip.y + toolStrip.height ? toolStrip.width / 2 : toolStrip.width * 1.05 + toolStrip.x)
        source:                     "qrc:/qml/QGroundControl/FlyView/VirtualJoystick.qml"
        active:                     _virtualJoystickEnabled && !(_activeVehicle ? _activeVehicle.usingHighLatencyLink : false)

        property real bottomEdgeLeftInset:     parent.height-y
        property bool autoCenterThrottle:      QGroundControl.settingsManager.appSettings.virtualJoystickAutoCenterThrottle.rawValue
        property bool leftHandedMode:          QGroundControl.settingsManager.appSettings.virtualJoystickLeftHandedMode.rawValue
        property bool _virtualJoystickEnabled: QGroundControl.settingsManager.appSettings.virtualJoystick.rawValue
        property real bottomEdgeRightInset:    parent.height-y
        property var  _pipViewMargin:          _pipView.visible ? parentToolInsets.bottomEdgeLeftInset + ScreenTools.defaultFontPixelHeight * 2 :
                                               bottomRightRowLayout.height + ScreenTools.defaultFontPixelHeight * 1.5

        property var  bottomLoaderMargin:      _pipViewMargin >= parent.height / 2 ? parent.height / 2 : _pipViewMargin

        // Width is difficult to access directly hence this hack which may not work in all circumstances
        property real leftEdgeBottomInset:  visible ? bottomEdgeLeftInset + width/18 - ScreenTools.defaultFontPixelHeight*2 : 0
        property real rightEdgeBottomInset: visible ? bottomEdgeRightInset + width/18 - ScreenTools.defaultFontPixelHeight*2 : 0
        property real rootWidth:            _root.width
        property var  itemX:                virtualJoystickMultiTouch.x   // real X on screen

        onRootWidthChanged: virtualJoystickMultiTouch.status == Loader.Ready && visible ? virtualJoystickMultiTouch.item.uiTotalWidth = rootWidth : undefined
        onItemXChanged:     virtualJoystickMultiTouch.status == Loader.Ready && visible ? virtualJoystickMultiTouch.item.uiRealX = itemX : undefined

        //Loader status logic
        onLoaded: {
            if (virtualJoystickMultiTouch.visible) {
                virtualJoystickMultiTouch.item.calibration = true
                virtualJoystickMultiTouch.item.uiTotalWidth = rootWidth
                virtualJoystickMultiTouch.item.uiRealX = itemX
            } else {
                virtualJoystickMultiTouch.item.calibration = false
            }
        }
    }

    // ---- Flynus: battery / remaining flight time ring -----------------------
    // Remaining time comes from the flight controller (BATTERY_STATUS.time_remaining)
    // when available; otherwise it is estimated from the discharge rate since arming
    // (shown with "~"). Without enough data the ring shows the battery percentage.
    property var  _battery:          _activeVehicle && _activeVehicle.batteries.count > 0 ? _activeVehicle.batteries.get(0) : null
    property real _battPercent:      _battery ? _battery.percentRemaining.rawValue : NaN
    property real _fcTimeRemaining:  _battery ? _battery.timeRemaining.rawValue : NaN   // seconds
    property bool _hasBattPercent:   !isNaN(_battPercent)
    property real _armPercent:       NaN
    property real _armTimeMs:        0
    property real _estTimeRemaining: NaN
    property real _remainingSec:     !isNaN(_fcTimeRemaining) && _fcTimeRemaining > 0 ? _fcTimeRemaining : _estTimeRemaining
    property bool _timeIsEstimate:   isNaN(_fcTimeRemaining) || _fcTimeRemaining <= 0

    function _battColor() {
        if (_battPercent <= 15) return "#BC0814"
        if (_battPercent <= 30) return "#F5B700"
        return "#2FBF4A"
    }

    function _resetFlightTimeEstimate() {
        _armPercent = NaN
        _armTimeMs = 0
        _estTimeRemaining = NaN
    }

    on_ActiveVehicleChanged: _resetFlightTimeEstimate()

    Connections {
        target:                 _activeVehicle
        ignoreUnknownSignals:   true
        function onArmedChanged(armed) {
            if (armed && _hasBattPercent) {
                _armPercent = _battPercent
                _armTimeMs  = Date.now()
                _estTimeRemaining = NaN
            } else if (!armed) {
                _resetFlightTimeEstimate()
            }
        }
    }

    Timer {
        interval:   2000
        repeat:     true
        running:    _activeVehicle && _activeVehicle.armed && _hasBattPercent
        onTriggered: {
            if (isNaN(_armPercent)) {
                _armPercent = _battPercent
                _armTimeMs  = Date.now()
                return
            }
            var used = _armPercent - _battPercent
            var elapsedSec = (Date.now() - _armTimeMs) / 1000
            // Need at least 2% used and 30 s of data for a usable rate
            if (used >= 2 && elapsedSec >= 30) {
                _estTimeRemaining = _battPercent * elapsedSec / used
            }
        }
    }

    // ---- Flynus: status + indicator panel (top-left) -------------------------
    property real _indicatorHeight: ScreenTools.toolbarHeight * 0.7
    // MainStatusIndicator reads/writes these from its parent context (normally FlyViewToolBar)
    property bool  _communicationLost:  _activeVehicle ? _activeVehicle.vehicleLinkManager.communicationLost : false
    property color _mainStatusBGColor:  QGroundControl.globalPalette.brandingPurple

    Rectangle {
        id:         statusPanel
        anchors.left:   parent.left
        anchors.top:    parent.top
        anchors.topMargin: _toolsMargin
        width:      statusColumn.width + _toolsMargin * 2
        height:     statusColumn.height + _toolsMargin * 2
        radius:     ScreenTools.defaultFontPixelWidth / 2
        color:      Qt.rgba(QGroundControl.globalPalette.window.r, QGroundControl.globalPalette.window.g, QGroundControl.globalPalette.window.b, 0.75)
        z:          QGroundControl.zOrderWidgets
        visible:    !QGroundControl.videoManager.fullScreen

        property real leftEdgeTopInset: visible ? x + width : 0

        Column {
            id:         statusColumn
            x:          _toolsMargin
            y:          _toolsMargin
            spacing:    _toolsMargin

            // Ready / Not Ready / Armed / Disconnected (click for details, arm, connect)
            Item {
                width:  mainStatus.width + _toolsMargin * 2
                height: _indicatorHeight

                // Status color strip (green = ready/armed OK, yellow = warnings, red = not ready / comms lost)
                Rectangle {
                    anchors.fill:   parent
                    radius:         ScreenTools.defaultFontPixelWidth / 2
                    color:          _mainStatusBGColor
                    opacity:        0.35
                }

                MainStatusIndicator {
                    id:             mainStatus
                    x:              _toolsMargin
                    height:         parent.height
                }
            }

            // Remaining flight time ring: the bright arc shrinks as the battery is used,
            // the used part stays faded. Center: remaining minutes (or % if unknown).
            Item {
                id:         flightTimeRing
                width:      ScreenTools.defaultFontPixelHeight * 3.6
                height:     width
                anchors.horizontalCenter: parent.horizontalCenter
                visible:    _activeVehicle && _hasBattPercent

                property real  fraction:  Math.max(0, Math.min(100, _battPercent)) / 100
                property color arcColor:  _battColor()
                property real  lineWidth: width * 0.11

                onFractionChanged:  ringCanvas.requestPaint()
                onArcColorChanged:  ringCanvas.requestPaint()

                Canvas {
                    id:             ringCanvas
                    anchors.fill:   parent
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.reset()
                        var r = (width - flightTimeRing.lineWidth) / 2
                        var cx = width / 2
                        var cy = height / 2
                        var start = -Math.PI / 2
                        ctx.lineWidth = flightTimeRing.lineWidth
                        ctx.lineCap = "round"
                        // Used part (faded full circle)
                        ctx.globalAlpha = 0.25
                        ctx.strokeStyle = flightTimeRing.arcColor
                        ctx.beginPath()
                        ctx.arc(cx, cy, r, 0, 2 * Math.PI, false)
                        ctx.stroke()
                        // Remaining part (bright), clockwise from 12 o'clock
                        if (flightTimeRing.fraction > 0) {
                            ctx.globalAlpha = 1.0
                            ctx.beginPath()
                            ctx.arc(cx, cy, r, start, start + 2 * Math.PI * flightTimeRing.fraction, false)
                            ctx.stroke()
                        }
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 0

                    QGCLabel {
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.bold:      true
                        font.pointSize: ScreenTools.largeFontPointSize
                        text: {
                            if (!isNaN(_remainingSec)) {
                                return (_timeIsEstimate ? "~" : "") + Math.floor(Math.max(0, _remainingSec) / 60)
                            }
                            return Math.round(_battPercent) + "%"
                        }
                    }
                    QGCLabel {
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.pointSize: ScreenTools.smallFontPointSize
                        text:           qsTr("min")
                        visible:        !isNaN(_remainingSec)
                    }
                }
            }

            Repeater {
                model: QGroundControl.corePlugin.toolBarIndicators
                Loader {
                    height:     _indicatorHeight
                    source:     modelData
                    visible:    item ? item.showIndicator : false
                }
            }

            Repeater {
                model: _activeVehicle ? _activeVehicle.toolIndicators : []
                Loader {
                    height:     _indicatorHeight
                    source:     modelData
                    visible:    item ? item.showIndicator : false
                }
            }
        }
    }

    // ---- Flynus: navigation buttons ----------------------------------------
    // Bottom-left: Plan / Configure / Analyze / Settings. Bottom-right: Close.
    // (The logo menu still has all items for quick switching from any screen.)

    component FlynusNavButton: Rectangle {
        id:             navButton
        width:          navRow.width + _m * 3
        height:         ScreenTools.defaultFontPixelHeight * 2.2
        radius:         ScreenTools.defaultFontPixelWidth / 2
        color:          navMouse.pressed ? QGroundControl.globalPalette.buttonHighlight : "transparent"

        // Inline component: no access to the outer file's properties, so keep sizes local
        readonly property real _m: ScreenTools.defaultFontPixelWidth * 0.75
        property string text
        property string iconSource
        signal clicked()

        Row {
            id:                 navRow
            anchors.verticalCenter: parent.verticalCenter
            x:                  _m * 1.5
            spacing:            ScreenTools.defaultFontPixelWidth

            QGCColoredImage {
                anchors.verticalCenter: parent.verticalCenter
                width:              ScreenTools.defaultFontPixelHeight * 1.2
                height:             width
                sourceSize.height:  height
                source:             navButton.iconSource
                color:              navMouse.pressed ? QGroundControl.globalPalette.buttonHighlightText : QGroundControl.globalPalette.text
                fillMode:           Image.PreserveAspectFit
            }

            QGCLabel {
                anchors.verticalCenter: parent.verticalCenter
                text:   navButton.text
                color:  navMouse.pressed ? QGroundControl.globalPalette.buttonHighlightText : QGroundControl.globalPalette.text
            }
        }

        QGCMouseArea {
            id:             navMouse
            anchors.fill:   parent
            onClicked:      navButton.clicked()
        }
    }

    Rectangle {
        id:                     navPanelLeft
        anchors.left:           parent.left
        anchors.bottom:         parent.bottom
        anchors.bottomMargin:   parentToolInsets.bottomEdgeLeftInset
        width:                  navColumn.width + _toolsMargin * 2
        height:                 navColumn.height + _toolsMargin * 2
        radius:                 ScreenTools.defaultFontPixelWidth / 2
        color:                  Qt.rgba(QGroundControl.globalPalette.window.r, QGroundControl.globalPalette.window.g, QGroundControl.globalPalette.window.b, 0.75)
        z:                      QGroundControl.zOrderWidgets
        visible:                !QGroundControl.videoManager.fullScreen

        Column {
            id:         navColumn
            x:          _toolsMargin
            y:          _toolsMargin
            spacing:    _toolsMargin / 2

            FlynusNavButton {
                objectName: "flynus_navPlan"
                text:       qsTr("Plan")
                iconSource: "/qmlimages/Plan.svg"
                onClicked:  if (mainWindow.allowViewSwitch()) mainWindow.showPlanView()
            }
            FlynusNavButton {
                objectName: "flynus_navConfigure"
                text:       qsTr("Configure")
                iconSource: "/res/GearWithPaperPlane.svg"
                onClicked:  if (mainWindow.allowViewSwitch()) mainWindow.showVehicleConfig()
            }
            FlynusNavButton {
                objectName: "flynus_navAnalyze"
                text:       qsTr("Analyze")
                iconSource: "/qmlimages/Analyze.svg"
                visible:    QGroundControl.corePlugin.showAdvancedUI
                onClicked:  if (mainWindow.allowViewSwitch()) mainWindow.showAnalyzeTool()
            }
            FlynusNavButton {
                objectName: "flynus_navSettings"
                text:       qsTr("Settings")
                iconSource: "/qmlimages/Gears.svg"
                visible:    !QGroundControl.corePlugin.options.combineSettingsAndSetup
                onClicked:  if (mainWindow.allowViewSwitch()) mainWindow.showSettingsTool()
            }
        }
    }

    Rectangle {
        id:                     navPanelRight
        anchors.right:          parent.right
        anchors.bottom:         parent.bottom
        width:                  closeButton.width + _toolsMargin * 2
        height:                 closeButton.height + _toolsMargin * 2
        radius:                 ScreenTools.defaultFontPixelWidth / 2
        color:                  Qt.rgba(QGroundControl.globalPalette.window.r, QGroundControl.globalPalette.window.g, QGroundControl.globalPalette.window.b, 0.75)
        z:                      QGroundControl.zOrderWidgets
        visible:                !QGroundControl.videoManager.fullScreen

        FlynusNavButton {
            id:         closeButton
            objectName: "flynus_navClose"
            x:          _toolsMargin
            y:          _toolsMargin
            text:       qsTr("Close")
            iconSource: "/res/OpenDoor.svg"
            // Same as the stock menu: goes through the window close checks
            // (unsaved mission, pending parameters, active connection).
            onClicked:  if (mainWindow.allowViewSwitch()) mainWindow.close()
        }
    }

    FlyViewToolStrip {
        id:                     toolStrip
        anchors.left:           parent.left
        anchors.top:            statusPanel.bottom
        anchors.topMargin:      _toolsMargin
        z:                      QGroundControl.zOrderWidgets
        maxHeight:              parent.height - y - Math.max(parentToolInsets.bottomEdgeLeftInset, navPanelLeft.visible ? navPanelLeft.height + navPanelLeft.anchors.bottomMargin : 0) - _toolsMargin
        visible:                !QGroundControl.videoManager.fullScreen

        onDisplayPreFlightChecklist: {
            if (!preFlightChecklistLoader.active) {
                preFlightChecklistLoader.active = true
            }
            preFlightChecklistLoader.item.open()
        }

        property real topEdgeLeftInset:     visible ? y + height : 0
        property real leftEdgeTopInset:     visible ? x + width : 0
        property real leftEdgeCenterInset:  leftEdgeTopInset
    }

    VehicleWarnings {
        anchors.centerIn:   parent
        z:                  QGroundControl.zOrderTopMost
    }

    MapScale {
        id:                 mapScale
        anchors.left:       statusPanel.right
        anchors.leftMargin: _toolsMargin
        anchors.top:        parent.top
        mapControl:         _mapControl
        autoHide:           true
        visible:            !ScreenTools.isTinyScreen && QGroundControl.corePlugin.options.flyView.showMapScale && QGCViewer3DManager.displayMode !== QGCViewer3DManager.View3D && mapControl.pipState.state === mapControl.pipState.fullState

        property real topEdgeCenterInset: visible ? y + height : 0
    }

    Viewer3DScaleBar {
        objectName:         "viewer3DScaleBar"
        anchors.left:       statusPanel.right
        anchors.leftMargin: _toolsMargin
        anchors.top:        parent.top
        controller:         _root.viewer3DCameraController
        autoHide:           true
        visible:            !ScreenTools.isTinyScreen && QGroundControl.corePlugin.options.flyView.showMapScale && QGCViewer3DManager.displayMode === QGCViewer3DManager.View3D && !!_root.viewer3DCameraController
    }

    Loader {
        id: preFlightChecklistLoader
        sourceComponent: preFlightChecklistPopup
        active: false
    }

    Component {
        id: preFlightChecklistPopup
        FlyViewPreFlightChecklistPopup {
        }
    }
}
