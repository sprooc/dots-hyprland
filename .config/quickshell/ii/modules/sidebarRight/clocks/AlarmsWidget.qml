import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import Qt5Compat.GraphicalEffects
import Quickshell.Io

Item {
    visible: true

    // Alarm data model
    property var alarms: []
    property bool showAddEditDialog: false
    property bool isEditing: false
    property int editingIndex: -1
    
    // Persistence using FileView
    property string alarmsFilePath: Directories.alarmPath
    
    FileView {
        id: alarmsFileView
        path: Qt.resolvedUrl(alarmsFilePath)
        
        onLoaded: {
            try {
                var loadedAlarms = JSON.parse(alarmsFileView.text());
                if (Array.isArray(loadedAlarms)) {
                    // Ensure each alarm has all required properties
                    alarms = loadedAlarms.map(alarm => ({
                        hour: alarm.hour || 12,
                        minute: alarm.minute || 0,
                        ampm: alarm.ampm || "AM",
                        name: alarm.name || "",
                        enabled: alarm.enabled !== undefined ? alarm.enabled : true,
                        repeatDays: Array.isArray(alarm.repeatDays) ? alarm.repeatDays : []
                    }));
                }
            } catch (e) {
                console.log("Failed to parse alarms file:", e);
                alarms = [];
                saveAlarms();
            }
        }
        
        onLoadFailed: (error) => {
            if (error == FileViewError.FileNotFound) {
                alarms = [];
                saveAlarms();
            } else {
                console.log("Failed to load alarms file:", error);
            }
        }
    }
    
    Component.onCompleted: {
        // Create data directory if it doesn't exist
        createDirProc.running = true;
    }
    
    Process {
        id: createDirProc
        command: ["mkdir", "-p", Directories.configPath + "/quickshell/ii/data"]
        running: false
    }
    
    function saveAlarms() {
        var jsonData = JSON.stringify(alarms, null, 2);
        alarmsFileView.setText(jsonData);
    }
    
    // Current alarm being edited
    property var currentAlarm: ({
        hour: 12,
        minute: 0,
        ampm: "AM",
        name: "",
        enabled: true,
        repeatDays: [] // Array of selected days: 0=Sunday, 1=Monday, etc.
    })

    // Timer for checking alarm triggers
    Timer {
        id: alarmChecker
        interval: 10000 // Check every second
        repeat: true
        running: true
        onTriggered: checkAlarms()
    }

    Process {
        id: alarmNotifyProc
        command: ['notify-send', 'Alarm', 'Wake up!']
        running: false
    }

    function checkAlarms() {
        var now = new Date()
        var currentHour = now.getHours()
        var currentMinute = now.getMinutes()
        var currentDay = now.getDay() // 0=Sunday, 1=Monday, etc.
        
        for (var i = 0; i < alarms.length; i++) {
            var alarm = alarms[i]
            if (!alarm || !alarm.enabled) continue
            
            var alarmHour = alarm.hour
            if (alarm.ampm === "PM" && alarmHour !== 12) {
                alarmHour += 12
            } else if (alarm.ampm === "AM" && alarmHour === 12) {
                alarmHour = 0
            }
            
            if (alarmHour === currentHour && alarm.minute === currentMinute && now.getSeconds() === 0) {
                if (!alarm.repeatDays || alarm.repeatDays.length === 0 || alarm.repeatDays.includes(currentDay)) {
                    triggerAlarm(alarm)
                }
            }
        }
    }

    function triggerAlarm(alarm) {
        alarmNotifyProc.command = ['notify-send', 'Alarm', (alarm.name || 'Untitled')]
        alarmNotifyProc.running = true
    }

    function addAlarm() {
        currentAlarm = {
            hour: 12,
            minute: 0,
            ampm: "AM",
            name: "",
            enabled: true,
            repeatDays: []
        }
        isEditing = false
        showAddEditDialog = true
    }

    function editAlarm(index) {
        if (index >= 0 && index < alarms.length) {
            currentAlarm = JSON.parse(JSON.stringify(alarms[index]))
            editingIndex = index
            isEditing = true
            showAddEditDialog = true
        }
    }

    function saveAlarm() {
        if (isEditing) {
            alarms[editingIndex] = JSON.parse(JSON.stringify(currentAlarm))
        } else {
            alarms.push(JSON.parse(JSON.stringify(currentAlarm)))
        }
        alarms = alarms.slice() // Trigger property change
        saveAlarms() // Save to file
        showAddEditDialog = false
    }

    function deleteAlarm(index) {
        if (index >= 0 && index < alarms.length) {
            alarms.splice(index, 1)
            alarms = alarms.slice() // Trigger property change
            saveAlarms() // Save to file
        }
    }

    function formatTime(hour, minute, ampm) {
        var h = hour.toString().padStart(2, '0')
        var m = minute.toString().padStart(2, '0')
        return h + ":" + m + " " + ampm
    }

    StackLayout {
        anchors.fill: parent
        currentIndex: showAddEditDialog ? 2 : (alarms.length === 0 ? 0 : 1)

        // Empty State View
        Item {
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 16

                MaterialSymbol {
                    text: "alarm"
                    iconSize: 64
                    color: Appearance.m3colors.m3outline
                    Layout.alignment: Qt.AlignHCenter
                }

                StyledText {
                    text: "No alarms yet"
                    font.pixelSize: Appearance.font.pixelSize.large
                    color: Appearance.m3colors.m3outline
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        // Alarm List View
        Item {
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                StyledFlickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentHeight: alarmListColumn.height
                    clip: true
                    
                    ColumnLayout {
                        id: alarmListColumn
                        width: parent.width
                        spacing: 8
                        
                        Repeater {
                            model: alarms.length
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: alarmItemLayout.implicitHeight + 16
                                color: Appearance.colors.colLayer2
                                radius: Appearance.rounding.small
                                
                                layer.enabled: true
                                layer.effect: DropShadow {
                                    horizontalOffset: 0
                                    verticalOffset: 1
                                    radius: 3
                                    samples: 7
                                    color: Appearance.colors.colShadow
                                    transparentBorder: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.rightMargin: 80
                                    onClicked: editAlarm(index)
                                    cursorShape: Qt.PointingHandCursor
                                }

                                RowLayout {
                                    id: alarmItemLayout
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    spacing: 12

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 4

                                        StyledText {
                                            text: alarms[index] ? formatTime(alarms[index].hour, alarms[index].minute, alarms[index].ampm) : ""
                                            font.family: Appearance.font.family.monospace
                                            font.pixelSize: Appearance.font.pixelSize.larger
                                            color: (alarms[index] && alarms[index].enabled) ? Appearance.colors.colOnLayer2 : Appearance.colors.colOnLayer2Disabled
                                        }

                                        StyledText {
                                            text: (alarms[index] && alarms[index].name) ? alarms[index].name : "Alarm"
                                            font.pixelSize: Appearance.font.pixelSize.small
                                            color: Appearance.colors.colSubtext
                                            visible: alarms[index] && alarms[index].name !== ""
                                        }

                                        // Repeat days display
                                        RowLayout {
                                            spacing: 4
                                            visible: alarms[index] && alarms[index].repeatDays && alarms[index].repeatDays.length > 0
                                            
                                            property var dayLabels: ["S", "M", "T", "W", "T", "F", "S"]
                                            
                                            Repeater {
                                                model: 7
                                                delegate: Rectangle {
                                                    width: 16
                                                    height: 16
                                                    radius: 8
                                                    color: (alarms[index] && alarms[index].repeatDays && alarms[index].repeatDays.includes(index)) ? 
                                                        Appearance.colors.colPrimary : "transparent"
                                                    border.width: 1
                                                    border.color: (alarms[index] && alarms[index].repeatDays && alarms[index].repeatDays.includes(index)) ? 
                                                        Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant
                                                    
                                                    StyledText {
                                                        text: parent.parent.dayLabels[index]
                                                        anchors.centerIn: parent
                                                        font.pixelSize: 8
                                                        color: (alarms[index] && alarms[index].repeatDays && alarms[index].repeatDays.includes(index)) ? 
                                                            Appearance.m3colors.m3onPrimary : Appearance.colors.colSubtext
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Toggle switch
                                    RippleButton {
                                        implicitWidth: 44
                                        implicitHeight: 24
                                        buttonRadius: 12
                                        colBackground: (alarms[index] && alarms[index].enabled) ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant
                                        onClicked: {
                                            if (alarms[index]) {
                                                alarms[index].enabled = !alarms[index].enabled
                                                alarms = alarms.slice()
                                                saveAlarms()
                                            }
                                        }

                                        contentItem: Rectangle {
                                            width: 20
                                            height: 20
                                            radius: 10
                                            color: Appearance.colors.colLayer2
                                            x: (alarms[index] && alarms[index].enabled) ? parent.width - width - 2 : 2
                                            y: 2

                                            Behavior on x {
                                                NumberAnimation { duration: 200 }
                                            }
                                        }
                                    }

                                    // Delete button
                                    RippleButton {
                                        implicitWidth: 32
                                        implicitHeight: 32
                                        buttonRadius: Appearance.rounding.full
                                        colBackground: "transparent"
                                        colBackgroundHover: Appearance.colors.colLayer1Hover
                                        onClicked: deleteAlarm(index)

                                        contentItem: MaterialSymbol {
                                            text: "close"
                                            horizontalAlignment: Text.AlignHCenter
                                            iconSize: Appearance.font.pixelSize.normal
                                            color: Appearance.colors.colOnLayer2
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Add/Edit Alarm View
        Item {
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16



                StyledFlickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentHeight: editFormColumn.height
                    
                    ColumnLayout {
                        id: editFormColumn
                        width: parent.width
                        spacing: 24
                        // Header
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            RippleButton {
                                implicitWidth: 60
                                implicitHeight: 32
                                buttonRadius: Appearance.rounding.small
                                colBackground: "transparent"
                                colBackgroundHover: Appearance.colors.colLayer1Hover
                                onClicked: showAddEditDialog = false
                                
                                contentItem: StyledText {
                                    text: "Cancel"
                                    horizontalAlignment: Text.AlignHCenter
                                    color: Appearance.colors.colPrimary
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                }
                            }

                            StyledText {
                                text: isEditing ? "Edit Alarm" : "New Alarm"
                                font.pixelSize: Appearance.font.pixelSize.larger
                                color: Appearance.colors.colOnLayer2
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                            }

                            RippleButton {
                                implicitWidth: 60
                                implicitHeight: 32
                                buttonRadius: Appearance.rounding.small
                                colBackground: Appearance.colors.colPrimary
                                colBackgroundHover: Appearance.colors.colPrimaryHover
                                onClicked: saveAlarm()
                                
                                contentItem: StyledText {
                                    text: isEditing ? "Save" : "Add"
                                    horizontalAlignment: Text.AlignHCenter
                                    color: Appearance.m3colors.m3onPrimary
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                }
                            }
                        }
                        // Time Picker Card
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: timePickerLayout.implicitHeight + 32
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

                            RowLayout {
                                id: timePickerLayout
                                anchors.centerIn: parent
                                spacing: 16

                                // Hour Picker
                                ColumnLayout {
                                    spacing: 8
                                    
                                    RippleButton {
                                        Layout.alignment: Qt.AlignHCenter
                                        implicitWidth: 32
                                        implicitHeight: 32
                                        buttonRadius: Appearance.rounding.small
                                        colBackground: "transparent"
                                        colBackgroundHover: Appearance.colors.colLayer1Hover
                                        onClicked: {
                                            var newAlarm = JSON.parse(JSON.stringify(currentAlarm))
                                            newAlarm.hour = newAlarm.hour === 12 ? 1 : newAlarm.hour + 1
                                            currentAlarm = newAlarm
                                        }

                                        contentItem: MaterialSymbol {
                                            text: "keyboard_arrow_up"
                                            horizontalAlignment: Text.AlignHCenter
                                            iconSize: Appearance.font.pixelSize.large
                                            color: Appearance.colors.colOnLayer2
                                        }
                                    }
                                    
                                    Rectangle {
                                        Layout.preferredWidth: 60
                                        Layout.preferredHeight: 50
                                        Layout.alignment: Qt.AlignHCenter
                                        color: Appearance.colors.colSurfaceContainerHigh
                                        radius: Appearance.rounding.small
                                        
                                        StyledText {
                                            text: currentAlarm.hour.toString().padStart(2, '0')
                                            font.family: Appearance.font.family.monospace
                                            font.pixelSize: Appearance.font.pixelSize.huge
                                            color: Appearance.colors.colOnLayer3
                                            anchors.centerIn: parent
                                        }
                                    }
                                    
                                    RippleButton {
                                        Layout.alignment: Qt.AlignHCenter
                                        implicitWidth: 32
                                        implicitHeight: 32
                                        buttonRadius: Appearance.rounding.small
                                        colBackground: "transparent"
                                        colBackgroundHover: Appearance.colors.colLayer1Hover
                                        onClicked: {
                                            var newAlarm = JSON.parse(JSON.stringify(currentAlarm))
                                            newAlarm.hour = newAlarm.hour === 1 ? 12 : newAlarm.hour - 1
                                            currentAlarm = newAlarm
                                        }

                                        contentItem: MaterialSymbol {
                                            text: "keyboard_arrow_down"
                                            horizontalAlignment: Text.AlignHCenter
                                            iconSize: Appearance.font.pixelSize.large
                                            color: Appearance.colors.colOnLayer2
                                        }
                                    }
                                }

                                StyledText {
                                    text: ":"
                                    font.family: Appearance.font.family.monospace
                                    font.pixelSize: Appearance.font.pixelSize.huge
                                    color: Appearance.colors.colSubtext
                                }

                                // Minute Picker
                                ColumnLayout {
                                    spacing: 8
                                    
                                    RippleButton {
                                        Layout.alignment: Qt.AlignHCenter
                                        implicitWidth: 32
                                        implicitHeight: 32
                                        buttonRadius: Appearance.rounding.small
                                        colBackground: "transparent"
                                        colBackgroundHover: Appearance.colors.colLayer1Hover
                                        onClicked: {
                                            var newAlarm = JSON.parse(JSON.stringify(currentAlarm))
                                            newAlarm.minute = (newAlarm.minute + 1) % 60
                                            currentAlarm = newAlarm
                                        }

                                        contentItem: MaterialSymbol {
                                            text: "keyboard_arrow_up"
                                            horizontalAlignment: Text.AlignHCenter
                                            iconSize: Appearance.font.pixelSize.large
                                            color: Appearance.colors.colOnLayer2
                                        }
                                    }
                                    
                                    Rectangle {
                                        Layout.preferredWidth: 60
                                        Layout.preferredHeight: 50
                                        Layout.alignment: Qt.AlignHCenter
                                        color: Appearance.colors.colSurfaceContainerHigh
                                        radius: Appearance.rounding.small
                                        
                                        StyledText {
                                            text: currentAlarm.minute.toString().padStart(2, '0')
                                            font.family: Appearance.font.family.monospace
                                            font.pixelSize: Appearance.font.pixelSize.huge
                                            color: Appearance.colors.colOnLayer3
                                            anchors.centerIn: parent
                                        }
                                    }
                                    
                                    RippleButton {
                                        Layout.alignment: Qt.AlignHCenter
                                        implicitWidth: 32
                                        implicitHeight: 32
                                        buttonRadius: Appearance.rounding.small
                                        colBackground: "transparent"
                                        colBackgroundHover: Appearance.colors.colLayer1Hover
                                        onClicked: {
                                            var newAlarm = JSON.parse(JSON.stringify(currentAlarm))
                                            newAlarm.minute = newAlarm.minute === 0 ? 59 : newAlarm.minute - 1
                                            currentAlarm = newAlarm
                                        }

                                        contentItem: MaterialSymbol {
                                            text: "keyboard_arrow_down"
                                            horizontalAlignment: Text.AlignHCenter
                                            iconSize: Appearance.font.pixelSize.large
                                            color: Appearance.colors.colOnLayer2
                                        }
                                    }
                                }

                                // AM/PM Picker
                                ColumnLayout {
                                    spacing: 8
                                    Layout.leftMargin: 16
                                    
                                    RippleButton {
                                        Layout.alignment: Qt.AlignHCenter
                                        implicitWidth: 50
                                        implicitHeight: 40
                                        buttonRadius: Appearance.rounding.small
                                        colBackground: currentAlarm.ampm === "AM" ? Appearance.colors.colPrimary : Appearance.colors.colSurfaceContainerHigh
                                        colBackgroundHover: currentAlarm.ampm === "AM" ? Appearance.colors.colPrimaryHover : Appearance.colors.colSurfaceContainerHighestHover
                                        onClicked: {
                                            var newAlarm = JSON.parse(JSON.stringify(currentAlarm))
                                            newAlarm.ampm = "AM"
                                            currentAlarm = newAlarm
                                        }
                                        
                                        contentItem: StyledText {
                                            text: "AM"
                                            horizontalAlignment: Text.AlignHCenter
                                            color: currentAlarm.ampm === "AM" ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer3
                                            font.pixelSize: Appearance.font.pixelSize.normal
                                        }
                                    }
                                    
                                    RippleButton {
                                        Layout.alignment: Qt.AlignHCenter
                                        implicitWidth: 50
                                        implicitHeight: 40
                                        buttonRadius: Appearance.rounding.small
                                        colBackground: currentAlarm.ampm === "PM" ? Appearance.colors.colPrimary : Appearance.colors.colSurfaceContainerHigh
                                        colBackgroundHover: currentAlarm.ampm === "PM" ? Appearance.colors.colPrimaryHover : Appearance.colors.colSurfaceContainerHighestHover
                                        onClicked: {
                                            var newAlarm = JSON.parse(JSON.stringify(currentAlarm))
                                            newAlarm.ampm = "PM"
                                            currentAlarm = newAlarm
                                        }
                                        
                                        contentItem: StyledText {
                                            text: "PM"
                                            horizontalAlignment: Text.AlignHCenter
                                            color: currentAlarm.ampm === "PM" ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer3
                                            font.pixelSize: Appearance.font.pixelSize.normal
                                        }
                                    }
                                }
                            }
                        }

                        // Repeat Options Card
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: repeatLayout.implicitHeight + 24
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
                                id: repeatLayout
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.margins: 16
                                spacing: 12

                                StyledText {
                                    text: "Repeat"
                                    font.pixelSize: Appearance.font.pixelSize.large
                                    color: Appearance.colors.colOnLayer2
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    property var dayLabels: ["S", "M", "T", "W", "T", "F", "S"]

                                    Repeater {
                                        model: 7
                                        
                                        RippleButton {
                                            Layout.preferredWidth: 35
                                            Layout.preferredHeight: 35
                                            buttonRadius: Appearance.rounding.full
                                            
                                            property bool isSelected: currentAlarm.repeatDays.includes(index)
                                            
                                            colBackground: isSelected ? Appearance.colors.colPrimary : Appearance.colors.colSurfaceContainerHigh
                                            colBackgroundHover: isSelected ? Appearance.colors.colPrimaryHover : Appearance.colors.colSurfaceContainerHighestHover
                                            
                                            onClicked: {
                                                var days = currentAlarm.repeatDays.slice()
                                                var dayIndex = days.indexOf(index)
                                                if (dayIndex > -1) {
                                                    days.splice(dayIndex, 1)
                                                } else {
                                                    days.push(index)
                                                }
                                                var newAlarm = JSON.parse(JSON.stringify(currentAlarm))
                                                newAlarm.repeatDays = days
                                                currentAlarm = newAlarm
                                            }
                                            
                                            contentItem: StyledText {
                                                text: parent.parent.dayLabels[index]
                                                horizontalAlignment: Text.AlignHCenter
                                                color: isSelected ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer3
                                                font.pixelSize: Appearance.font.pixelSize.small
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Name Input Card
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: nameLayout.implicitHeight + 24
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
                                id: nameLayout
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.margins: 16
                                spacing: 12

                                StyledText {
                                    text: "Name"
                                    font.pixelSize: Appearance.font.pixelSize.large
                                    color: Appearance.colors.colOnLayer2
                                }

                                TextField {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 40
                                    
                                    text: currentAlarm.name
                                    placeholderText: "Alarm name (optional)"
                                    color: Appearance.colors.colOnLayer2
                                    placeholderTextColor: Appearance.colors.colSubtext
                                    
                                    background: Rectangle {
                                        color: Appearance.colors.colSurfaceContainerHigh
                                        radius: Appearance.rounding.small
                                        border.width: 2
                                        border.color: parent.activeFocus ? Appearance.colors.colPrimary : "transparent"
                                    }
                                    
                                    onTextChanged: {
                                        var newAlarm = JSON.parse(JSON.stringify(currentAlarm))
                                        newAlarm.name = text
                                        currentAlarm = newAlarm
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Add some margin for the FAB
    property int fabMargins: 14

    // Shadow for the FAB
    StyledRectangularShadow {
        target: fabButton
        radius: fabButton.buttonRadius
        blur: 0.6 * Appearance.sizes.elevationMargin
    }

    FloatingActionButton {
        id: fabButton
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: fabMargins
        anchors.bottomMargin: fabMargins

        onClicked: addAlarm()

        contentItem: MaterialSymbol {
            text: "add"
            horizontalAlignment: Text.AlignHCenter
            iconSize: Appearance.font.pixelSize.huge
            color: Appearance.m3colors.m3onPrimaryContainer
        }
    }
}
