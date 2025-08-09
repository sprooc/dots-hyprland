import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import Qt5Compat.GraphicalEffects

Item {
    visible: true

    // World clock data model
    property var worldClocks: [
        {
            city: "Beijing",
            timezone: "Asia/Shanghai",
            offset: 8, // UTC offset
            country: "China"
        },
        {
            city: "New York",
            timezone: "America/New_York",
            offset: -5,
            country: "USA"
        },
        {
            city: "London",
            timezone: "Europe/London",
            offset: 0,
            country: "UK"
        },
        {
            city: "Tokyo",
            timezone: "Asia/Tokyo",
            offset: 9,
            country: "Japan"
        }
    ]
    
    property bool showAddDialog: false
    
    // Current clock being added
    property var currentClock: ({
        city: "",
        timezone: "",
        offset: 0,
        country: ""
    })

    // Available timezones
    property var availableTimezones: [
        { city: "Beijing", timezone: "Asia/Shanghai", offset: 8, country: "China" },
        { city: "Shanghai", timezone: "Asia/Shanghai", offset: 8, country: "China" },
        { city: "New York", timezone: "America/New_York", offset: -5, country: "USA" },
        { city: "Los Angeles", timezone: "America/Los_Angeles", offset: -8, country: "USA" },
        { city: "Chicago", timezone: "America/Chicago", offset: -6, country: "USA" },
        { city: "London", timezone: "Europe/London", offset: 0, country: "UK" },
        { city: "Paris", timezone: "Europe/Paris", offset: 1, country: "France" },
        { city: "Berlin", timezone: "Europe/Berlin", offset: 1, country: "Germany" },
        { city: "Moscow", timezone: "Europe/Moscow", offset: 3, country: "Russia" },
        { city: "Dubai", timezone: "Asia/Dubai", offset: 4, country: "UAE" },
        { city: "Mumbai", timezone: "Asia/Kolkata", offset: 5.5, country: "India" },
        { city: "Tokyo", timezone: "Asia/Tokyo", offset: 9, country: "Japan" },
        { city: "Sydney", timezone: "Australia/Sydney", offset: 11, country: "Australia" },
        { city: "Auckland", timezone: "Pacific/Auckland", offset: 13, country: "New Zealand" }
    ]

    // Timer for updating times
    Timer {
        id: timeUpdater
        interval: 1000 // Update every second
        repeat: true
        running: true
        onTriggered: updateTimes()
    }

    function updateTimes() {
        // Force refresh - this will automatically update the display
        // since we're using Repeater with worldClocks.length
    }

    function formatTimeForTimezone(offset) {
        var now = new Date()
        var utc = now.getTime() + (now.getTimezoneOffset() * 60000)
        var targetTime = new Date(utc + (offset * 3600000))
        
        var hours = targetTime.getHours()
        var minutes = targetTime.getMinutes()
        
        return hours.toString().padStart(2, '0') + ":" + 
               minutes.toString().padStart(2, '0')
    }

    function formatDateForTimezone(offset) {
        var now = new Date()
        var utc = now.getTime() + (now.getTimezoneOffset() * 60000)
        var targetTime = new Date(utc + (offset * 3600000))
        
        var options = { 
            weekday: 'short', 
            month: 'short', 
            day: 'numeric' 
        }
        return targetTime.toLocaleDateString('en-US', options)
    }

    function addClock() {
        currentClock = {
            city: "",
            timezone: "",
            offset: 0,
            country: ""
        }
        showAddDialog = true
    }

    function saveClock() {
        if (currentClock.city !== "" && currentClock.timezone !== "") {
            worldClocks.push(JSON.parse(JSON.stringify(currentClock)))
            worldClocks = worldClocks.slice() // Trigger property change
            showAddDialog = false
        }
    }

    function deleteClock(index) {
        if (index >= 0 && index < worldClocks.length) {
            worldClocks.splice(index, 1)
            worldClocks = worldClocks.slice() // Trigger property change
        }
    }

    StackLayout {
        anchors.fill: parent
        currentIndex: showAddDialog ? 2 : (worldClocks.length === 0 ? 0 : 1)

        // Empty State View
        Item {
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 16

                MaterialSymbol {
                    text: "public"
                    iconSize: 64
                    color: Appearance.m3colors.m3outline
                    Layout.alignment: Qt.AlignHCenter
                }

                StyledText {
                    text: "No world clocks yet"
                    font.pixelSize: Appearance.font.pixelSize.large
                    color: Appearance.m3colors.m3outline
                    Layout.alignment: Qt.AlignHCenter
                }

                RippleButton {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 140
                    implicitHeight: 40
                    buttonRadius: Appearance.rounding.small
                    colBackground: Appearance.colors.colPrimary
                    colBackgroundHover: Appearance.colors.colPrimaryHover
                    onClicked: addClock()
                    
                    contentItem: StyledText {
                        text: "Add World Clock"
                        horizontalAlignment: Text.AlignHCenter
                        color: Appearance.m3colors.m3onPrimary
                        font.pixelSize: Appearance.font.pixelSize.normal
                    }
                }
            }
        }

        // World Clocks List View
        Item {
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                StyledFlickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentHeight: clockListColumn.height
                    clip: true
                    
                    ColumnLayout {
                        id: clockListColumn
                        width: parent.width
                        spacing: 8
                        
                        Repeater {
                            model: worldClocks.length
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: clockItemLayout.implicitHeight + 18
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

                                RowLayout {
                                    id: clockItemLayout
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    spacing: 12

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 4

                                        StyledText {
                                            text: worldClocks[index].city
                                            font.pixelSize: Appearance.font.pixelSize.large
                                            color: Appearance.colors.colOnLayer2
                                        }

                                        StyledText {
                                            text: worldClocks[index].country
                                            font.pixelSize: Appearance.font.pixelSize.small
                                            color: Appearance.colors.colSubtext
                                        }

                                        StyledText {
                                            text: formatDateForTimezone(worldClocks[index].offset)
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            color: Appearance.colors.colSubtext
                                        }
                                    }

                                    ColumnLayout {
                                        spacing: 4
                                        Layout.minimumWidth: 80
                                        Layout.alignment: Qt.AlignRight

                                        StyledText {
                                            text: formatTimeForTimezone(worldClocks[index].offset)
                                            font.family: Appearance.font.family.monospace
                                            font.pixelSize: Appearance.font.pixelSize.larger
                                            color: Appearance.colors.colOnLayer2
                                            Layout.alignment: Qt.AlignRight
                                            horizontalAlignment: Text.AlignRight
                                        }

                                        StyledText {
                                            text: "UTC" + (worldClocks[index].offset >= 0 ? "+" : "") + worldClocks[index].offset
                                            font.family: Appearance.font.family.monospace
                                            font.pixelSize: Appearance.font.pixelSize.smallest
                                            color: Appearance.colors.colSubtext
                                            Layout.alignment: Qt.AlignRight
                                            horizontalAlignment: Text.AlignRight
                                        }
                                    }

                                    RippleButton {
                                        implicitWidth: 32
                                        implicitHeight: 32
                                        buttonRadius: Appearance.rounding.full
                                        colBackground: "transparent"
                                        colBackgroundHover: Appearance.colors.colLayer1Hover
                                        onClicked: deleteClock(index)

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
                        
                        // Bottom padding for FAB
                        Item {
                            implicitHeight: 80
                        }
                    }
                }
            }
            
            // + FAB
            StyledRectangularShadow {
                target: fabButton
                radius: fabButton.buttonRadius
                blur: 0.6 * Appearance.sizes.elevationMargin
            }
            FloatingActionButton {
                id: fabButton
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.rightMargin: 14
                anchors.bottomMargin: 14

                onClicked: addClock()

                contentItem: MaterialSymbol {
                    text: "add"
                    horizontalAlignment: Text.AlignHCenter
                    iconSize: Appearance.font.pixelSize.huge
                    color: Appearance.m3colors.m3onPrimaryContainer
                }
            }
        }

        // Add Clock Dialog
        Item {
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16

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
                        onClicked: showAddDialog = false
                        
                        contentItem: StyledText {
                            text: "Cancel"
                            horizontalAlignment: Text.AlignHCenter
                            color: Appearance.colors.colPrimary
                            font.pixelSize: Appearance.font.pixelSize.normal
                        }
                    }

                    StyledText {
                        text: "Add World Clock"
                        font.pixelSize: Appearance.font.pixelSize.larger
                        color: Appearance.colors.colOnLayer2
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                    }

                    RippleButton {
                        implicitWidth: 60
                        implicitHeight: 32
                        buttonRadius: Appearance.rounding.small
                        colBackground: currentClock.city !== "" ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant
                        colBackgroundHover: currentClock.city !== "" ? Appearance.colors.colPrimaryHover : Appearance.colors.colOutlineVariant
                        enabled: currentClock.city !== ""
                        onClicked: saveClock()
                        
                        contentItem: StyledText {
                            text: "Add"
                            horizontalAlignment: Text.AlignHCenter
                            color: enabled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer2Disabled
                            font.pixelSize: Appearance.font.pixelSize.normal
                        }
                    }
                }

                // City Selection List
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
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

                    StyledFlickable {
                        anchors.fill: parent
                        anchors.margins: 12
                        contentHeight: cityListColumn.height
                        clip: true
                        
                        ColumnLayout {
                            id: cityListColumn
                            width: parent.width
                            spacing: 4
                            
                            Repeater {
                                model: availableTimezones.length
                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: timezoneItemLayout.implicitHeight + 12
                                    color: currentClock.city === availableTimezones[index].city ? 
                                        Appearance.colors.colPrimaryContainer : "transparent"
                                    radius: Appearance.rounding.small
                                    border.width: currentClock.city === availableTimezones[index].city ? 2 : 0
                                    border.color: Appearance.colors.colPrimary

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            currentClock = JSON.parse(JSON.stringify(availableTimezones[index]))
                                        }
                                        cursorShape: Qt.PointingHandCursor
                                    }

                                    RowLayout {
                                        id: timezoneItemLayout
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 12

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 2

                                            StyledText {
                                                text: availableTimezones[index].city
                                                font.pixelSize: Appearance.font.pixelSize.normal
                                                color: currentClock.city === availableTimezones[index].city ? 
                                                    Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer2
                                            }

                                            StyledText {
                                                text: availableTimezones[index].country
                                                font.pixelSize: Appearance.font.pixelSize.small
                                                color: currentClock.city === availableTimezones[index].city ? 
                                                    Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
                                            }
                                        }

                                        StyledText {
                                            text: "UTC" + (availableTimezones[index].offset >= 0 ? "+" : "") + availableTimezones[index].offset
                                            font.family: Appearance.font.family.monospace
                                            font.pixelSize: Appearance.font.pixelSize.small
                                            color: currentClock.city === availableTimezones[index].city ? 
                                                Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
                                            Layout.minimumWidth: 60
                                            Layout.alignment: Qt.AlignRight
                                            horizontalAlignment: Text.AlignRight
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}