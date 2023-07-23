import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    width: 100
    height: 400

    Button {
        id: btnZoomIn
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        height: parent.width
        icon.name: "value-increase-symbolic"
        icon.width: Math.round(btnZoomIn.width * 0.5)
        icon.height: Math.round(btnZoomIn.height * 0.5)
        icon.color: "lightblue"

        background: Rectangle {
            anchors.fill: parent
            color: btnZoomIn.down ? "red" : "#99000000"
            border.width: 2
            border.color: "lightblue"
            radius: 90
        }

        onClicked: {
            var newZoom = camera.digitalZoom+1.0

            if(newZoom >= 0 && newZoom < camera.maximumDigitalZoom){
                camera.setDigitalZoom(newZoom)
            }
        }
    }

    Text {
        anchors.centerIn: parent
        width: parent.width
        height: parent.width * 2
        text: camera.digitalZoom
        anchors.margins: 5
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        color: "white"
        font.bold: true
        style: Text.Raised
        styleColor: "black"
        font.pixelSize: 24
    }

    Button {
        id: btnZoomOut
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        height: parent.width
        icon.name: "value-decrease-symbolic"
        icon.width: Math.round(btnZoomOut.width * 0.5)
        icon.height: Math.round(btnZoomOut.height * 0.5)
        icon.color: "lightblue"

        background: Rectangle {
            anchors.fill: parent
            color: btnZoomOut.down ? "red" : "#99000000"
            border.width: 2
            border.color: "lightblue"
            radius: 90
        }

        onClicked: {
            var newZoom = camera.digitalZoom-1.0

            if(newZoom >= 0 && newZoom < camera.maximumDigitalZoom){
                camera.setDigitalZoom(newZoom)
            }
        }
    }
}
