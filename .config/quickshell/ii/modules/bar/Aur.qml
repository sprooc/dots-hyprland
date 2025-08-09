pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import Quickshell
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property real margin: 0
    property bool hovered: false
    implicitWidth: rowLayout.implicitWidth + margin * 2
    implicitHeight: rowLayout.implicitHeight

    hoverEnabled: true

    RowLayout {
        id: rowLayout
        anchors.centerIn: parent
        
        MaterialSymbol {
            text: AurUpdates.data?.updating ? "sync" : 
                  (AurUpdates.data?.updateCount > 0 ? "system_update" : "check_circle")
            iconSize: Appearance.font.pixelSize.large
            color: AurUpdates.data?.updateCount > 0 ? 
                   Appearance.colors.colAccent : 
                   Appearance.colors.colOnLayer1
            Layout.alignment: Qt.AlignVCenter
            
            rotation: AurUpdates.data?.updating ? rotation : 0
            
            RotationAnimation on rotation {
                running: AurUpdates.data?.updating
                from: 0
                to: 360
                duration: 1000
                loops: Animation.Infinite
            }
        }

        StyledText {
            visible: AurUpdates.data?.updateCount > 0 || AurUpdates.data?.updating
            font.pixelSize: Appearance.font.pixelSize.small
            color: AurUpdates.data?.updateCount > 0 ? 
                   Appearance.colors.colAccent : 
                   Appearance.colors.colOnLayer1
            text: AurUpdates.data?.updating ? "..." : 
                  (AurUpdates.data?.updateCount || 0).toString()
            Layout.alignment: Qt.AlignVCenter
        }
    }

    LazyLoader {
        id: popupLoader
        active: root.containsMouse

        component: PopupWindow {
            id: popupWindow
            visible: true
            implicitWidth: 250
            implicitHeight: Math.max(150, aurPopup.implicitHeight)
            anchor.item: root
            anchor.edges: Edges.Top
            anchor.rect.x: (root.implicitWidth - popupWindow.implicitWidth) / 2
            anchor.rect.y: Config.options.bar.bottom ? 
                (-popupWindow.implicitHeight - 15) :
                (root.implicitHeight + 15 )
            color: "transparent"
            
            Rectangle {
                id: aurPopup
                anchors.fill: parent
                color: Appearance.colors.colLayer2
                radius: Appearance.rounding.normal
                border.width: 1
                border.color: Appearance.colors.colOutlineVariant

                Column {
                    id: contentColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 16
                    spacing: 12

                    StyledText {
                        text: "AUR Updates"
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Bold
                        color: Appearance.colors.colOnLayer2
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Appearance.colors.colOutlineVariant
                    }

                    StyledText {
                        text: AurUpdates.data?.updating ? "Checking for updates..." :
                              AurUpdates.data?.updateCount > 0 ? 
                              `${AurUpdates.data.updateCount} package${AurUpdates.data.updateCount === 1 ? '' : 's'} available for update` :
                              "All packages are up to date"
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer2
                        wrapMode: Text.WordWrap
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                    }

                    StyledText {
                        text: `Last checked: ${AurUpdates.formatLastCheck()}`
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOnLayer2
                        opacity: 0.7
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8
                        
                        RippleButton {
                            text: "Refresh"
                            implicitWidth: 80
                            implicitHeight: 32
                            onClicked: AurUpdates.checkUpdates()
                            enabled: !AurUpdates.data?.updating
                        }
                        
                        RippleButton {
                            text: "Update All"
                            implicitWidth: 80
                            implicitHeight: 32
                            visible: AurUpdates.data?.updateCount > 0
                            onClicked: {
                                // Open terminal and run yay -Syu
                                Quickshell.execDetached(["kitty", "-e", "yay", "-Syu"])
                            }
                        }
                    }
                }
            }
        }
    }

    onClicked: {
        if (AurUpdates.data?.updateCount > 0) {
            // Double-click to update
            Quickshell.execDetached(["kitty", "-e", "yay", "-Syu"])
        } else {
            // Single click to refresh
            AurUpdates.checkUpdates()
        }
    }
}
