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
        leftEdgeBottomInset:    virtualJoystickMultiTouch.visible ? virtualJoystickMultiTouch.leftEdgeBottomInset : parentToolInsets.leftEdgeBottomInset
        rightEdgeTopInset:      topRightPanel.rightEdgeTopInset
        rightEdgeCenterInset:   Math.max(topRightPanel.rightEdgeCenterInset, actionViewport.rightEdgeCenterInset)
        rightEdgeBottomInset:   Math.max(bottomRightRowLayout.rightEdgeBottomInset, navPanelRight.visible ? navPanelRight.width + _layoutMargin : 0)
        topEdgeLeftInset:       toolStrip.topEdgeLeftInset
        topEdgeCenterInset:     mapScale.topEdgeCenterInset
        topEdgeRightInset:      topRightPanel.topEdgeRightInset
        bottomEdgeLeftInset:    virtualJoystickMultiTouch.visible ? virtualJoystickMultiTouch.bottomEdgeLeftInset : parentToolInsets.bottomEdgeLeftInset
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

    on_ActiveVehicleChanged: {
        _resetFlightTimeEstimate()
        // Show the "waiting for connection" screen again after a disconnect
        if (!_activeVehicle) {
            _connectScreenDismissed = false
        }
    }

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

    // ---- Flynus Dark panel style ---------------------------------------------
    readonly property color _panelColor:    Qt.rgba(0.07, 0.086, 0.078, 0.78)
    readonly property color _panelBorder:   Qt.rgba(1, 1, 1, 0.10)
    readonly property real  _panelRadius:   ScreenTools.defaultFontPixelWidth * 1.4
    readonly property real  _panelPadding:  ScreenTools.defaultFontPixelWidth * 1.2
    readonly property color _flynusGreen:   "#2FBF4A"
    readonly property color _flynusAmber:   "#F5B700"
    readonly property color _flynusRed:     "#E0303B"
    readonly property color _mutedText:     "#9AA59D"

    // Flynus-styled replacements for some stock toolbar indicators. The stock indicator is
    // still loaded (invisible) on top so clicking the row opens its usual detail page.
    function _flynusIndicatorKind(url) {
        var u = url.toString()
        if (u.endsWith("/BatteryIndicator.qml"))       return "battery"
        if (u.endsWith("/VehicleGPSIndicator.qml"))    return "gps"
        if (u.endsWith("/RCRSSIIndicator.qml"))        return "rc"
        if (u.endsWith("/TelemetryRSSIIndicator.qml")) return "telemetry"
        return ""
    }

    component FlynusIndicatorRow: Row {
        id:         indRow
        spacing:    ScreenTools.defaultFontPixelWidth * 1.2

        property string iconSource
        property color  iconColor: "#2FBF4A"
        property string value
        property string caption

        QGCColoredImage {
            anchors.verticalCenter: parent.verticalCenter
            width:              ScreenTools.defaultFontPixelHeight * 1.5
            height:             width
            sourceSize.height:  height
            source:             indRow.iconSource
            color:              indRow.iconColor
            fillMode:           Image.PreserveAspectFit
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            QGCLabel {
                text:           indRow.value
                font.pointSize: ScreenTools.mediumFontPointSize
                font.bold:      true
            }
            QGCLabel {
                text:               indRow.caption
                color:              "#9AA59D"
                font.pointSize:     ScreenTools.smallFontPointSize
                font.letterSpacing: 1
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
        width:      statusColumn.width + _panelPadding * 2
        height:     statusColumn.height + _panelPadding * 2
        radius:     _panelRadius
        color:      _panelColor
        border.width: 1
        border.color: _panelBorder
        z:          QGroundControl.zOrderWidgets
        visible:    !QGroundControl.videoManager.fullScreen

        property real leftEdgeTopInset: visible ? x + width : 0

        Column {
            id:         statusColumn
            x:          _panelPadding
            y:          _panelPadding
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

                Item {
                    id:         indicatorCell
                    width:      kind !== "" ? Math.max(flynusRow.width, ScreenTools.defaultFontPixelWidth * 14) : (stockLoader.item ? stockLoader.item.width : 0)
                    height:     _indicatorHeight
                    visible:    stockLoader.item ? stockLoader.item.showIndicator : false

                    property string kind: _flynusIndicatorKind(modelData)

                    FlynusIndicatorRow {
                        id:                     flynusRow
                        anchors.verticalCenter: parent.verticalCenter
                        visible:                indicatorCell.kind !== ""
                        iconSource: {
                            switch (indicatorCell.kind) {
                            case "battery":   return "qrc:/flynus/icons/battery.svg"
                            case "gps":       return "qrc:/flynus/icons/gps.svg"
                            case "rc":        return "qrc:/flynus/icons/rc.svg"
                            case "telemetry": return "qrc:/flynus/icons/telemetry.svg"
                            }
                            return ""
                        }
                        iconColor: {
                            switch (indicatorCell.kind) {
                            case "battery":
                                if (isNaN(_battPercent)) return _mutedText
                                return _battPercent <= 15 ? _flynusRed : (_battPercent <= 30 ? _flynusAmber : _flynusGreen)
                            case "gps":
                                return _activeVehicle && _activeVehicle.gps.lock.rawValue >= 3 ? _flynusGreen : _flynusAmber
                            case "rc": {
                                var rssi = _activeVehicle ? _activeVehicle.rcRSSI.rawValue : 0
                                return rssi >= 60 ? _flynusGreen : (rssi >= 30 ? _flynusAmber : _flynusRed)
                            }
                            case "telemetry": {
                                var l = _activeVehicle ? _activeVehicle.radioStatus.lrssi.rawValue : 0
                                return l >= -80 ? _flynusGreen : (l >= -95 ? _flynusAmber : _flynusRed)
                            }
                            }
                            return _flynusGreen
                        }
                        value: {
                            if (!_activeVehicle) return "--"
                            switch (indicatorCell.kind) {
                            case "battery":   return isNaN(_battPercent) ? "--" : Math.round(_battPercent) + "%"
                            case "gps":       return _activeVehicle.gps.count.valueString
                            case "rc":        return _activeVehicle.rcRSSI.rawValue + "%"
                            case "telemetry": return String(_activeVehicle.radioStatus.lrssi.rawValue)
                            }
                            return ""
                        }
                        caption: {
                            if (!_activeVehicle) return ""
                            switch (indicatorCell.kind) {
                            case "battery":   return _battery && !isNaN(_battery.voltage.rawValue) ? _battery.voltage.rawValue.toFixed(1) + " V" : qsTr("BATTERY")
                            case "gps":       return qsTr("GPS") + " · " + _activeVehicle.gps.lock.enumStringValue
                            case "rc":        return qsTr("RC LINK")
                            case "telemetry": return qsTr("TELEMETRY dBm")
                            }
                            return ""
                        }
                    }

                    // Stock indicator: visible for the indicators we don't restyle; invisible but
                    // clickable (opacity 0) on top of the Flynus row for the ones we do.
                    Loader {
                        id:         stockLoader
                        height:     parent.height
                        source:     modelData
                        opacity:    indicatorCell.kind !== "" ? 0 : 1
                        onLoaded: {
                            if (indicatorCell.kind !== "") {
                                item.width = Qt.binding(function() { return indicatorCell.width })
                            }
                        }
                    }
                }
            }
        }
    }

    // ---- Flynus: square tile button (navigation) and round action button -----
    // Inline components have no access to the outer file's properties, so sizes/colours are local.
    component FlynusTileButton: Rectangle {
        id:             tile
        width:          ScreenTools.defaultFontPixelHeight * 3.6
        height:         width
        radius:         ScreenTools.defaultFontPixelWidth * 1.4
        color:          tileMouse.pressed ? "#2FBF4A" : Qt.rgba(0.07, 0.086, 0.078, 0.78)
        border.width:   1
        border.color:   Qt.rgba(1, 1, 1, 0.10)

        property string text
        property string iconSource
        property color  iconColor: "#F2F5F3"
        signal clicked()

        Column {
            anchors.centerIn:   parent
            spacing:            ScreenTools.defaultFontPixelHeight * 0.15

            QGCColoredImage {
                anchors.horizontalCenter: parent.horizontalCenter
                width:              ScreenTools.defaultFontPixelHeight * 1.5
                height:             width
                sourceSize.height:  height
                source:             tile.iconSource
                color:              tileMouse.pressed ? "#0B0D0C" : tile.iconColor
                fillMode:           Image.PreserveAspectFit
            }
            QGCLabel {
                anchors.horizontalCenter: parent.horizontalCenter
                text:               tile.text
                color:              tileMouse.pressed ? "#0B0D0C" : "#9AA59D"
                font.pointSize:     ScreenTools.smallFontPointSize
                font.bold:          true
                font.letterSpacing: 0.5
            }
        }

        QGCMouseArea {
            id:             tileMouse
            anchors.fill:   parent
            onClicked:      tile.clicked()
        }
    }

    component FlynusActionButton: Rectangle {
        id:             actionBtn
        width:          ScreenTools.defaultFontPixelHeight * 4.2
        height:         width
        radius:         width / 2
        color:          actionMouse.pressed ? "#2FBF4A" : Qt.rgba(0.055, 0.067, 0.059, 0.85)
        border.width:   primary ? 2 : 1
        border.color:   primary ? "#2FBF4A" : Qt.rgba(1, 1, 1, 0.12)
        opacity:        enabled ? 1 : 0.4

        property string text
        property string iconSource
        property color  iconColor: "#F2F5F3"
        property bool   primary:   false
        signal clicked()

        Column {
            anchors.centerIn:   parent
            spacing:            ScreenTools.defaultFontPixelHeight * 0.1

            QGCColoredImage {
                anchors.horizontalCenter: parent.horizontalCenter
                width:              ScreenTools.defaultFontPixelHeight * 1.6
                height:             width
                sourceSize.height:  height
                source:             actionBtn.iconSource
                color:              actionMouse.pressed ? "#0B0D0C" : actionBtn.iconColor
                fillMode:           Image.PreserveAspectFit
            }
            QGCLabel {
                anchors.horizontalCenter: parent.horizontalCenter
                text:               actionBtn.text
                color:              actionMouse.pressed ? "#0B0D0C" : "#F2F5F3"
                font.pointSize:     ScreenTools.smallFontPointSize
                font.bold:          true
                font.letterSpacing: 1
            }
        }

        QGCMouseArea {
            id:             actionMouse
            anchors.fill:   parent
            enabled:        actionBtn.enabled
            onClicked:      actionBtn.clicked()
        }
    }

    FlynusTileButton {
        id:             navPanelRight
        objectName:     "flynus_navClose"
        anchors.right:  parent.right
        anchors.bottom: parent.bottom
        z:              QGroundControl.zOrderWidgets
        visible:        !QGroundControl.videoManager.fullScreen
        text:           qsTr("CLOSE")
        iconSource:     "qrc:/flynus/icons/power.svg"
        iconColor:      "#FF6B6B"
        // Same as the stock menu: goes through the window close checks
        // (unsaved mission, pending parameters, active connection).
        onClicked:      if (mainWindow.allowViewSwitch()) mainWindow.close()
    }

    // ---- Flynus: large round action buttons (right edge) ---------------------
    // They open the same guided-action confirmation (slider) as the stock tool strip.
    Flickable {
        id:                     actionViewport
        anchors.right:          parent.right
        width:                  actionColumn.implicitWidth
        height:                 Math.min(contentHeight, Math.max(0, _bottomLimit - _topLimit))
        y:                      Math.max(_topLimit, Math.min((parent.height - height) / 2, _bottomLimit - height))
        contentWidth:           width
        contentHeight:          actionColumn.implicitHeight
        clip:                   height < contentHeight
        interactive:            clip
        boundsBehavior:         Flickable.StopAtBounds
        flickableDirection:     Flickable.VerticalFlick
        z:                      QGroundControl.zOrderWidgets
        visible:                !QGroundControl.videoManager.fullScreen && _activeVehicle

        // Keep the camera controls and the bottom Close button clear.
        readonly property real _cameraBottom: topRightPanel.visible
            ? topRightPanel.y + topRightPanel.height
            : topRightColumnLayout.visible && topRightColumnLayout.childrenRect.height > 0
                ? topRightColumnLayout.y + topRightColumnLayout.childrenRect.y + topRightColumnLayout.childrenRect.height
                : 0
        readonly property real _topLimit: _cameraBottom > 0 ? _cameraBottom + _layoutSpacing : 0
        readonly property real _bottomLimit: navPanelRight.visible ? navPanelRight.y - _layoutSpacing : parent.height
        readonly property real rightEdgeCenterInset: visible && height > 0 ? width + _layoutMargin : 0

        Column {
            id:                 actionColumn
            spacing:            ScreenTools.defaultFontPixelHeight * 0.8

            FlynusActionButton {
                text:       _guidedController.takeoffTitle.toUpperCase()
                iconSource: "qrc:/flynus/icons/takeoff.svg"
                primary:    true
                visible:    _guidedController.showTakeoff || !_guidedController.showLand
                enabled:    _guidedController.showTakeoff
                onClicked:  { _guidedController.closeAll(); _guidedController.confirmAction(_guidedController.actionTakeoff) }
            }
            FlynusActionButton {
                text:       qsTr("RTH")
                iconSource: "qrc:/flynus/icons/rth.svg"
                enabled:    _guidedController.showRTL
                onClicked:  { _guidedController.closeAll(); _guidedController.confirmAction(_guidedController.actionRTL) }
            }
            FlynusActionButton {
                text:       _guidedController.landTitle.toUpperCase()
                iconSource: "qrc:/flynus/icons/land.svg"
                visible:    _guidedController.showLand || !_guidedController.showTakeoff
                enabled:    _guidedController.showLand
                onClicked:  { _guidedController.closeAll(); _guidedController.confirmAction(_guidedController.actionLand) }
            }
            FlynusActionButton {
                text:       _guidedController.pauseTitle.toUpperCase()
                iconSource: "qrc:/flynus/icons/pause.svg"
                iconColor:  "#F5B700"
                enabled:    _guidedController.showPause
                onClicked:  { _guidedController.closeAll(); _guidedController.confirmAction(_guidedController.actionPause) }
            }
        }
    }

    FlyViewToolStrip {
        id:                     toolStrip
        anchors.left:           parent.left
        anchors.top:            statusPanel.bottom
        anchors.topMargin:      _toolsMargin
        z:                      QGroundControl.zOrderWidgets
        maxHeight:              parent.height - y - parentToolInsets.bottomEdgeLeftInset - _toolsMargin
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

    // ---- Flynus: "waiting for connection" screen ------------------------------
    // Shown until a vehicle is connected and its parameters are loaded. "Go to map" hides it
    // until the next disconnect. The top toolbar (logo menu) stays usable above it.
    property bool _connectScreenDismissed: false
    property bool _vehicleReady: _activeVehicle ? _activeVehicle.parameterManager.parametersReady : false

    // Restore QGC's PiP visibility binding when the waiting screen closes.
    Binding {
        target:         _pipView
        property:       "visible"
        value:          false
        when:           connectScreen.visible
        restoreMode:    Binding.RestoreBindingOrValue
    }

    Rectangle {
        id:                 connectScreen
        anchors.fill:       parent
        anchors.leftMargin:     -_toolsMargin
        anchors.rightMargin:    -_toolsMargin
        anchors.bottomMargin:   -_toolsMargin
        anchors.topMargin:      -(_toolsMargin + ScreenTools.toolbarHeight)
        z:                  QGroundControl.zOrderTopMost
        visible:            !_connectScreenDismissed && !_vehicleReady && !QGroundControl.videoManager.fullScreen
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#1d2a20" }
            GradientStop { position: 0.55; color: "#0d110e" }
            GradientStop { position: 1.0; color: "#070908" }
        }

        // Block clicks to the map underneath
        MouseArea {
            anchors.fill:   parent
            hoverEnabled:   true
            onWheel:        (wheel) => { wheel.accepted = true }
        }

        Column {
            anchors.centerIn:   parent
            spacing:            ScreenTools.defaultFontPixelHeight * 0.9

            Image {
                anchors.horizontalCenter: parent.horizontalCenter
                source:             "qrc:/flynus/FlynusWordmarkWhite.svg"
                width:              Math.min(connectScreen.width * 0.42, ScreenTools.defaultFontPixelHeight * 22)
                height:             width * 0.27
                sourceSize.width:   width
                fillMode:           Image.PreserveAspectFit
                smooth:             true
            }

            QGCLabel {
                anchors.horizontalCenter: parent.horizontalCenter
                text:               qsTr("GROUND CONTROL STATION")
                color:              "#9AA59D"
                font.bold:          true
                font.letterSpacing: 6
            }

            // Radar
            Item {
                id:                         radar
                anchors.horizontalCenter:   parent.horizontalCenter
                width:                      ScreenTools.defaultFontPixelHeight * 9
                height:                     width

                Repeater {
                    model: 3
                    Rectangle {
                        anchors.centerIn:   parent
                        width:              radar.width * (0.56 + index * 0.22)
                        height:             width
                        radius:             width / 2
                        color:              "transparent"
                        border.width:       2
                        border.color:       Qt.rgba(0.184, 0.749, 0.29, 0.7 - index * 0.22)
                    }
                }
                Rectangle {
                    id:                 pulse
                    anchors.centerIn:   parent
                    width:              radar.width * 0.38
                    height:             width
                    radius:             width / 2
                    color:              "transparent"
                    border.width:       2
                    border.color:       "#2FBF4A"
                    SequentialAnimation on scale {
                        running:    connectScreen.visible
                        loops:      Animation.Infinite
                        NumberAnimation { from: 1.0; to: 2.6; duration: 1800; easing.type: Easing.OutQuad }
                    }
                    SequentialAnimation on opacity {
                        running:    connectScreen.visible
                        loops:      Animation.Infinite
                        NumberAnimation { from: 0.9; to: 0.0; duration: 1800; easing.type: Easing.OutQuad }
                    }
                }
                Rectangle {
                    anchors.centerIn:   parent
                    width:              radar.width * 0.38
                    height:             width
                    radius:             width / 2
                    color:              Qt.rgba(0.184, 0.749, 0.29, 0.15)
                    border.width:       2
                    border.color:       "#2FBF4A"

                    QGCColoredImage {
                        anchors.centerIn:   parent
                        width:              parent.width * 0.5
                        height:             width
                        sourceSize.height:  height
                        source:             "qrc:/flynus/icons/rc.svg"
                        color:              "#2FBF4A"
                    }
                }
            }

            QGCLabel {
                anchors.horizontalCenter: parent.horizontalCenter
                text:               _activeVehicle ? qsTr("Loading parameters…") : qsTr("Searching for Flynus aircraft…")
                font.pointSize:     ScreenTools.largeFontPointSize * 1.15
                font.bold:          true
            }
            QGCLabel {
                anchors.horizontalCenter: parent.horizontalCenter
                text:               qsTr("Turn on the remote and the aircraft. The app connects automatically.")
                color:              "#9AA59D"
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing:                  ScreenTools.defaultFontPixelWidth * 3

                Repeater {
                    model: [
                        { label: qsTr("Aircraft"), done: !!_activeVehicle },
                        { label: qsTr("Parameters"), done: _vehicleReady }
                    ]
                    Row {
                        spacing: ScreenTools.defaultFontPixelWidth
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width:          ScreenTools.defaultFontPixelHeight * 1.1
                            height:         width
                            radius:         width / 2
                            color:          modelData.done ? "#2FBF4A" : "transparent"
                            border.width:   2
                            border.color:   modelData.done ? "#2FBF4A" : "#9AA59D"
                            QGCLabel {
                                anchors.centerIn:   parent
                                text:               "✓"
                                visible:            modelData.done
                                color:              "#0B0D0C"
                                font.bold:          true
                            }
                        }
                        QGCLabel {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.label
                        }
                    }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing:                  ScreenTools.defaultFontPixelWidth * 1.5
                topPadding:               ScreenTools.defaultFontPixelHeight

                QGCButton {
                    text:       qsTr("CONNECT MANUALLY")
                    primary:    true
                    visible:    !_activeVehicle
                    onClicked:  mainStatus.dropMainStatusIndicator()
                }
                QGCButton {
                    text:       qsTr("GO TO MAP")
                    onClicked:  _connectScreenDismissed = true
                }
                QGCButton {
                    text:       qsTr("SETTINGS")
                    onClicked:  if (mainWindow.allowViewSwitch()) mainWindow.showSettingsTool()
                }
            }
        }

        QGCLabel {
            anchors.horizontalCenter:   parent.horizontalCenter
            anchors.bottom:             parent.bottom
            anchors.bottomMargin:       ScreenTools.defaultFontPixelHeight
            text:                       QGroundControl.appName + " " + QGroundControl.qgcVersion + "  ·  " + qsTr("based on QGroundControl")
            color:                      "#5C665F"
            font.pointSize:             ScreenTools.smallFontPointSize
        }
    }
}
