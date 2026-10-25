import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlyView
import QGroundControl.FlightMap

// Flynus GCS custom Fly View overlay.
// (The left status/indicator panel lives in FlyViewWidgetLayer.qml.)
// A DJI-style battery / flight-time bar right below the top toolbar:
//  - the colored fill shrinks from right to left as the battery drains
//  - the chip at the end of the fill shows the remaining flight time (mm:ss)
// Remaining time comes from the flight controller (BATTERY_STATUS.time_remaining)
// when available; otherwise it is estimated from the discharge rate since arming
// (shown with a "~"). Without enough data the chip shows the battery percentage.
Item {
    id: _root

    property var parentToolInsets               // insets from the widget layer
    property var totalToolInsets:   _toolInsets // insets after our additions
    property var mapControl

    property var  _activeVehicle:   QGroundControl.multiVehicleManager.activeVehicle
    property var  _battery:         _activeVehicle && _activeVehicle.batteries.count > 0 ? _activeVehicle.batteries.get(0) : null
    property real _percent:         _battery ? _battery.percentRemaining.rawValue : NaN
    property real _fcTimeRemaining: _battery ? _battery.timeRemaining.rawValue : NaN   // seconds
    property bool _hasPercent:      !isNaN(_percent)

    // Estimate from discharge rate since arming
    property real _armPercent:      NaN
    property real _armTimeMs:       0
    property real _estTimeRemaining: NaN

    property real _remainingSec:    !isNaN(_fcTimeRemaining) && _fcTimeRemaining > 0 ? _fcTimeRemaining : _estTimeRemaining
    property bool _isEstimate:      isNaN(_fcTimeRemaining) || _fcTimeRemaining <= 0

    // The bar spans the whole Fly View width directly under the toolbar.
    // Our parent anchors us with the same margin on all sides, so x == that margin.
    property real _edgeMargin:      x
    property real _barHeight:       ScreenTools.defaultFontPixelHeight * 0.35

    readonly property color _colorGood: "#2FBF4A"
    readonly property color _colorLow:  "#F5B700"
    readonly property color _colorCrit: "#BC0814"

    function _fillColor() {
        if (_percent <= 15) return _colorCrit
        if (_percent <= 30) return _colorLow
        return _colorGood
    }

    function _formatTime(sec) {
        sec = Math.max(0, Math.round(sec))
        var m = Math.floor(sec / 60)
        var s = sec % 60
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s
    }

    function _resetEstimate() {
        _armPercent = NaN
        _armTimeMs = 0
        _estTimeRemaining = NaN
    }

    Connections {
        target: _activeVehicle
        ignoreUnknownSignals: true
        function onArmedChanged(armed) {
            if (armed && _hasPercent) {
                _armPercent = _percent
                _armTimeMs  = Date.now()
                _estTimeRemaining = NaN
            } else if (!armed) {
                _resetEstimate()
            }
        }
    }

    on_ActiveVehicleChanged: _resetEstimate()

    Timer {
        interval:   2000
        repeat:     true
        running:    _activeVehicle && _activeVehicle.armed && _hasPercent
        onTriggered: {
            if (isNaN(_armPercent)) {
                _armPercent = _percent
                _armTimeMs  = Date.now()
                return
            }
            var used = _armPercent - _percent
            var elapsedSec = (Date.now() - _armTimeMs) / 1000
            // Need at least 2% used and 30 s of data for a usable rate
            if (used >= 2 && elapsedSec >= 30) {
                _estTimeRemaining = _percent * elapsedSec / used
            }
        }
    }

    // ---- Bar ---------------------------------------------------------------
    Item {
        id:         batteryBar
        x:          -_edgeMargin
        y:          -_edgeMargin
        width:      (_root.parent ? _root.parent.width : _root.width + 2 * _edgeMargin)
        height:     chip.height
        visible:    _activeVehicle && _hasPercent
        z:          QGroundControl.zOrderWidgets

        // Track
        Rectangle {
            id:             track
            anchors.top:    parent.top
            anchors.left:   parent.left
            anchors.right:  parent.right
            height:         _barHeight
            color:          "#66000000"
        }

        // Fill: shrinks toward the left as the battery drains
        Rectangle {
            id:             fill
            anchors.top:    track.top
            anchors.left:   track.left
            height:         track.height
            width:          track.width * Math.max(0, Math.min(100, _percent)) / 100
            color:          _fillColor()
            Behavior on width { NumberAnimation { duration: 500 } }
        }

        // Chip with remaining time at the end of the fill
        Rectangle {
            id:         chip
            anchors.top: track.bottom
            anchors.topMargin: ScreenTools.defaultFontPixelHeight * 0.15
            // Keep clear of the left tool strip (Takeoff/Return buttons)
            x:          Math.max(parentToolInsets.leftEdgeTopInset + _edgeMargin, Math.min(fill.width - width / 2, batteryBar.width - width))
            width:      chipLabel.width + ScreenTools.defaultFontPixelWidth * 1.5
            height:     chipLabel.height + ScreenTools.defaultFontPixelHeight * 0.3
            radius:     height / 2
            color:      fill.color

            QGCLabel {
                id:                 chipLabel
                anchors.centerIn:   parent
                color:              "white"
                font.bold:          true
                font.pointSize:     ScreenTools.smallFontPointSize
                text: {
                    if (!isNaN(_remainingSec)) {
                        return (_isEstimate ? "~" : "") + _formatTime(_remainingSec)
                    }
                    return Math.round(_percent) + "%"
                }
            }
        }
    }

    // We use the top-center area; push other top widgets down a little.
    QGCToolInsets {
        id:                     _toolInsets
        leftEdgeTopInset:       parentToolInsets.leftEdgeTopInset
        leftEdgeCenterInset:    parentToolInsets.leftEdgeCenterInset
        leftEdgeBottomInset:    parentToolInsets.leftEdgeBottomInset
        rightEdgeTopInset:      parentToolInsets.rightEdgeTopInset
        rightEdgeCenterInset:   parentToolInsets.rightEdgeCenterInset
        rightEdgeBottomInset:   parentToolInsets.rightEdgeBottomInset
        topEdgeLeftInset:       parentToolInsets.topEdgeLeftInset
        topEdgeCenterInset:     Math.max(parentToolInsets.topEdgeCenterInset, batteryBar.visible ? batteryBar.height : 0)
        topEdgeRightInset:      parentToolInsets.topEdgeRightInset
        bottomEdgeLeftInset:    parentToolInsets.bottomEdgeLeftInset
        bottomEdgeCenterInset:  parentToolInsets.bottomEdgeCenterInset
        bottomEdgeRightInset:   parentToolInsets.bottomEdgeRightInset
    }
}
