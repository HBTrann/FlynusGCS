import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls

// Flynus GCS override of the stock ParameterEditor.qml (Configure > Parameters):
// card-style search bar, pill tabs, group list with accent bar, borderless table,
// star favourites and green "modified" chips. Behaviour is unchanged.
Item {
    id:         _root

    property Fact   _editorDialogFact: Fact { }
    property int    _rowHeight:         ScreenTools.defaultFontPixelHeight * 2
    property int    _rowWidth:          10 // Dynamic adjusted at runtime
    property bool   _searchFilter:      searchText.text.trim() != "" || controller.showModifiedOnly || controller.showFavoritesOnly  ///< true: showing results of search
    property var    _searchResults      ///< List of parameter names from search results
    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle
    property bool   _showRCToParam:     _activeVehicle.px4Firmware
    property var    _appSettings:       QGroundControl.settingsManager.appSettings
    property var    _controller:        controller
    property var    _favorites:         controller.favoriteParameterNames
    property real   _margins:           ScreenTools.defaultFontPixelHeight / 2

    ParameterEditorController {
        id: controller
    }

    Timer {
        id:         clearTimer
        interval:   100;
        running:    false;
        repeat:     false
        onTriggered: {
            searchText.text = ""
            controller.searchText = ""
        }
    }

    QGCMenu {
        id:                 toolsMenu
        QGCMenuItem {
            text:           qsTr("Refresh")
            onTriggered:	controller.refresh()
        }
        QGCMenuItem {
            text:           qsTr("Reset all to firmware's defaults")
            onTriggered:    QGroundControl.showMessageDialog(_root, qsTr("Reset All"),
                                                         qsTr("Select Reset to reset all parameters to their defaults.\n\nNote that this will also completely reset everything, including UAVCAN nodes, all vehicle settings, setup and calibrations."),
                                                         Dialog.Cancel | Dialog.Reset,
                                                         function() { controller.resetAllToDefaults() })
        }
        QGCMenuItem {
            text:           qsTr("Reset to vehicle's configuration defaults")
            visible:        !_activeVehicle.apmFirmware
            onTriggered:    QGroundControl.showMessageDialog(_root, qsTr("Reset All"),
                                                         qsTr("Select Reset to reset all parameters to the vehicle's configuration defaults."),
                                                         Dialog.Cancel | Dialog.Reset,
                                                         function() { controller.resetAllToVehicleConfiguration() })
        }
        QGCMenuSeparator { }
        QGCMenuItem {
            objectName:     "parameterEditor_toolLoadFromFile"
            text:           qsTr("Load from file for review...")
            onTriggered: {
                fileDialog.title =          qsTr("Load Parameters")
                fileDialog.openForLoad()
            }
        }
        QGCMenuItem {
            text:           qsTr("Save to file...")
            onTriggered: {
                fileDialog.title =          qsTr("Save Parameters")
                fileDialog.openForSave()
            }
        }
        QGCMenuSeparator { }
        QGCMenuItem {
            text:           qsTr("Clear all favorites")
            onTriggered:    controller.clearAllFavorites()
        }
        QGCMenuSeparator { visible: _showRCToParam }
        QGCMenuItem {
            text:           qsTr("Clear all RC to Param")
            onTriggered:	_activeVehicle.clearAllParamMapRC()
            visible:        _showRCToParam
        }
        QGCMenuSeparator { }
        QGCMenuItem {
            text:           qsTr("Reboot Vehicle")
            onTriggered:    QGroundControl.showMessageDialog(_root, qsTr("Reboot Vehicle"),
                                                         qsTr("Select Ok to reboot vehicle."),
                                                         Dialog.Cancel | Dialog.Ok,
                                                         function() { _activeVehicle.rebootVehicle() })
        }
    }


    QGCFileDialog {
        id:             fileDialog
        folder:         _appSettings.parameterSavePath
        nameFilters:    [ qsTr("Parameter Files (*.%1)").arg(_appSettings.parameterFileExtension), qsTr("Mission Planner Files (*.param)"), qsTr("All Files (*)") ]

        onAcceptedForSave: (file) => {
            controller.saveToFile(file)
            close()
        }

        onAcceptedForLoad: (file) => {
            close()
            if (controller.buildDiffFromFile(file)) {
                parameterDiffDialogFactory.open()
            }
        }
    }

    QGCPopupDialogFactory {
        id: editorDialogFactory

        dialogComponent: editorDialogComponent
    }

    Component {
        id: editorDialogComponent

        ParameterEditorDialog {
            fact:           _editorDialogFact
            showRCToParam:  _showRCToParam
        }
    }

    QGCPopupDialogFactory {
        id: parameterDiffDialogFactory

        dialogComponent: parameterDiffDialog
    }

    Component {
        id: parameterDiffDialog

        ParameterDiffDialog {
            paramController: _controller
        }
    }

    RowLayout {
        id:             header
        anchors.left:   parent.left
        anchors.right:  parent.right

        RowLayout {
            Layout.alignment:   Qt.AlignLeft
            spacing:            ScreenTools.defaultFontPixelWidth

            Rectangle {
                implicitWidth:  searchRow.implicitWidth + ScreenTools.defaultFontPixelWidth * 1.5
                implicitHeight: searchRow.implicitHeight + ScreenTools.defaultFontPixelHeight * 0.3
                radius:         height / 2
                color:          qgcPal.windowShade
                border.width:   1
                border.color:   searchText.activeFocus ? "#2FBF4A" : qgcPal.groupBorder

                RowLayout {
                    id:                 searchRow
                    anchors.centerIn:   parent
                    spacing:            ScreenTools.defaultFontPixelWidth / 2

                    QGCColoredImage {
                        source:             "qrc:/flynus/icons/search.svg"
                        color:              "#9AA59D"
                        width:              ScreenTools.defaultFontPixelHeight
                        height:             width
                        sourceSize.height:  height
                    }

                    QGCTextField {
                        id:                     searchText
                        Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 28
                        placeholderText:        qsTr("Search parameters")
                        onDisplayTextChanged:   controller.searchText = displayText
                    }
                }
            }

            QGCButton {
                text: qsTr("Clear")
                onClicked: {
                    if(ScreenTools.isMobile) {
                        Qt.inputMethod.hide();
                    }
                    clearTimer.start()
                }
            }

            QGCCheckBox {
                text:       qsTr("Hide read-only")
                checked:    controller.hideReadOnly
                onClicked:  controller.hideReadOnly = checked
            }
        }

        QGCButton {
            Layout.alignment:   Qt.AlignRight
            objectName:         "parameterEditor_toolsButton"
            text:               qsTr("Tools")
            onClicked:          toolsMenu.popup()
        }
    }

    // Pill tabs: Full List / Modified / Favorites
    Row {
        id:                 tabBar
        anchors.left:       parent.left
        anchors.top:        header.bottom
        anchors.topMargin:  _margins
        spacing:            ScreenTools.defaultFontPixelWidth

        property int currentIndex: 0

        onCurrentIndexChanged: {
            controller.showModifiedOnly  = (currentIndex === 1)
            controller.showFavoritesOnly = (currentIndex === 2)
        }

        Repeater {
            model: [ qsTr("Full List"), qsTr("Modified"), qsTr("Favorites") ]

            Rectangle {
                width:          pillLabel.contentWidth + ScreenTools.defaultFontPixelWidth * 3
                height:         pillLabel.contentHeight + ScreenTools.defaultFontPixelHeight * 0.6
                radius:         height / 2
                color:          tabBar.currentIndex === index ? "#2FBF4A" : qgcPal.windowShade
                border.width:   1
                border.color:   tabBar.currentIndex === index ? "#2FBF4A" : qgcPal.groupBorder

                QGCLabel {
                    id:                 pillLabel
                    anchors.centerIn:   parent
                    text:               modelData
                    font.bold:          true
                    color:              tabBar.currentIndex === index ? "#0B0D0C" : qgcPal.text
                }

                QGCMouseArea {
                    anchors.fill:   parent
                    onClicked:      tabBar.currentIndex = index
                }
            }
        }
    }

    /// Group buttons
    QGCFlickable {
        id :                groupScroll
        width:              ScreenTools.defaultFontPixelWidth * 25
        anchors.top:        tabBar.bottom
        anchors.topMargin:  _margins
        anchors.bottom:     parent.bottom
        clip:               true
        pixelAligned:       true
        contentHeight:      groupedViewCategoryColumn.height
        flickableDirection: Flickable.VerticalFlick
        visible:            !_searchFilter

        ColumnLayout {
            id:             groupedViewCategoryColumn
            anchors.left:   parent.left
            anchors.right:  parent.right
            spacing:        Math.ceil(ScreenTools.defaultFontPixelHeight * 0.25)

            Repeater {
                model: controller.categories

                Column {
                    Layout.fillWidth:   true
                    spacing:            Math.ceil(ScreenTools.defaultFontPixelHeight * 0.25)


                    // Category header
                    Rectangle {
                        id:             categoryHeader
                        anchors.left:   parent.left
                        anchors.right:  parent.right
                        height:         categoryLabel.contentHeight + ScreenTools.defaultFontPixelHeight * 0.8
                        radius:         ScreenTools.defaultFontPixelWidth
                        color:          checked ? qgcPal.windowShade : "transparent"

                        property bool checked: object == controller.currentCategory

                        QGCLabel {
                            id:                     categoryLabel
                            anchors.left:           parent.left
                            anchors.leftMargin:     ScreenTools.defaultFontPixelWidth
                            anchors.verticalCenter: parent.verticalCenter
                            text:                   object.name.toUpperCase()
                            font.bold:              true
                            font.letterSpacing:     1
                            color:                  categoryHeader.checked ? "#2FBF4A" : "#9AA59D"
                        }

                        QGCMouseArea {
                            anchors.fill:   parent
                            onClicked:      controller.currentCategory = object
                        }
                    }

                    Repeater {
                        model: categoryHeader.checked ? object.groups : 0

                        Rectangle {
                            id:             groupItem
                            width:          ScreenTools.defaultFontPixelWidth * 25
                            height:         _rowHeight
                            radius:         ScreenTools.defaultFontPixelWidth
                            color:          selected ? Qt.rgba(0.184, 0.749, 0.29, 0.14) : (groupMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent")

                            property bool selected: object == controller.currentGroup

                            Rectangle {
                                anchors.left:           parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width:                  ScreenTools.defaultFontPixelWidth * 0.45
                                height:                 parent.height * 0.6
                                radius:                 width / 2
                                color:                  "#2FBF4A"
                                visible:                groupItem.selected
                            }

                            QGCLabel {
                                anchors.left:           parent.left
                                anchors.leftMargin:     ScreenTools.defaultFontPixelWidth * 1.6
                                anchors.verticalCenter: parent.verticalCenter
                                text:                   object.name
                                font.bold:              groupItem.selected
                                color:                  groupItem.selected ? "#2FBF4A" : qgcPal.text
                            }

                            QGCMouseArea {
                                id:             groupMouse
                                anchors.fill:   parent
                                hoverEnabled:   !ScreenTools.isMobile
                                onClicked: {
                                    if (!groupItem.selected) _rowWidth = 10
                                    controller.currentGroup = object
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    HorizontalHeaderView {
        id:                 headerView
        anchors.left:       tableView.left
        anchors.right:      tableView.right
        anchors.top:        tabBar.bottom
        anchors.topMargin:  _margins
        syncView:           tableView
        clip:               true

        delegate: Rectangle {
            implicitWidth:  column === 0 ? ScreenTools.implicitCheckBoxHeight + ScreenTools.defaultFontPixelWidth
                                         : headerLabel.contentWidth + ScreenTools.defaultFontPixelWidth
            implicitHeight: headerLabel.contentHeight + ScreenTools.defaultFontPixelHeight * 0.7
            color:          "transparent"

            QGCLabel {
                id:                     headerLabel
                anchors.left:           parent.left
                anchors.leftMargin:     ScreenTools.defaultFontPixelWidth / 2
                anchors.verticalCenter: parent.verticalCenter
                text:                   String(display).toUpperCase()
                font.bold:              true
                font.letterSpacing:     1
                font.pointSize:         ScreenTools.smallFontPointSize
                color:                  "#9AA59D"
            }

            // Bottom border
            Rectangle {
                anchors.bottom: parent.bottom
                width:          parent.width
                height:         1
                color:          qgcPal.groupBorder
            }
        }
    }

    TableView {
        id:                 tableView
        anchors.leftMargin: ScreenTools.defaultFontPixelWidth
        anchors.top:        headerView.bottom
        anchors.bottom:     parent.bottom
        anchors.left:       _searchFilter ? parent.left : groupScroll.right
        anchors.right:      parent.right
        columnSpacing:      0
        rowSpacing:         0
        model:              controller.parameters
        contentWidth:       width
        clip:               true

        // Qt is supposed to adjust column widths automatically when larger widths come into view.
        // But it doesn't work. So we have to do it force a layout manually when we scroll.
        Timer {
            id:             forceLayoutTimer
            interval:       500
            repeat:         false
            onTriggered:    tableView.forceLayout()
        }

        onTopRowChanged: forceLayoutTimer.start()
        onModelChanged: {
            positionViewAtRow(0, TableView.AlignLeft | TableView.AlignTop)
            forceLayoutTimer.start()
        }

        delegate: Rectangle {
            implicitWidth:  column === 0 ? ScreenTools.implicitCheckBoxHeight + ScreenTools.defaultFontPixelWidth
                                         : column === 1 ? nameRow.implicitWidth + ScreenTools.defaultFontPixelWidth
                                         : column === 2 ? ScreenTools.defaultFontPixelWidth * 16
                                                        : label.contentWidth + ScreenTools.defaultFontPixelWidth
            implicitHeight: label.contentHeight + ScreenTools.defaultFontPixelHeight * 0.8
            color:          row % 2 === 0 ? "transparent" : Qt.rgba(1, 1, 1, 0.025)
            clip:           true

            // Row separator
            Rectangle {
                anchors.bottom: parent.bottom
                width:          parent.width
                height:         1
                color:          Qt.rgba(1, 1, 1, 0.06)
            }

            // Favourite star
            QGCColoredImage {
                id:                 favStar
                visible:            column === 0
                anchors.centerIn:   parent
                z:                  1
                width:              ScreenTools.defaultFontPixelHeight * 1.1
                height:             width
                sourceSize.height:  height
                property bool isFavorite: _root._favorites.indexOf(fact.name) >= 0
                source:             isFavorite ? "qrc:/flynus/icons/star-filled.svg" : "qrc:/flynus/icons/star.svg"
                color:              isFavorite ? "#F5B700" : "#6F7A72"

                QGCMouseArea {
                    anchors.fill:       parent
                    anchors.margins:    -ScreenTools.defaultFontPixelWidth / 2
                    onClicked:          controller.toggleFavorite(fact.name)
                }
            }

            Row {
                id:                     nameRow
                visible:                column === 1
                anchors.left:           parent.left
                anchors.leftMargin:     ScreenTools.defaultFontPixelWidth / 2
                anchors.verticalCenter: parent.verticalCenter
                spacing:               lockIcon.visible ? ScreenTools.defaultFontPixelWidth / 3 : 0

                QGCLabel {
                    text:               column === 1 ? display : ""
                    anchors.verticalCenter: parent.verticalCenter
                }

                QGCColoredImage {
                    id:                 lockIcon
                    visible:            fact.readOnly
                    source:             "qrc:/InstrumentValueIcons/lock-closed.svg"
                    color:              qgcPal.text
                    width:              ScreenTools.defaultFontPixelHeight * 0.8
                    height:             width
                    sourceSize.width:   width
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // "Modified" chip behind the value when it differs from the default
            Rectangle {
                visible:                column == 2 && fact.defaultValueAvailable && !fact.valueEqualsDefault
                anchors.left:           parent.left
                anchors.leftMargin:     ScreenTools.defaultFontPixelWidth / 4
                anchors.verticalCenter: parent.verticalCenter
                width:                  Math.min(label.contentWidth, label.width) + ScreenTools.defaultFontPixelWidth / 2
                height:                 label.contentHeight + ScreenTools.defaultFontPixelHeight * 0.2
                radius:                 height / 2
                color:                  Qt.rgba(0.184, 0.749, 0.29, 0.18)
                border.width:           1
                border.color:           Qt.rgba(0.184, 0.749, 0.29, 0.6)
            }

            QGCLabel {
                id:                 label
                visible:            column !== 0 && column !== 1
                anchors.left:       parent.left
                anchors.leftMargin: ScreenTools.defaultFontPixelWidth / 2
                anchors.verticalCenter: parent.verticalCenter
                width:              column == 2 ? ScreenTools.defaultFontPixelWidth * 15 : implicitWidth
                text:               column == 2 ? col1String() : display
                color:              column == 2 && fact.defaultValueAvailable && !fact.valueEqualsDefault ? "#2FBF4A" : (column == 3 ? "#9AA59D" : qgcPal.text)
                font.bold:          column == 2 && fact.defaultValueAvailable && !fact.valueEqualsDefault
                maximumLineCount:   1
                elide:              column == 2 ? Text.ElideRight : Text.ElideNone

                function col1String() {
                    if (fact.enumStrings.length === 0) {
                        return fact.valueString + " " + fact.units
                    }
                    if (fact.bitmaskStrings.length != 0) {
                        return fact.selectedBitmaskStrings.join(',')
                    }
                    return fact.enumStringValue
                }
            }

            QGCMouseArea {
                anchors.fill: parent
                visible:      column !== 0
                onClicked: mouse => {
                    _editorDialogFact = fact
                    editorDialogFactory.open()
                }
            }
        }
    }
}
