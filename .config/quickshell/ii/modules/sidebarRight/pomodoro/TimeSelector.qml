import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    property int value: 0
    spacing: 2

    RippleButton {
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: 28
        implicitHeight: 28
        buttonRadius: Appearance.rounding.small
        colBackground: "transparent"
        colBackgroundHover: Appearance.colors.colLayer1Hover
        onClicked: value = (value + 1) % 60

        contentItem: MaterialSymbol {
            text: "keyboard_arrow_up"
            horizontalAlignment: Text.AlignHCenter
            iconSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer2
        }
    }

    StyledText {
        text: value < 10 ? "0" + value : value
        font.family: Appearance.font.family.monospace
        font.pixelSize: Appearance.font.pixelSize.larger
        color: Appearance.colors.colOnLayer2
        Layout.alignment: Qt.AlignHCenter
        horizontalAlignment: Text.AlignHCenter
    }

    RippleButton {
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: 28
        implicitHeight: 28
        buttonRadius: Appearance.rounding.small
        colBackground: "transparent"
        colBackgroundHover: Appearance.colors.colLayer1Hover
        onClicked: value = (value + 59) % 60

        contentItem: MaterialSymbol {
            text: "keyboard_arrow_down"
            horizontalAlignment: Text.AlignHCenter
            iconSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer2
        }
    }
}
