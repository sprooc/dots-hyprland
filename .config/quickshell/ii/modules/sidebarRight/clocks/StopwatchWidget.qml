import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.modules.common
import qs.modules.common.widgets
import Qt5Compat.GraphicalEffects

Item {
    id: root

    // 格式化函数
    function formatTime(ms) {
        const totalSeconds = Math.floor(ms / 1000);
        const hours = Math.floor(totalSeconds / 3600);
        const minutes = Math.floor((totalSeconds % 3600) / 60);
        const seconds = totalSeconds % 60;
        const tenths = Math.floor((ms % 1000) / 100);
        return Qt.formatDateTime(new Date(0, 0, 0, hours, minutes, seconds), "hh:mm:ss");
    }

    property bool running: false
    property int elapsedTime: 0
    property real lastTime: 0
    property var lapTimes: []
    property int lastLapTime: 0

    Timer {
        id: stopwatchTimer
        interval: 500
        repeat: true
        running: root.running
        onTriggered: {
            const now = Date.now();
            elapsedTime += (now - lastTime);
            lastTime = now;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 20

        // Stopwatch display card
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: timeDisplayLayout.implicitHeight + 30
            color: Appearance.colors.colLayer2
            radius: Appearance.rounding.normal
            
            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 2
                radius: 8
                samples: 17
                color: Appearance.colors.colShadow
                transparentBorder: true
            }

            ColumnLayout {
                id: timeDisplayLayout
                anchors.centerIn: parent
                spacing: 8

                StyledText {
                    text: formatTime(elapsedTime)
                    font.family: Appearance.font.family.monospace
                    font.pixelSize: 56
                    color: Appearance.colors.colOnLayer2
                    Layout.alignment: Qt.AlignHCenter
                }
                
                // Current lap time display
                StyledText {
                    text: "Lap: " + formatTime(lastLapTime)
                    font.family: Appearance.font.family.monospace
                    font.pixelSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colSubtext
                    Layout.alignment: Qt.AlignHCenter
                    visible: lapTimes.length > 0
                }
            }
        }

        // Control buttons
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 12

            RippleButton {
                implicitWidth: 45
                implicitHeight: 45
                buttonRadius: Appearance.rounding.full
                colBackground: Appearance.colors.colSurfaceContainerHigh
                colBackgroundHover: Appearance.colors.colSurfaceContainerHighestHover
                enabled: stopwatchTimer.running || elapsedTime > 0
                onClicked: {
                    if (!stopwatchTimer.running && elapsedTime > 0) {
                        // Clear all data
                        elapsedTime = 0;
                        lapTimes = [];
                        lastLapTime = 0;
                    } else if (stopwatchTimer.running) {
                        // Record lap time
                        lapTimes.push(elapsedTime);
                        lastLapTime = elapsedTime;
                        lapTimes = lapTimes; // Trigger property change
                    }
                }

                contentItem: MaterialSymbol {
                    text: !stopwatchTimer.running && elapsedTime > 0 ? "clear" : "flag"
                    horizontalAlignment: Text.AlignHCenter
                    iconSize: Appearance.font.pixelSize.larger
                    color: parent.enabled ? Appearance.colors.colOnLayer3 : Appearance.colors.colOnLayer2Disabled
                }
            }

            RippleButton {
                implicitWidth: 60
                implicitHeight: 60
                buttonRadius: Appearance.rounding.full
                colBackground: stopwatchTimer.running ? Appearance.colors.colSecondaryContainer : Appearance.colors.colPrimary
                colBackgroundHover: stopwatchTimer.running ? Appearance.colors.colSecondaryContainerHover : Appearance.colors.colPrimaryHover
                onClicked: {
                    if (stopwatchTimer.running) {
                        root.running = false;
                    } else {
                        if (elapsedTime > 0) {
                            root.running = true;
                        } else {
                            lastTime = Date.now();
                            root.running = true;
                        }
                    }
                }

                contentItem: MaterialSymbol {
                    text: stopwatchTimer.running ? "pause" : "play_arrow"
                    horizontalAlignment: Text.AlignHCenter
                    iconSize: Appearance.font.pixelSize.huge
                    color: stopwatchTimer.running ? Appearance.colors.colOnSecondaryContainer : Appearance.m3colors.m3onPrimary
                }
            }

            RippleButton {
                implicitWidth: 45
                implicitHeight: 45
                buttonRadius: Appearance.rounding.full
                colBackground: Appearance.colors.colSurfaceContainerHigh
                colBackgroundHover: Appearance.colors.colSurfaceContainerHighestHover
                enabled: elapsedTime > 0 && !stopwatchTimer.running
                onClicked: {
                    elapsedTime = 0;
                    lapTimes = [];
                    lastLapTime = 0;
                }

                contentItem: MaterialSymbol {
                    text: "stop"
                    horizontalAlignment: Text.AlignHCenter
                    iconSize: Appearance.font.pixelSize.larger
                    color: parent.enabled ? Appearance.colors.colOnLayer3 : Appearance.colors.colOnLayer2Disabled
                }
            }
        }

        // Lap times list
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 0
            color: "transparent"
            visible: lapTimes.length > 0

            StyledFlickable {
                id: lapTimesFlickable
                anchors.fill: parent
                contentHeight: lapTimesColumn.height
                clip: true

                ColumnLayout {
                    id: lapTimesColumn
                    width: parent.width
                    spacing: 4

                    StyledText {
                        text: "Lap Times"
                        font.pixelSize: Appearance.font.pixelSize.large
                        color: Appearance.colors.colOnLayer2
                        Layout.alignment: Qt.AlignLeft
                        Layout.bottomMargin: 8
                    }

                    Repeater {
                        model: lapTimes.length
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: lapTimeLayout.implicitHeight + 8
                            color: Appearance.colors.colLayer2
                            radius: Appearance.rounding.small

                            RowLayout {
                                id: lapTimeLayout
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.margins: 12

                                StyledText {
                                    text: "Lap " + (index + 1)
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colOnLayer2
                                }

                                Item { Layout.fillWidth: true }

                                StyledText {
                                    text: formatTime(lapTimes[index] - (index > 0 ? lapTimes[index - 1] : 0))
                                    font.family: Appearance.font.family.monospace
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colOnLayer2
                                }

                                StyledText {
                                    text: formatTime(lapTimes[index])
                                    font.family: Appearance.font.family.monospace
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colSubtext
                                    Layout.leftMargin: 8
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
            visible: lapTimes.length === 0
        }
    }
}