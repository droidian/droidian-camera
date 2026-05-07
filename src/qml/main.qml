/* SPDX-License-Identifier: GPL-2.0-only
 *
 * Copyright (C) 2025 Droidian Project
 *
 * Authors:
 * Alexander Rutz <alex@familyrutz.com>
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import HybrisCamera
import ThemeUtils
import MediaScanner

import "DefaultUI"

Item {
    id: root

    property bool landscape: width > height

    function openMediaWall() {
        mediaWall.visible = true
    }

    FontLoader {
        id: mdiFont
        source: "file:///usr/share/fonts/truetype/material-design-icons-iconfont/MaterialIcons-Regular.ttf"
    }

    HybrisCamera {
        id: camera
        blur: encoderSettings.opacity > 0.0 || timeLapseFps.opacity > 0.0
        anchors.fill: parent
        property real lastZoom: 1.0

        onVideoBitRateChanged: vidBitRateTumbler.currentIndex = camera.videoBitRate - 3

        onCamIdChanged: {
            if (camera.videoModel.rowCount() > 0) {
                const video = camera.videoModel.get(videoModel.currentIndex);
                camera.setVideoSize(video.resolution.width, video.resolution.height)
            }
        }
    }

    Connections {
        target: camera

        function onNewMediaSaved(filePath) {
            MediaScanner.addMediaItem(filePath)
        }
    }

    PinchArea {
        anchors.fill: parent

        property real zoomSensitivity: 2.5

        onPinchUpdated: {
            let targetZoom = camera.lastZoom * Math.pow(pinch.scale, zoomSensitivity);

            if (targetZoom > camera.maxZoom) {
                camera.zoom = camera.maxZoom;
            } else if (targetZoom < 1.0) {
                camera.zoom = 1.0;
            } else {
                camera.zoom = targetZoom;
            }
        }

        onPinchFinished: {
            camera.lastZoom = camera.zoom;
        }
    }

    MouseArea {
        id: closeMa
        anchors.fill: parent
        visible: encoderSettings.opacity > 0.0 || timeLapseFps.opacity > 0.0

        onClicked: {
            encoderSettings.opacity = 0.0
            timeLapseFps.opacity = 0.0
            timeLapseFps.currentIndex = 0
        }
    }

    ColumnLayout {
        id: encoderSettings
        width: parent.width * 0.5
        height: parent.landscape ? parent.height * 0.7 : parent.width * 0.7
        anchors.centerIn: parent
        opacity: 0.0
        visible: opacity > 0.0

        Behavior on opacity {
            NumberAnimation { duration: 400 }
        }

        Text {
            id: bitRateHeader
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            visible: !camera.swEncode
            text: "Video Bit Rate"
            font.pixelSize: 24
            font.bold: true
            color: ThemeUtils.getAccentColor()
        }
        Tumbler {
            id: vidBitRateTumbler
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !camera.swEncode
            model: ListModel {}
            property bool initialized: false

            delegate: Item {
                width: parent.width
                height: parent.height / 5

                Text {
                    text: model.value + " Mbps"
                    fontSizeMode: Text.Fit
                    minimumPixelSize: 10
                    font.pixelSize: 24
                    anchors.centerIn: parent
                    color: index === vidBitRateTumbler.currentIndex ? ThemeUtils.getAccentColor() : "grey"
                }
            }

            Component.onCompleted: {
                for (var i = 3; i <= 60; i++) {
                    model.append({ value: i });
                }
            }

            onVisibleChanged: {
                if(visible && !initialized){
                    vidBitRateTumbler.currentIndex = camera.videoBitRate - 3
                    initialized = true
                }
            }

            onCurrentIndexChanged: {
                if(initialized)
                    camera.videoBitRate = vidBitRateTumbler.currentIndex + 3;
            }
        }

        Text {
            id: crfHeader
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            visible: camera.swEncode
            text: "Constant Rate Factor"
            font.pixelSize: 24
            font.bold: true
            color: ThemeUtils.getAccentColor()
        }
        Tumbler {
            id: encCrfTumbler
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: camera.swEncode
            model: ListModel {}
            property bool initialized: false

            delegate: Item {
                width: parent.width
                height: parent.height / 5

                Text {
                    text: model.value
                    fontSizeMode: Text.Fit
                    minimumPixelSize: 10
                    font.pixelSize: 20
                    anchors.centerIn: parent
                    color: index === encCrfTumbler.currentIndex ? ThemeUtils.getAccentColor() : "grey"
                }
            }

            Component.onCompleted: {
                for (var i = 0; i <= 51; i++) {
                    model.append({ value: i });
                }
            }

            onVisibleChanged: {
                if(visible && !initialized){
                    encCrfTumbler.currentIndex = camera.encCrf
                    initialized = true
                }
            }

            onCurrentIndexChanged: {
                if(initialized)
                    camera.encCrf = encCrfTumbler.currentIndex
            }
        }

        RowLayout {
            width: root.width * 0.8
            height: bitRateHeader.height
            uniformCellSizes: true
            Item {
                Layout.fillWidth: true
                RadioButton {
                    anchors.right: swTxt.left
                    checked: camera.swEncode
                    onClicked: {
                        camera.swEncode = true
                    }
                }
                Text {
                    id: swTxt
                    anchors.right: parent.right
                    text: "SW Encoder"
                    color: camera.swEncode ? ThemeUtils.getAccentColor() : "grey"
                    font.pixelSize: 24
                    MouseArea{
                        anchors.fill: parent
                            onClicked: {
                            camera.swEncode = true
                        }
                    }
                }
            }
            Item {
                Layout.fillWidth: true
                RadioButton {
                    id: hwRadioBtn
                    checked: !camera.swEncode
                    anchors.left: parent.left
                    onClicked: {
                        camera.swEncode = false
                    }
                }
                Text {
                    anchors.left: hwRadioBtn.right
                    text: "HW Encoder"
                    color: !camera.swEncode ? ThemeUtils.getAccentColor() : "grey"
                    font.pixelSize: 24
                    MouseArea{
                        anchors.fill: parent
                            onClicked: {
                            camera.swEncode = false
                        }
                    }
                }
            }
        }
    }

    ColumnLayout {
        id: timeLapseSettings
        width: parent.width * 0.5
        height: parent.landscape ? parent.height * 0.8 : parent.width * 0.8
        anchors.centerIn: parent
        visible: timeLapseFps.opacity > 0.0

        Text {
            id: timeLapseHeader
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: "Timelapse FPS"
            font.pixelSize: 28
            font.bold: true
            color: ThemeUtils.getAccentColor()
            anchors.bottomMargin: 10
        }
        Tumbler {
            id: timeLapseFps
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: ListModel {}
            opacity: 0.0
            visible: true

            delegate: Item {
                width: parent.width
                height: 60

                Text {
                    text: model.value > 0 ? model.value + " FPS" : "OFF"
                    font.pixelSize: 24
                    anchors.centerIn: parent
                    color: index === timeLapseFps.currentIndex ? ThemeUtils.getAccentColor() : "grey"
                }
            }

            Component.onCompleted: {
                for (var i = 0; i <= 300; i++) {
                    model.append({ value: i / 10 });
                }
            }

            onCurrentIndexChanged: camera.timeLapseFps = timeLapseFps.currentIndex / 10;

            Behavior on opacity {
                NumberAnimation { duration: 400 }
            }
        }

        RowLayout {
            spacing: 10
            uniformCellSizes: true
            visible: timeLapseFps.currentIndex
            width: parent.width
            height: 40
            DefaultButton {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignHCenter | Qt.AlignLeft
                color: "green"
                code: "\ue5ca"

                onClicked: {
                    camera.startRecording()
                    timeLapseFps.opacity = 0.0
                }
            }
            DefaultButton {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignHCenter | Qt.AlignRight
                color: "red"
                code: "\ue5cd"

                onClicked: timeLapseFps.currentIndex = 0
            }
        }
    }

    DefaultUI {
        anchors.fill: parent
    }

    MediaWall {
        id: mediaWall
        anchors.fill: parent
        visible: false
    }
}