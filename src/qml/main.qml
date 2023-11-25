// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2023 Droidian Project
//
// Authors:
// Bardia Moshiri <fakeshell@bardia.tech>
// Erik Inkinen <erik.inkinen@gmail.com>
// Alexander Rutz <alex@familyrutz.com>

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.12
import QtGraphicalEffects 1.0
import QtMultimedia 5.15
import QtQuick.Layouts 1.15
import Qt.labs.settings 1.0
import Qt.labs.platform 1.1

ApplicationWindow {
    id:window
    visible: true
    width: 400
    height: 600
    title: "Static Top, Swipeable Bottom"
    property bool videoCaptured: false

    property var countDown: 0
    property var useFlash: 0
    property var frontCameras: 0
    property var backCameras: 0

    Item {
        id: cslate

        state: "PhotoCapture"

        states: [
            State {
                name: "PhotoCapture"
            },
            State {
                name: "VideoCapture"
            }
        ]
    }

    Camera {
        id: camera
        captureMode: Camera.CaptureStillImage

        property variant firstFourThreeResolution
        property variant firstSixteenNineResolution
        property var aspWide: 0

        focus {
            focusMode: Camera.FocusMacro
            focusPointMode: Camera.FocusPointCustom
        }

        imageProcessing {
            denoisingLevel: 1.0
            sharpeningLevel: 1.0
            whiteBalanceMode: Camera.WhiteBalanceAuto
        }

        flash.mode: Camera.FlashOff

        imageCapture {
            onImageCaptured: {

                if (mediaView.index < 0) {
                    mediaView.folder = StandardPaths.writableLocation(StandardPaths.PicturesLocation) + "/droidian-camera"
                }
            }
        }

        onDeviceIdChanged: {
            settings.setValue("cameraId", deviceId);
        }

    }

    Rectangle {
        // Static top covering the entire screen
        id: cameraFrame
       
        width: parent.width
        height: parent.height 

        VideoOutput {
            id: viewfinder
            anchors.fill: parent
            source: camera
            autoOrientation: true
        }
    }

    SwipeView {
        // Swipeable bottom part on top of the screen
        id: swipeView
        height: 120
        width: parent.width
        anchors.bottom: parent.bottom

        Rectangle {
            color: Qt.rgba(173/255, 216/255, 230/255, 0.6) // lightblue with 60% transparency
            width: swipeView.width
            height: swipeView.height

            Text {
                anchors.centerIn: parent
                text: "Page 1"
                font.pixelSize: 24
            }
        }

        Rectangle {
            color: Qt.rgba(144/255, 238/255, 144/255, 0.6) // lightgreen with 60% transparency
            width: swipeView.width
            height: swipeView.height

            Text {
                anchors.centerIn: parent
                text: "Page 2"
                font.pixelSize: 24
            }
        }

        Rectangle {
            color: Qt.rgba(240/255, 128/255, 128/255, 0.6) // lightcoral with 60% transparency
            width: swipeView.width
            height: swipeView.height

            Text {
                anchors.centerIn: parent
                text: "Page 3"
                font.pixelSize: 24
            }
        }
    }
}