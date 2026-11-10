import QtQml.Models

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlyView
import QGroundControl.Viewer3D

// Flynus GCS override of the stock FlyViewToolStripActionList.qml:
// Takeoff / Land / RTL / Pause are large round buttons on the right edge of the Fly View
// (see FlyViewWidgetLayer.qml), so they are removed from the left tool strip.
ToolStripActionList {
    id: _root

    signal displayPreFlightChecklist

    model: [
        Viewer3DShowAction { },
        PreFlightCheckListShowAction { onTriggered: displayPreFlightChecklist() },
        FlyViewAdditionalActionsButton { },
        FlyViewGripperButton { }
    ]
}
