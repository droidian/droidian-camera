import QtQuick 2.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.0

Item {
    id: cameraListButton
    property alias value : popup.currentValue
    property alias model : popup.model

    width: 70
    height: 70

    Button {
        id: btnCameraSelect
        anchors.left: parent.right
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: parent.width
        implicitHeight: parent.height
        icon.name: "emblem-synchronizing-symbolic"
        icon.width: Math.round(btnCameraSelect.width * 0.5)
        icon.height: Math.round(btnCameraSelect.height * 0.5)
        icon.color: "lightblue"

        background: Rectangle {
            anchors.fill: parent
            color: "#99000000"
            border.width: 2
            border.color: "lightblue"
            radius: 90
        }

        onClicked: popup.toggle()
    }

    CameraListPopup {
        id: popup
        anchors.left: parent.right
        anchors.bottom: parent.top
        anchors.bottomMargin: 16
        visible: opacity > 0

        onSelected: popup.toggle()
    }
}
