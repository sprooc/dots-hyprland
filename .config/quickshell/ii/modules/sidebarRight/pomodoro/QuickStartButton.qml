import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RippleButton {
    id: root
    property string label: ""
    
    Layout.fillWidth: true
    implicitHeight: 35
    buttonRadius: Appearance.rounding.small
    colBackground: Appearance.colors.colLayer2
    colBackgroundHover: Appearance.colors.colLayer2Hover
    
    contentItem: StyledText {
        text: root.label
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: Appearance.font.pixelSize.small
        color: Appearance.colors.colOnLayer2
    }
}
