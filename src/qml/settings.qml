import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
width: 400
height: 800
color: "#00ffffff"
border.width: 0
Label {
    id: titleM
    width: 116
    height: 29
    text: qsTr("Settings")
    anchors.left: parent.left
    anchors.top: parent.top
    font.pointSize: 14
    anchors.leftMargin: 46
    font.family: "Lato"
    anchors.topMargin: 8
    color:  (atmospheresHandler.variant == "dark") ? "white" : "black"
}

Rectangle {
    id: rectangleM
    height: 1
    color:     (atmospheresHandler.variant == "dark") ? "white" : "#66000000"
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.leftMargin: 8
    anchors.rightMargin: 8
    anchors.topMargin: 36
}

Label {
    id: titleM1
    width: 116
    height: 29
    color: (atmospheresHandler.variant == "dark") ? "white" : "black"
    text: qsTr("Photo")
    anchors.left: parent.left
    anchors.top: parent.top
    font.pointSize: 14
    anchors.topMargin: 43
    anchors.leftMargin: 8
    font.family: "Lato"
}

Image {
       id: image
       x: 8
       y: 8
       width: 32
       height: 35
       source: "icons/icon-m-dismiss.svg"
       fillMode: Image.PreserveAspectFit
   }

   Image {
       id: image1
       x: 360
       y: 5
       width: 32
       height: 35
       source: "icons/icon-m-accept.svg"
       fillMode: Image.PreserveAspectFit
   }



Label {
    id: titleM2
    width: 116
    height: 29
    color: (atmospheresHandler.variant == "dark") ? "white" : "black"
    text: qsTr("Video")
    anchors.left: parent.left
    anchors.top: parent.top
    font.pointSize: 14
    anchors.topMargin: 146
    anchors.leftMargin: 8
    font.family: "Lato"
}

ComboBox {
    id: comboBox
    x: 130
    y: 84
    width: 264
    height: 32
}

Label {
    id: titleM3
    width: 116
    height: 29
    color: (atmospheresHandler.variant == "dark") ? "white" : "black"
    text: qsTr("resolution")
    anchors.left: parent.left
    anchors.top: parent.top
    font.pointSize: 14
    anchors.topMargin: 84
    anchors.leftMargin: 8
    font.family: "Lato"
}

ComboBox {
    id: comboBox1
    x: 130
    y: 191
    width: 264
    height: 32
}

Label {
    id: titleM4
    width: 116
    height: 29
    color: (atmospheresHandler.variant == "dark") ? "white" : "black"
    text: qsTr("resolution")
    anchors.left: parent.left
    anchors.top: parent.top
    font.pointSize: 14
    anchors.topMargin: 191
    anchors.leftMargin: 8
    font.family: "Lato"
}

}
