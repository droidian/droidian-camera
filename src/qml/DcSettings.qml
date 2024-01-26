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
import QtQuick.Layouts

Drawer {
    id: drawer
    width: settingsLoader.active ? 300 : 100
    height: parent.height
    dim: false
    background: Rectangle {
        id: background
        anchors.fill: parent
        color: "black"
        opacity: 0.5
    }

    Behavior on width {
        NumberAnimation { duration: 250 }
    }

    ColumnLayout {
        id: btnContainer
        spacing: 25
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 20
        Button {
            id: camSwitchBtn

            height: width
            Layout.alignment: Qt.AlignHCenter
            icon.name: "camera-switch-symbolic"
            icon.height: 40
            icon.width: 40
            icon.color: "white"
                visible: true

                background: Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                }

                onClicked: {
                    dcCam.cameraId = dcCam.cameraId+1
                }
            }

            Button {
                id: cameraSelectButton
                Layout.topMargin: -35
                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                icon.name: "view-more-horizontal-symbolic"
                icon.height: 40
                icon.width: 40
                icon.color: "white"

                background: Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                }

                visible: true

                onClicked: {
                    // delayTime.visible = false
                    // backCamSelect.visible = true
                    // optionContainer.state = "opened"
                    // drawer.close()
                    // window.blurView = 1
                }
            }

            Button {
                id: flashButton

                height: width
                Layout.alignment: Qt.AlignHCenter
                icon.name: "thunderbolt-symbolic"
                icon.height: 40
                icon.width: 40
                icon.color: "white"
                //state: settings.flash

                visible: true

                states: [
                    State {
                        name: "flashOff"
                        PropertyChanges {
                            target: camera
                            flash.mode: Camera.FlashOff
                        }

                        PropertyChanges {
                            target: settings
                            flash: "flashOff"
                        }
                    },

                    State {
                        name: "flashOn"
                        PropertyChanges {
                            target: camera
                            flash.mode: Camera.FlashOn
                        }

                        PropertyChanges {
                            target: settings
                            flash: "flashOn"
                        }
                    },

                    State {
                        name: "flashAuto"
                        PropertyChanges {
                            target: camera
                            flash.mode: Camera.FlashAuto
                        }

                        PropertyChanges {
                            target: settings
                            flash: "flashAuto"
                        }
                    }
                    ]

                background: Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                }

                onClicked: {
                    if (camera.position !== Camera.FrontFace) {
                        if (flashButton.state == "flashOff") {
                            flashButton.state = "flashOn"
                        } else if (flashButton.state == "flashOn") {
                            flashButton.state = "flashAuto"
                        } else if (flashButton.state == "flashAuto") {
                            flashButton.state = "flashOff"
                        }
                    }
                }

                Text {
                    anchors.fill: parent
                    text: flashButton.state == "flashOn" ? "\u2714" :
                    flashButton.state == "flashOff" ? "\u2718" : "A"
                    color: "white"
                    z: parent.z + 1
                    font.pixelSize: 32
                    font.bold: true
                    style: Text.Outline;
                    styleColor: "black"
                    bottomPadding: 10
                }
            }

            Button {
                id: aspectRatioButton
                Layout.preferredWidth: 60
                Layout.preferredHeight: 40
                Layout.alignment: Qt.AlignHCenter
                palette.buttonText: settingsLoader.source == "DcResolutions.qml" ? "orange" : "white"

                font.pixelSize: 14
                font.bold: true
                text: dcCam.aspectRatio == 1 ? "16:9" : "4:3"

                visible: true //!window.videoCaptured

                background: Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.width: 2
                    border.color: settingsLoader.source == "DcResolutions.qml" ? "orange" : "white"
                    radius: 8
                }

                onClicked: {
                    dcCam.aspectRatio = !dcCam.aspectRatio
                    drawer.close()
                }
            }

            Button {
                id: resolutionButton
                Layout.topMargin: -25
                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                icon.name: "view-more-horizontal-symbolic"
                icon.height: 40
                icon.width: 40
                icon.color: settingsLoader.source == "DcResolutions.qml" ? "orange" : "white"

                background: Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                }

                onClicked: {
                    if(settingsLoader.active && settingsLoader.source == "DcResolutions.qml"){
                        settingsLoader.source = ""
                        settingsLoader.active = false
                    } else {
                        settingsLoader.source = "DcResolutions.qml"
                        settingsLoader.active = true
                    }
                }
            }

            Button {
                id: soundButton
                //property var soundOn: settings.soundOn

                height: width
                Layout.alignment: Qt.AlignHCenter
                icon.name: soundButton.soundOn == 1 ? "audio-volume-high-symbolic" : "audio-volume-muted-symbolic"
                icon.height: 40
                icon.width: 40
                icon.color: "white"

                background: Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                }

                onClicked: {
                    if (soundButton.soundOn == 1) {
                        soundButton.soundOn = 0
                        settings.setValue("soundOn", 0)
                    } else {
                        soundButton.soundOn = 1
                        settings.setValue("soundOn", 1)
                    }
                }
            }

            Button {
                id: sceneButton
                Layout.preferredWidth: 60
                Layout.preferredHeight: 40
                Layout.alignment: Qt.AlignHCenter
                palette.buttonText: settingsLoader.source == "DcSceneModes.qml" ? "orange" : "white"

                font.pixelSize: 14
                font.bold: true
                text: "SCENE"

                visible: true //!window.videoCaptured

                background: Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.width: 2
                    border.color: settingsLoader.source == "DcSceneModes.qml" ? "orange" : "white"
                    radius: 8
                }

                onClicked: {
                    if(settingsLoader.active && settingsLoader.source == "DcSceneModes.qml"){
                        settingsLoader.source = ""
                        settingsLoader.active = false
                    } else {
                        settingsLoader.source = "DcSceneModes.qml"
                        settingsLoader.active = true
                    }
                }
            }

        }
        onClosed: {
            blurItm.blureOn = 0
            settingsLoader.source = ""
            settingsLoader.active = false
        }

    Loader {
        id: settingsLoader
        active: false
        width: 200
        height: parent.height * 0.8
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        opacity: parent.width / 300
    }
}