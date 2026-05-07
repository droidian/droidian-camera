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

GridLayout {
    id: centerGridControl
    columns: 3
    anchors.fill: parent
    rowSpacing: 2
    columnSpacing: 2

    DefaultButton {
        id: btnPicMode
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        maxPixelSize: parent.width * 0.12
        color: camera.camMode == HybrisCamera.PictureMode ? ThemeUtils.getAccentColor() : "darkgrey"
        code: "\ue412"

        onClicked: camera.camMode = HybrisCamera.PictureMode
    }

    DefaultButton {
        id: btnPicAspect
        visible: camera.camMode == HybrisCamera.PictureMode
        Layout.fillWidth: true
        Layout.fillHeight: true
        ffamily: ""
        Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
        color: "darkgrey"
        code: camera.picAspectWide ? "\u301016:9\u3011" : "\u30104:3\u3011"

        onClicked: camera.picAspectWide = !camera.picAspectWide
    }

    DefaultButton {
        id: btnVidResolution

        visible: camera.camMode == HybrisCamera.VideoMode && !camera.isRecording
        Layout.fillWidth: true
        Layout.fillHeight: true
        ffamily: ""
        Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
        color: "darkgrey"

        onClicked: {
            if (camera.isRecording)
                return

            if (camera.videoModel.rowCount() > 0) {
                if((camera.videoModel.currentIndex() + 1) === camera.videoModel.rowCount())
                    camera.videoModel.setCurrentIndex(0)
                else
                    camera.videoModel.setCurrentIndex(camera.videoModel.currentIndex() + 1)
                const video = camera.videoModel.get(camera.videoModel.currentIndex());
                code = "\u3010" + video.name + "\u3011";
                camera.setVideoSize(video.resolution.width, video.resolution.height)
            }
        }

        Component.onCompleted: {
            if (camera.videoModel.rowCount() > 0) {
                const video = camera.videoModel.get(camera.videoModel.currentIndex());
                code = "\u3010" + video.name + "\u3011";
            }
        }

        Connections {
            target: camera
            function onCamIdChanged() {
                if (camera.videoModel.rowCount() > 0) {
                    const video = camera.videoModel.get(camera.videoModel.currentIndex());
                    btnVidResolution.code = "\u3010" + video.name + "\u3011";
                }
            }
            function onCamModeChanged() {
                if (camera.videoModel.rowCount() > 0) {
                    const video = camera.videoModel.get(camera.videoModel.currentIndex());
                    btnVidResolution.code = "\u3010" + video.name + "\u3011";
                }
            }
        }
    }

    DefaultButton {
        id: btnSnapshot

        visible: camera.camMode == HybrisCamera.VideoMode && camera.isRecording
        Layout.fillWidth: true
        Layout.fillHeight: true
        ffamily: ""
        Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
        color: ThemeUtils.getAccentColor()
        code: "\ue3af"
        rotate: true
        onClicked: camera.takeSnapshot()
    }

    DefaultButton {
        id: btnVidMode
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        maxPixelSize: 48
        color: camera.camMode == HybrisCamera.VideoMode ? ThemeUtils.getAccentColor() : "darkgrey"
        code: "\ue04b"

        onClicked: camera.camMode = HybrisCamera.VideoMode
    }

    DefaultButton {
        id: btnShatter
        rotate: true
        Layout.fillWidth: true
        Layout.fillHeight: false
        Layout.minimumHeight: parent.height * 0.54
        Layout.row: 1
        Layout.column: 1
        Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
        color: camera.camMode == HybrisCamera.VideoMode ? "red" : "white"
        code: camera.camMode == HybrisCamera.PictureMode ? "\ue3af" : camera.isRecording ? "\uef71" : "\ue837"
        opacity: timeLapseFps.opacity == 0.0 && encoderSettings.opacity == 0.0 ? 1.0 : 0.0

        onClicked: {
            if(encoderSettings.opacity > 0.0 || timeLapseFps.opacity > 0.0)
                return
            if(camera.camMode == HybrisCamera.PictureMode)
                camera.takePicture()
            else
                camera.isRecording ? camera.stopRecording() : camera.startRecording()
        }

        onPressAndHold: {
            if(encoderSettings.opacity > 0.0 || timeLapseFps.opacity > 0.0)
                return
            if(camera.camMode == HybrisCamera.VideoMode && !camera.isRecording)
                timeLapseFps.opacity = timeLapseFps.opacity == 0.0 ? 1.0 : 0.0
        }
    }
}