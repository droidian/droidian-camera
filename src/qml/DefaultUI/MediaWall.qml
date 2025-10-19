/* SPDX-License-Identifier: GPL-2.0-only
 *
 * Copyright (C) 2025 Droidian Project
 *
 * Authors:
 * Alexander Rutz <alex@familyrutz.com>
 */
 
import QtQuick
import QtQuick.Controls
import QtMultimedia
import QtQml.Models
import MediaScanner
import ThemeUtils
import HybrisCamera

Item {
    id: root

    anchors.fill: parent

    onVisibleChanged: {
        if(!visible){
            imgView.visible = false
            imgView.source = ""
            videoPlayer.stop()
            videoRect.visible = false
            videoPlayer.source = ""
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
    }

    Component.onCompleted: {
        MediaScanner.scan()
    }

    Connections {
        target: MediaScanner

        function onScanningChanged() {
            if(!MediaScanner.scanning)
                mediaList.contentY = textHeader.height
        }
    }

    ListView {
        id: mediaList
        anchors.top: textHeader.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        height: parent.height - textHeader.height
        model: MediaScanner.groups
        flickableDirection: Flickable.VerticalFlick
        clip: true

        onContentYChanged: {
            if(MediaScanner.scanning)
                return
            if(contentY < textHeader.height)
                contentY = textHeader.height
            var index = indexAt(contentX, contentY)
            var item = model[index]
            if(item && item.label != textHeader.text)
                textHeader.text = item.label
        }

        delegate: Column {
            width: parent.width
            spacing: 10

            Rectangle {
                width: parent.width
                height: 40
                color: "darkgrey"

                Text {
                    anchors.centerIn: parent
                    text: modelData.label
                    font.pixelSize: 18
                    font.bold: true
                    color: "white"
                }
            }

            GridView {
                id: mediaGrid
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter
                interactive: false

                property int spacing: 10
                property int minItemWidth: root.width * 0.25
                property int columnCount: {
                    let full = minItemWidth + spacing;
                    let count = Math.floor((width + spacing) / full);
                    return Math.max(1, count);
                }

                property real itemWidth: width / columnCount
                property real itemHeight: itemWidth * 0.75 + 20

                cellWidth: itemWidth
                cellHeight: itemHeight

                model: modelData.items

                property int rowCount: Math.ceil(modelData.items.length / columnCount)
                height: rowCount * cellHeight

                property real contentWidth: columnCount * itemWidth + spacing * (columnCount - 1)
                x: (width - contentWidth) / 2

                delegate: Item {
                    width: mediaGrid.cellWidth
                    height: mediaGrid.cellHeight

                    Rectangle {
                        width: mediaGrid.itemWidth
                        height: mediaGrid.itemHeight - 20

                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: mediaGrid.spacing / 2

                        radius: 8
                        color: "darkgrey"

                        Image {
                            anchors.fill: parent
                            source: modelData.thumbnailPath
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            anchors.margins: 4

                            Text {
                                visible: modelData.type === "video"
                                anchors.fill: parent
                                anchors.margins: parent.height * 0.4
                                color: "white"
                                font.family: mdiFont.name
                                style: Text.Outline
                                styleColor: ThemeUtils.getAccentColor()
                                fontSizeMode: Text.Fit
                                minimumPixelSize: 10
                                font.pixelSize: 100
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                text: "\ue1c4"
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if(modelData.type === "image"){
                                    imgView.visible = true
                                    imgView.source = modelData.path
                                } else if(modelData.type === "video"){
                                    videoRect.visible = true
                                    videoPlayer.source = modelData.path
                                    videoPlayer.play()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: videoRect
        anchors.fill: parent
        color: "black"
        visible: false

        Video {
            id: videoPlayer
            anchors.fill: parent
            source: ""
            autoPlay: false
            loops: MediaPlayer.Infinite
            muted: true
            visible: parent.visible

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    videoPlayer.stop()
                    videoRect.visible = false
                    videoPlayer.source = ""
                }
            }
        }
    }

    ImageViewer {
        id: imgView
        anchors.fill: parent
        visible: false
    }

    Rectangle {
        id: textHeader

        property var text: ""

        width: parent.width
        height: 40
        anchors.horizontalCenter: parent.horizontalCenter
        color: "black"

        Text {
            anchors.centerIn: parent
            text: parent.text
            font.pixelSize: 18
            font.bold: true
            color: "white"
        }
    }

    Rectangle {
        id: closeViewer
        visible: imgView.visible || videoRect.visible
        width: parent.width > parent.height ? parent.width * 0.05 : parent.height * 0.05
        height: width
        radius: 90
        color: Qt.rgba(0, 0, 0, 0.8)

        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.margins: parent.width > parent.height ? parent.width * 0.01 : parent.height * 0.01

        DefaultButton {
            anchors.fill: parent
            anchors.margins: 5
            color: ThemeUtils.getAccentColor()
            code: "\ue9b0"
            onClicked: {
                imgView.visible = false
                imgView.source = ""
                videoPlayer.stop()
                videoRect.visible = false
                videoPlayer.source = ""
            }
        }
    }

    Rectangle {
        id: backToCam
        width: parent.width > parent.height ? parent.width * 0.05 : parent.height * 0.05
        height: width
        radius: 90
        color: Qt.rgba(0, 0, 0, 0.8)

        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: parent.width > parent.height ? parent.width * 0.01 : parent.height * 0.01

        DefaultButton {
            anchors.fill: parent
            anchors.margins: 5
            color: ThemeUtils.getAccentColor()
            code: camera.camMode === HybrisCamera.PictureMode ? "\ue412" : "\ue04b"
            onClicked: root.visible = false
        }
    }

    Rectangle {
        id: loadingOverlay
        anchors.fill: parent
        color: "#B4000000"
        visible: MediaScanner.scanning
        z: 100

        Text {
            anchors.centerIn: parent
            text: "Scanning media..."
            font.pixelSize: 20
            color: "white"
        }
    }
}