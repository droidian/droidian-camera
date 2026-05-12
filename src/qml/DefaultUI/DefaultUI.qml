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
import QtQuick.Effects
import HybrisCamera
import ThemeUtils
import MediaScanner

Item {
    id: root
    anchors.fill: parent

    property bool landscape: width > height

    Rectangle {
        id: ctrlBottom
        visible: !root.landscape
        width: parent.width
        height: parent.height * 0.14
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        color: "#B4000000"
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.5) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 1.0) }
        }
    }

    Rectangle {
        id: ctrlLeft
        visible: root.landscape
        width: parent.height * 0.14
        height: parent.height
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        color: "#B4000000"

        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.5) }
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 1.0) }
        }
    }

    Rectangle {
        id: ctrlRight
        visible: root.landscape
        width: parent.height * 0.14
        height: parent.height
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        color: "#B4000000"
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 1.0) }
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.5) }
        }
    }

    Loader {
        id: ctrLoader
        width: root.landscape ? root.height * 0.22 : parent.width * 0.6
        height: root.landscape ? root.height * 0.75 : parent.height * 0.11
    }

    DefaultButton {
        id: qrReader
        visible: !camera.isRecording
        x: !landscape ? parent.width * 0.7 : parent.width * 0.5
        anchors.bottom: root.bottom
        anchors.margins: width / 2
        rotate: true
        width: root.landscape ? root.height * 0.06 : parent.width * 0.06
        height: width
        color: camera.camMode === HybrisCamera.QrMode ? ThemeUtils.getAccentColor() : "white"
        code: "\ue00a"
        onClicked: camera.camMode = HybrisCamera.QrMode
    }

    DefaultButton {
        id: camSwitch
        visible: !camera.isRecording
        anchors.right: root.right
        anchors.bottom: root.bottom
        anchors.margins: width
        rotate: true
        width: root.landscape ? root.height * 0.06 : parent.width * 0.06
        height: width
        color: "white"
        code: "\uefeb"
        onClicked: camera.camId = (camera.camId === 0 ? 1 : 0)
    }

    Rectangle {
        anchors.left: root.left
        anchors.bottom: root.bottom
        anchors.margins: root.landscape ? root.height * 0.05 : parent.width * 0.05
        width: root.landscape ? root.height * 0.08 : parent.width * 0.08
        height: width
        radius: width / 2
        color: ThemeUtils.getAccentColor()

            Image {
                id: lastMedia
                source: {
                    const groups = MediaScanner.groups
                    if (groups.length > 0) {
                        const lastGroup = groups[0]
                        const items = lastGroup.items
                        if (items.length > 0) {
                            return items[0].thumbnailPath
                        }
                    }
                    return ""
                }
                anchors.centerIn: parent
                height: parent.height - 4
                width: height
                visible: false
            }

            MultiEffect {
                source: lastMedia
                anchors.fill: lastMedia
                maskEnabled: true
                maskSource: mask
            }

            Item {
                id: mask
                anchors.fill: lastMedia
                layer.enabled: true
                opacity: 0

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "black"
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: openMediaWall()
            }
    }

    ColumnLayout {
        id: sideControl_B
        spacing: 2
        width: root.landscape ? root.height * 0.2 : root.width * 0.2
        height: root.landscape ? parent.width * 0.12 : parent.height * 0.12
        uniformCellSizes: true

        DefaultButton {
            id: flashBtn
            visible: camera.camMode === HybrisCamera.PictureMode
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: sideControl_B.height * 0.05
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            color: "white"
            code: "\ue3e7"
            onClicked: {
                if (camera.flash === HybrisCamera.FLASH_AUTO) {
                    code = "\ue3e6"
                    camera.flash = HybrisCamera.FLASH_OFF
                } else if (camera.flash === HybrisCamera.FLASH_OFF) {
                    code = "\ue3e7"
                    camera.flash = HybrisCamera.FLASH_ON
                } else if (camera.flash === HybrisCamera.FLASH_ON) {
                    code = "\ue3e5"
                    camera.flash = HybrisCamera.FLASH_AUTO
                }
            }
        }

        DefaultButton {
            id: torchBtn
            visible: camera.camMode === HybrisCamera.VideoMode || camera.camMode === HybrisCamera.QrMode
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: sideControl_B.height * 0.05
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            color: "white"
            code: "\uf00a"
            onClicked: {
                if (camera.flash !== HybrisCamera.FLASH_TORCH) {
                    code = "\uf00b"
                    camera.flash = HybrisCamera.FLASH_TORCH
                } else {
                    code = "\uf00a"
                    camera.flash = HybrisCamera.FLASH_OFF
                }
            }
        }

        Item { Layout.fillWidth: true; Layout.fillHeight: true }
        Item { Layout.fillWidth: true; Layout.fillHeight: true }
    }

    ColumnLayout {
        id: sideControl_A
        spacing: 2
        width: root.landscape ? root.height * 0.2 : root.width * 0.2
        height: root.landscape ? parent.width * 0.12 : parent.height * 0.12
        uniformCellSizes: true

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.landscape
        }

        Rectangle {
            id: vidBitRateText
            visible: !root.landscape && camera.camMode === HybrisCamera.VideoMode && !camera.isRecording
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            color: Qt.rgba(0, 0, 0, 0.7)
            border.color: ThemeUtils.getAccentColor()
            border.width: 1
            radius: 20
            Text {
                anchors.fill: parent
                anchors.leftMargin: 5
                anchors.rightMargin: 5
                color: encoderSettings.opacity > 0.0 ? ThemeUtils.getAccentColor() : ThemeUtils.getTextColor()
                text: camera.swEncode ? "SW Encoder" : "HW Encoder"
                fontSizeMode: Text.Fit
                minimumPixelSize: 10
                font.pixelSize: 20
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (!camera.isRecording)
                            encoderSettings.opacity = encoderSettings.opacity > 0 ? 0.0 : 1.0
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: sideControl_A.height * 0.05
            Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom

            DefaultButton {
                id: btnMic
                visible: camera.camMode === HybrisCamera.VideoMode && !camera.isRecording
                anchors.fill: parent
                color: "white"
                code: camera.withMic ? "\ue029" : "\ue02b"
                onClicked: camera.withMic = !camera.withMic
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    states: [
        State {
            name: "portrait"
            when: !root.landscape
            PropertyChanges { target: ctrLoader; source: "ControlPortrait.qml" }
            AnchorChanges {
                target: ctrLoader
                anchors.bottom: root.bottom
                anchors.horizontalCenter: root.horizontalCenter
                anchors.right: undefined
                anchors.verticalCenter: undefined
            }
            AnchorChanges {
                target: sideControl_A
                anchors.bottom: camSwitch.top
                anchors.right: root.right
                anchors.left: undefined
            }
            AnchorChanges {
                target: sideControl_B
                anchors.left: root.left
                anchors.bottom: root.bottom
            }
        },
        State {
            name: "landscape"
            when: root.landscape
            PropertyChanges { target: ctrLoader; source: "ControlLandscape.qml" }
            AnchorChanges {
                target: ctrLoader
                anchors.right: root.right
                anchors.verticalCenter: root.verticalCenter
                anchors.bottom: undefined
                anchors.horizontalCenter: undefined
            }
            AnchorChanges {
                target: sideControl_A
                anchors.bottom: sideControl_B.top
                anchors.left: root.left
                anchors.right: undefined
            }
            AnchorChanges {
                target: sideControl_B
                anchors.left: root.left
                anchors.bottom: root.bottom
            }
        }
    ]
}
