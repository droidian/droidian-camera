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

        onVideoBitRateChanged: {
            if (vidBitRateTumbler.currentIndex != videoBitRate - 3){
                setVidBitRate.start()
            }
        }

        onCamIdChanged: {
            if (camera.videoModel.rowCount() > 0) {
                const video = camera.videoModel.get(vidQuality.currentIndex);
                camera.setVideoSize(video.resolution.width, video.resolution.height)
            }
        }

        Timer {
            id: setVidBitRate
            interval: 1000
            repeat: false
            running: false
            onTriggered: vidBitRateTumbler.currentIndex = camera.videoBitRate - 3
        }
    }

    Connections {
        target: camera
        onNewMediaSaved: MediaScanner.addMediaItem(filePath)
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

    Item {
        id: encoderSettings
        width: 200
        height: 300
        anchors.centerIn: parent
        opacity: 0.0
        visible: opacity > 0.0

        Behavior on opacity {
            NumberAnimation { duration: 400 }
        }

        Text {
            id: bitRateHeader
            visible: !camera.swEncode
            text: "Video Bit Rate"
            font.pixelSize: 28
            font.bold: true
            color: ThemeUtils.getAccentColor()
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: vidBitRateTumbler.top
            anchors.bottomMargin: 10
        }
        Tumbler {
            id: vidBitRateTumbler
            anchors.fill: parent
            visible: !camera.swEncode
            model: ListModel {}

            delegate: Item {
                width: parent.width
                height: 60

                Text {
                    text: model.value + " Mbps"
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

            onCurrentIndexChanged: camera.videoBitRate = vidBitRateTumbler.currentIndex + 3;
        }

        Text {
            id: crfHeader
            visible: camera.swEncode
            text: "Constant Rate Factor"
            font.pixelSize: 26
            font.bold: true
            color: ThemeUtils.getAccentColor()
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: vidBitRateTumbler.top
            anchors.bottomMargin: 10
        }
        Tumbler {
            id: encCrfTumbler
            visible: camera.swEncode
            anchors.fill: parent
            model: ListModel {}
            property bool initialized: false

            delegate: Item {
                width: parent.width
                height: 60

                Text {
                    text: model.value
                    font.pixelSize: 24
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
            anchors.top: vidBitRateTumbler.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 10
            uniformCellSizes: true
            RadioButton {
                checked: camera.swEncode
                font.pixelSize: 24
                Layout.alignment: Qt.AlignRight
                text: qsTr("SW Encoder")
                onClicked: {
                    camera.swEncode = true
                }
            }
            RadioButton {
                checked: !camera.swEncode
                font.pixelSize: 24
                Layout.alignment: Qt.AlignLeft
                text: qsTr("HW Encoder")
                onClicked: {
                    camera.swEncode = false
                }
            }
        }
    }

    Item {
        width: 200
        height: 300
        anchors.centerIn: parent
        visible: timeLapseFps.opacity > 0.0

        Text {
            id: timeLapseHeader
            text: "Timelapse FPS"
            font.pixelSize: 28
            font.bold: true
            color: ThemeUtils.getAccentColor()
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: timeLapseFps.top
            anchors.bottomMargin: 10
        }
        Tumbler {
            id: timeLapseFps
            anchors.fill: parent
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
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: timeLapseFps.bottom
            anchors.topMargin: 10
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