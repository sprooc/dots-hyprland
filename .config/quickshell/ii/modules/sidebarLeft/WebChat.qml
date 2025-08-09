import QtQuick
import QtWebEngine
import qs.modules.common
import qs.modules.common.widgets
import qs
import QtQuick.Layouts

Item {
    id: root
    property var tabs: [
        {"name": "ChatGPT", "icon": "chat", "url": "https://chat.openai.com"},
        {"name": "DeepSeek", "icon": "lightbulb", "url": "https://chat.deepseek.com"}
    ]
    property int selectedTab: 0

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        StackLayout {
            id: viewStack
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.selectedTab

            Repeater {
                model: root.tabs
                WebEngineView {
                    url: modelData.url
                    settings.javascriptCanAccessClipboard: true

                    profile: WebEngineProfile {
                        id: persistentProfile
                        persistentCookiesPolicy: WebEngineProfile.ForcePersistentCookies
                        storageName: "chatProfile"
                        persistentStoragePath: StandardPaths.writableLocation(StandardPaths.AppDataLocation) + "/chat"
                        offTheRecord: false
                    }

                }
            }
        }


        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 68
            color: "transparent"

            Row {
                anchors.fill: parent
                anchors.leftMargin: 0
                anchors.rightMargin: 0
                spacing: 0

                Repeater {
                    model: root.tabs
                    Item {
                        width: parent.width / root.tabs.length
                        height: parent.height

                        NavigationRailButton {
                            anchors.centerIn: parent
                            height: parent.height
                            showToggledHighlight: false
                            toggled: root.selectedTab === index
                            buttonText: modelData.name
                            buttonIcon: modelData.icon
                            onClicked: {
                                root.selectedTab = index
                                Persistent.states.sidebar.bottomGroup.tab = index
                            }
                        }
                    }
                }
            }
        }
    }
}