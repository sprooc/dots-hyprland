import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Quickshell
import qs.modules.common
import qs
import qs.modules.common.widgets

Item {
    id: root
    visible: true

    property int selectedTab: 2
    property var tabs: [
        {"name": "World", "icon": "public", "color": "#4285F4"},
        {"name": "Alarms", "icon": "alarm", "color": "#EA4335"},
        {"name": "Stopwatch", "icon": "timer", "color": "#FBBC05"},
        {"name": "Timer", "icon": "hourglass_empty", "color": "#34A853"}
    ]

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        StackLayout {
            id: contentStack
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.selectedTab

            WorldWidget {}
            AlarmsWidget {}
            StopwatchWidget {}
            TimerWidget {}
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            color: "transparent"
            z: 2

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 0

                Repeater {
                    model: root.tabs
                    delegate: Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Column {
                            anchors.centerIn: parent
                            spacing: 4

                            NavigationRailButton {
                                showToggledHighlight: false
                                toggled: root.selectedTab == index
                                buttonText: modelData.name
                                buttonIcon: modelData.icon
                                onClicked: {
                                    root.selectedTab = index
                                    Persistent.states.sidebar.bottomGroup.tab = index
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.selectedTab = index
                        }
                    }
                }
            }
        }
    }
}