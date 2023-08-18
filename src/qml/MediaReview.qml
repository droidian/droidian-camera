import QtQuick 2.15
import QtMultimedia 5.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import Qt.labs.folderlistmodel 2.15
import Qt.labs.platform 1.1

Rectangle {
    id: viewRect
    property int index: -1
    property var lastImg: index == -1 ? "" :imgModel.get(viewRect.index, "fileUrl")
    property var folder: StandardPaths.writableLocation(StandardPaths.PicturesLocation) + "/droidian-camera"
    signal closed

    color: "black"
    visible: false

    FolderListModel {
        id: imgModel
        folder: viewRect.folder
        showDirs: false
        nameFilters: ["*.jpg"]

        onStatusChanged: {
            if (imgModel.status == FolderListModel.Ready) {
                viewRect.index = imgModel.count - 1
            }
        }
    }

    Image {
        id: view
        anchors.fill: parent
        autoTransform: true
        transformOrigin: Item.Center
        fillMode: Image.PreserveAspectFit
        smooth: true
        source: viewRect.index == -1 ? "" : imgModel.get(viewRect.index, "fileUrl")
    }

    RowLayout {
        width: parent.width
        height: 70
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter

        Button {
            id: btnClose
            implicitWidth: 70
            implicitHeight: 70
            icon.name: "camera-video-symbolic"
            icon.width: Math.round(btnClose.width * 0.8)
            icon.height: Math.round(btnClose.height * 0.8)
            icon.color: "white"
            Layout.alignment : Qt.AlignHCenter

            background: Rectangle {
                anchors.fill: parent
                color: "#99000000"
            }

            onClicked: {
                viewRect.visible = false
                viewRect.index = imgModel.count - 1
                viewRect.closed();
            }
        }
    }

    Button {
        id: btnPrev
        implicitWidth: 60
        implicitHeight: 60
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        icon.name: "go-previous-symbolic"
        icon.width: Math.round(btnPrev.width * 0.5)
        icon.height: Math.round(btnPrev.height * 0.5)
        icon.color: "white"
        Layout.alignment : Qt.AlignHCenter

        visible: viewRect.index > 0

        background: Rectangle {
            anchors.fill: parent
            color: "#AA000000"
        }

        onClicked: {
            if ((viewRect.index - 1) >= 0 ) {
                viewRect.index = viewRect.index - 1
            }
        }
    }

    Button {
        id: btnNext
        implicitWidth: 60
        implicitHeight: 60
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        icon.name: "go-next-symbolic"
        icon.width: Math.round(btnNext.width * 0.5)
        icon.height: Math.round(btnNext.height * 0.5)
        icon.color: "white"
        visible: viewRect.index < (imgModel.count - 1)
        Layout.alignment : Qt.AlignHCenter

        background: Rectangle {
            anchors.fill: parent
            color: "#AA000000"
        }

        onClicked: {
            if ((viewRect.index + 1) <= (imgModel.count - 1)) {
                viewRect.index = viewRect.index + 1
            }
        }
    }

    Rectangle {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: 200
        height: 50
        color: "#AA000000"
        visible: viewRect.index >= 0
        Text {
            text: (viewRect.index + 1) + " / " + imgModel.count

            anchors.fill: parent
            anchors.margins: 5
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            color: "white"
            font.bold: true
            style: Text.Raised
            styleColor: "black"
            font.pixelSize: 16
        }
    }
}
