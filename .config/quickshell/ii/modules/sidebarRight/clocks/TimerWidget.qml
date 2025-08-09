import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import Qt5Compat.GraphicalEffects
import Quickshell.Io


Item {
    visible: true

    property int hours: 0
    property int minutes: 15
    property int seconds: 0
    property int initialTotalSeconds: 0
    property bool timerIsRunning: false
    property bool timerIsSet: false

    Process {
      id: notifyProc
      command: ['notify-send', 'Timer Finished', 'The countdown has completed.']
      running: false
    }

    Timer {
        id: countdownTimer
        interval: 1000
        repeat: true
        running: false
        onTriggered: {
            if (hours === 0 && minutes === 0 && seconds === 0) {
                stopTimer()
            } else {
                if (seconds > 0) {
                    seconds--
                } else {
                    seconds = 59
                    if (minutes > 0) {
                        minutes--
                    } else {
                        minutes = 59
                        if (hours > 0) {
                            hours--
                        }
                    }
                }
            }
        }
    }

    function formatTime(t) {
        return t < 10 ? "0" + t : t
    }

    function startTimer() {
        if (!timerIsSet) {
            initialTotalSeconds = hours * 3600 + minutes * 60 + seconds
            if (initialTotalSeconds === 0) return
            timerIsSet = true
        }
        timerIsRunning = true
        countdownTimer.running = true
    }

    function stopTimer() {
        timerIsRunning = false
        countdownTimer.running = false
        timerIsSet = false
        notifyProc.running = true
    }

    function pauseTimer() {
        timerIsRunning = false
        countdownTimer.running = false
    }

    function resetTimer() {
        pauseTimer()
        hours = Math.floor(initialTotalSeconds / 3600)
        minutes = Math.floor((initialTotalSeconds % 3600) / 60)
        seconds = initialTotalSeconds % 60
    }

    function deleteTimer() {
        pauseTimer()
        timerIsSet = false
        hours = 0
        minutes = 0
        seconds = 0
    }

    function quickSet(h, m, s) {
        hours = h
        minutes = m
        seconds = s
        startTimer()
    }

    StackLayout {
        anchors.fill: parent
        currentIndex: timerIsSet ? 1 : 0

        // 设置界面
        Item {
            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width * 0.9
                spacing: 12

                // Quick start buttons section
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    StyledText {
                        text: "Quick Start"
                        font.pixelSize: Appearance.font.pixelSize.large
                        color: Appearance.colors.colOnLayer2
                        Layout.alignment: Qt.AlignLeft
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 4
                        columnSpacing: 8
                        rowSpacing: 8

                        Repeater {
                            model: [
                                {label: "1 min", h: 0, m: 1, s: 0},
                                {label: "2 min", h: 0, m: 2, s: 0},
                                {label: "3 min", h: 0, m: 3, s: 0},
                                {label: "5 min", h: 0, m: 5, s: 0},
                                {label: "15 min", h: 0, m: 15, s: 0},
                                {label: "30 min", h: 0, m: 30, s: 0},
                                {label: "45 min", h: 0, m: 45, s: 0},
                                {label: "1 hour", h: 1, m: 0, s: 0}
                            ]
                            delegate: RippleButton {
                                Layout.fillWidth: true
                                implicitHeight: 30
                                buttonRadius: Appearance.rounding.small
                                colBackground: Appearance.colors.colLayer2
                                colBackgroundHover: Appearance.colors.colLayer2Hover
                                onClicked: quickSet(modelData.h, modelData.m, modelData.s)
                                
                                contentItem: StyledText {
                                    text: modelData.label
                                    horizontalAlignment: Text.AlignHCenter
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colOnLayer2
                                }
                            }
                        }
                    }
                }

                // Custom time selector section
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: timeSelectorLayout.implicitHeight + 16
                        color: Appearance.colors.colLayer2
                        radius: Appearance.rounding.small

                        RowLayout {
                            id: timeSelectorLayout
                            anchors.centerIn: parent
                            spacing: 8

                            TimeSelector {
                                value: hours
                                onValueChanged: hours = value
                            }
                            StyledText { 
                                text: ":" 
                                font.pixelSize: Appearance.font.pixelSize.larger
                                color: Appearance.colors.colSubtext
                            }
                            TimeSelector {
                                value: minutes
                                onValueChanged: minutes = value
                            }
                            StyledText { 
                                text: ":" 
                                font.pixelSize: Appearance.font.pixelSize.larger
                                color: Appearance.colors.colSubtext
                            }
                            TimeSelector {
                                value: seconds
                                onValueChanged: seconds = value
                            }
                        }
                    }

                    RippleButton {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: 50
                        implicitHeight: 50
                        buttonRadius: Appearance.rounding.full
                        colBackground: Appearance.colors.colPrimary
                        colBackgroundHover: Appearance.colors.colPrimaryHover
                        enabled: hours > 0 || minutes > 0 || seconds > 0
                        onClicked: startTimer()

                        contentItem: MaterialSymbol {
                            text: "play_arrow"
                            horizontalAlignment: Text.AlignHCenter
                            iconSize: Appearance.font.pixelSize.huge
                            color: Appearance.m3colors.m3onPrimary
                        }
                    }
                }
            }
        }

        // 运行界面
        Item {
            ColumnLayout {
                width: parent.width
                anchors.centerIn: parent
                spacing: 20

                // Timer display card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.margins: 12
                    implicitHeight: timerDisplayLayout.implicitHeight + 30
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
                        id: timerDisplayLayout
                        anchors.centerIn: parent
                        spacing: 8

                        StyledText {
                            text: formatTime(hours) + ":" + formatTime(minutes) + ":" + formatTime(seconds)
                            font.family: Appearance.font.family.monospace
                            font.pixelSize: 56
                            color: Appearance.colors.colOnLayer2
                            Layout.alignment: Qt.AlignHCenter
                        }

                        // Progress indicator
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.margins: 16
                            height: 4
                            color: Appearance.colors.colOutlineVariant
                            radius: 2

                            Rectangle {
                                height: parent.height
                                width: initialTotalSeconds > 0 ? 
                                    parent.width * (1 - (hours * 3600 + minutes * 60 + seconds) / initialTotalSeconds) : 0
                                color: Appearance.colors.colPrimary
                                radius: 2

                                Behavior on width {
                                    NumberAnimation {
                                        duration: 300
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
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
                        onClicked: resetTimer()

                        contentItem: MaterialSymbol {
                            text: "refresh"
                            horizontalAlignment: Text.AlignHCenter
                            iconSize: Appearance.font.pixelSize.larger
                            color: Appearance.colors.colOnLayer3
                        }
                    }

                    RippleButton {
                        implicitWidth: 60
                        implicitHeight: 60
                        buttonRadius: Appearance.rounding.full
                        colBackground: timerIsRunning ? Appearance.colors.colSecondaryContainer : Appearance.colors.colPrimary
                        colBackgroundHover: timerIsRunning ? Appearance.colors.colSecondaryContainerHover : Appearance.colors.colPrimaryHover
                        onClicked: timerIsRunning ? pauseTimer() : startTimer()

                        contentItem: MaterialSymbol {
                            text: timerIsRunning ? "pause" : "play_arrow"
                            horizontalAlignment: Text.AlignHCenter
                            iconSize: Appearance.font.pixelSize.huge
                            color: timerIsRunning ? Appearance.colors.colOnSecondaryContainer : Appearance.m3colors.m3onPrimary
                        }
                    }

                    RippleButton {
                        implicitWidth: 45
                        implicitHeight: 45
                        buttonRadius: Appearance.rounding.full
                        colBackground: Appearance.colors.colSurfaceContainerHigh
                        colBackgroundHover: Appearance.colors.colSurfaceContainerHighestHover
                        onClicked: deleteTimer()

                        contentItem: MaterialSymbol {
                            text: "stop"
                            horizontalAlignment: Text.AlignHCenter
                            iconSize: Appearance.font.pixelSize.larger
                            color: Appearance.colors.colOnLayer3
                        }
                    }
                }
            }
        }
    }
} 
