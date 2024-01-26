// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2024 Droidian Project
//
// Authors:
// Bardia Moshiri <fakeshell@bardia.tech>
// Erik Inkinen <erik.inkinen@gmail.com>
// Alexander Rutz <alex@familyrutz.com>
// Joaquin Philco <joaquinphilco@gmail.com>

import QtQuick
import QtQuick.Controls
import QtQuick.Window
import QtQuick.Layouts
import QtMultimedia
import DroidianCamera

ApplicationWindow {
    id: mainWindow
    width: 400
    height: 800
    visible: true
    title: qsTr("Droidian-Camera")
    color: "black"

    DroidianCamera{
        id: dcCam
        cameraId: 0
        videoSink: viewfinder.videoSink

        onImageCaptured: sound.play()
    }

    SoundEffect {
        id: sound
        source: "../sounds/camera-shutter.wav"
    }

    Item {
        id: camZoom
        onScaleChanged: {
            dcCam.setZoom(scale)
        }
    }

    VideoOutput {
        id: viewfinder
        anchors.fill: parent
        visible: true

        PinchArea {
            id: pinchArea
            width: parent.width
            height: parent.height * 0.85
            pinch.target: camZoom
            pinch.maximumScale: dcCam.maxZoom
            pinch.minimumScale: 1.0
        }
    }

    DcBlur {
        id: blurItm
        blurSrc: viewfinder
        blureOn: 0
    }

    DcSettings{
        id: dcSettings
    }

    Drawer {
        id: tmDrawer
        width: parent.width
        edge: Qt.BottomEdge
        dim: true

        background: Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 0.9
        }

        onClosed: {
            blurItm.blureOn = 0
        }

        onOpened: {
            blurItm.blureOn = 1
        }
    }

    RowLayout {
        width: parent.width
        height: 140
        anchors.bottom: parent.bottom
        spacing: 6
        
        Button {
            Layout.alignment: Qt.AlignHCenter
            icon.name: "open-menu-symbolic"
            icon.color: "white"
            icon.width: 32
            icon.height: 32
            background: Rectangle {
                color: "black"
                opacity: 0.4
            }

            onClicked: {
                blurItm.blureOn = !blurItm.blureOn
            }
        }

        Button {
            id: shutterBtn
            Layout.alignment: Qt.AlignHCenter
            icon.color: "white"
            icon.source: "../icons/shutter.svg"
            icon.width: 80
            icon.height: 80
            background: Rectangle {
                color: "black"
                radius: 90
            }

            onClicked: {
                dcCam.takePicture()
                shutterBtn.rotation += 180
            }

            Behavior on rotation {
                RotationAnimation {
                    duration: 250
                    direction: RotationAnimation.Counterclockwise
                }
            }
        }

        Button {
            Layout.alignment: Qt.AlignHCenter
            icon.name: "open-menu-symbolic"
            icon.color: "white"
            icon.width: 32
            icon.height: 32
            background: Rectangle {
                color: "black"
                opacity: 0.4
            }

            onClicked: {
                blurItm.blureOn = !blurItm.blureOn
                dcSettings.open()
            }
        }
    }
}