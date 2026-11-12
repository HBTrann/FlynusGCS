import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls

// Flynus GCS override of the stock SettingsButton.qml (left menus of Configure and
// Application Settings): taller rows, dark card on selection with a green accent bar.
Button {
    id:             control
    padding:        ScreenTools.defaultFontPixelWidth * 0.75
    leftPadding:    ScreenTools.defaultFontPixelWidth * 1.6
    topPadding:     ScreenTools.defaultFontPixelHeight * 0.45
    bottomPadding:  ScreenTools.defaultFontPixelHeight * 0.45
    hoverEnabled:   !ScreenTools.isMobile
    autoExclusive:  true
    icon.color:     textColor

    property color textColor: checked || pressed ? "#2FBF4A" : qgcPal.buttonText
    property bool expandable: false
    property bool expanded:   false

    // Application Settings sets this object name from the untranslated page key.
    readonly property string settingsIconPrefix: "qrc:/flynus/icons/settings/"
    readonly property bool isApplicationSettingsPage: objectName.startsWith("settingsButton_")
    readonly property var settingsIcons: ({
        "general": "general",
        "flyview": "fly",
        "3dview": "3d",
        "planview": "plan",
        "adsbserver": "adsb",
        "commlinks": "links",
        "applogging": "logging",
        "applogviewer": "log-viewer",
        "maps": "maps",
        "ntriprtk": "rtk",
        "ntrip": "rtk",
        "px4logtransfer": "transfer",
        "remoteid": "remote-id",
        "telemetry": "telemetry",
        "video": "video",
        "help": "help"
    })
    readonly property url menuIconSource: {
        if (!isApplicationSettingsPage) {
            return icon.source
        }

        const pageKey = objectName.slice("settingsButton_".length).toLowerCase().replace(/[^a-z0-9]/g, "")
        return settingsIconPrefix + (settingsIcons[pageKey] ?? "general") + ".svg"
    }

    signal toggleExpand()

    QGCPalette {
        id:                 qgcPal
        colorGroupEnabled:  control.enabled
    }

    background: Rectangle {
        color:      checked || pressed ? Qt.rgba(0.184, 0.749, 0.29, 0.14) : (enabled && hovered ? Qt.rgba(1, 1, 1, 0.06) : "transparent")
        radius:     ScreenTools.defaultFontPixelWidth
        border.width: checked ? 1 : 0
        border.color: Qt.rgba(0.184, 0.749, 0.29, 0.45)

        // Accent bar on the selected item
        Rectangle {
            anchors.left:           parent.left
            anchors.verticalCenter: parent.verticalCenter
            width:                  ScreenTools.defaultFontPixelWidth * 0.45
            height:                 parent.height * 0.6
            radius:                 width / 2
            color:                  "#2FBF4A"
            visible:                control.checked
        }
    }

    contentItem: RowLayout {
        spacing: ScreenTools.defaultFontPixelWidth

        QGCColoredImage {
            source: control.menuIconSource
            color:  control.icon.color
            width:  ScreenTools.defaultFontPixelHeight * 1.2
            height: ScreenTools.defaultFontPixelHeight * 1.2
        }

        QGCLabel {
            id:                     displayText
            Layout.fillWidth:       true
            text:                   control.text
            color:                  control.textColor
            font.bold:              control.checked
            horizontalAlignment:    QGCLabel.AlignLeft
        }

        QGCColoredImage {
            visible:    control.expandable
            source:     control.isApplicationSettingsPage ? control.settingsIconPrefix + "chevron.svg" : "/InstrumentValueIcons/cheveron-right.svg"
            color:      control.textColor
            width:      ScreenTools.defaultFontPixelHeight * 0.75
            height:     width
            rotation:   control.expanded ? 90 : 0

            MouseArea {
                anchors.fill: parent
                anchors.margins: -ScreenTools.defaultFontPixelWidth
                onClicked: control.toggleExpand()
            }
        }
    }
}
