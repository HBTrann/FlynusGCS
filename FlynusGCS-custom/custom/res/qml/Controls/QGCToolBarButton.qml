import QtQuick
import QtQuick.Controls

import QGroundControl
import QGroundControl.Controls

// Important Note: Toolbar buttons must manage their checked state manually in order to support
// view switch prevention. This means they can't be checkable or autoExclusive.

// Flynus GCS override: logo buttons show the full "FLYNUS" wordmark (wide tile)
// instead of a square icon. Applies to the Fly, Plan and settings/tool toolbars.
Button {
    id:                 button
    height:             ScreenTools.defaultFontPixelHeight * 3
    leftPadding:        _horizontalMargin
    rightPadding:       _horizontalMargin
    checkable:          false

    property bool logo: false

    property real _horizontalMargin: ScreenTools.defaultFontPixelWidth

    onCheckedChanged: checkable = false

    component PageTab: Button {
        id: tab

        required property string page
        required property string glyph
        required property bool compact
        readonly property bool selected: button.activePage === page

        width: compact ? ScreenTools.defaultFontPixelHeight * 2.1 : implicitWidth
        height: ScreenTools.defaultFontPixelHeight * 2.15
        horizontalPadding: ScreenTools.defaultFontPixelWidth * 0.9
        verticalPadding: 0
        hoverEnabled: !ScreenTools.isMobile
        Accessible.name: text
        Accessible.selected: selected
        ToolTip.visible: compact && hovered
        ToolTip.text: text

        background: Rectangle {
            radius: ScreenTools.defaultFontPixelWidth * 0.65
            color: tab.selected ? Qt.rgba(0.18, 0.75, 0.29, 0.22) : qgcPal.windowShade
            border.width: tab.selected || tab.activeFocus ? 1 : 0
            border.color: qgcPal.colorGreen
            opacity: tab.selected || tab.hovered || tab.down ? 1 : 0.88
        }

        contentItem: Item {
            implicitWidth: tabContent.implicitWidth
            implicitHeight: tabContent.implicitHeight

            Row {
                id: tabContent
                anchors.centerIn: parent
                spacing: ScreenTools.defaultFontPixelWidth * 0.55

                QGCColoredImage {
                    anchors.verticalCenter: parent.verticalCenter
                    width: ScreenTools.defaultFontPixelHeight * 1.2
                    height: width
                    source: tab.glyph
                    color: tab.selected ? qgcPal.colorGreen : qgcPal.buttonText
                }

                QGCLabel {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !tab.compact
                    text: tab.text
                    font.bold: tab.selected
                    color: tab.selected ? qgcPal.colorGreen : qgcPal.buttonText
                }
            }
        }
    }

    readonly property string activePage: logo ? _currentPage() : ""

    function _currentPage() {
        // The shared logo button sits inside the active Fly, Plan, or tool view.
        for (let item = parent; item; item = item.parent) {
            if (item.objectName === "mainView_plan") {
                return "plan"
            }
            if (item.objectName === "mainView_toolDrawer") {
                const source = String(item.toolSource)
                if (source.endsWith("/AnalyzeView.qml")) {
                    return "analyze"
                }
                if (source.endsWith("/VehicleConfigView.qml")) {
                    return "configure"
                }
                if (source.endsWith("/AppSettings.qml")) {
                    return "settings"
                }
                return ""
            }
        }
        return "fly"
    }

    background: Rectangle {
        anchors.fill:   parent
        color:          button.checked ? qgcPal.buttonHighlight : Qt.rgba(0,0,0,0)
        border.color:   "red"
        border.width:   QGroundControl.corePlugin.showTouchAreas ? 3 : 0
    }

    contentItem: Row {
        spacing:                ScreenTools.defaultFontPixelWidth
        anchors.verticalCenter: button.verticalCenter
        Button {
            id:                     flyLogo
            visible:                button.logo
            height:                 ScreenTools.defaultFontPixelHeight * 2.3
            width:                  ScreenTools.defaultFontPixelHeight * 2 * 2.97 + 4
            anchors.verticalCenter: parent.verticalCenter
            Accessible.name:        qsTr("Fly")
            Accessible.selected:    button.activePage === "fly"
            ToolTip.visible:        hovered
            ToolTip.text:           qsTr("Fly")

            onClicked: {
                if (button.activePage !== "fly" && mainWindow.allowViewSwitch()) {
                    mainWindow.showFlyView()
                }
            }
            onPressAndHold: mainWindow.showToolSelectDialog()

            background: Rectangle {
                radius: ScreenTools.defaultFontPixelWidth * 0.65
                color: "transparent"
                border.width: button.activePage === "fly" || flyLogo.activeFocus ? 1 : 0
                border.color: qgcPal.colorGreen
            }

            contentItem: Item {
                QGCVectorImage {
                    anchors.centerIn: parent
                    height: ScreenTools.defaultFontPixelHeight * 2
                    width: height * 2.97
                    source: flyLogo.visible ? "qrc:/flynus/FlynusWordmarkTile.svg" : ""
                }
            }
        }
        QGCColoredImage {
            visible:                !button.logo
            height:                 ScreenTools.defaultFontPixelHeight * 2
            width:                  height
            sourceSize.height:      parent.height
            fillMode:               Image.PreserveAspectFit
            color:                  button.checked ? qgcPal.buttonHighlightText : qgcPal.buttonText
            source:                 visible ? button.icon.source : ""
            anchors.verticalCenter: parent.verticalCenter
        }
        Label {
            id:                     _label
            visible:                text !== ""
            text:                   button.text
            color:                  button.checked ? qgcPal.buttonHighlightText : qgcPal.buttonText
            anchors.verticalCenter: parent.verticalCenter
        }
        Loader {
            active: button.logo
            visible: active
            anchors.verticalCenter: parent.verticalCenter
            sourceComponent: Row {
                id: tabs
                spacing: ScreenTools.defaultFontPixelWidth * 0.45
                readonly property bool compact: mainWindow.width < ScreenTools.defaultFontPixelWidth * 115

                PageTab {
                    page: "plan"
                    text: qsTr("Plan")
                    glyph: "qrc:/flynus/icons/plan.svg"
                    compact: tabs.compact
                    onClicked: if (!selected && mainWindow.allowViewSwitch()) mainWindow.showPlanView()
                }
                PageTab {
                    page: "analyze"
                    text: qsTr("Analyze")
                    glyph: "qrc:/flynus/icons/analyze.svg"
                    compact: tabs.compact
                    visible: QGroundControl.corePlugin.showAdvancedUI
                    onClicked: if (!selected && mainWindow.allowViewSwitch()) mainWindow.showAnalyzeTool()
                }
                PageTab {
                    page: "configure"
                    text: qsTr("Configure")
                    glyph: "qrc:/flynus/icons/setup.svg"
                    compact: tabs.compact
                    onClicked: if (!selected && mainWindow.allowViewSwitch()) mainWindow.showVehicleConfig()
                }
                PageTab {
                    page: "settings"
                    text: qsTr("Settings")
                    glyph: "qrc:/flynus/icons/settings.svg"
                    compact: tabs.compact
                    visible: !QGroundControl.corePlugin.options.combineSettingsAndSetup
                    onClicked: if (!selected && mainWindow.allowViewSwitch()) mainWindow.showSettingsTool()
                }
            }
        }
    }
}
