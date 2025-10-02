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
        ffamily: ""
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        color: camera.camMode == HybrisCamera.PictureMode ? ThemeUtils.getAccentColor() : "darkgrey"
        code: "\u{1F4F7}"

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
        property int currentIndex: 0

        visible: camera.camMode == HybrisCamera.VideoMode
        Layout.fillWidth: true
        Layout.fillHeight: true
        ffamily: ""
        Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
        color: "darkgrey"

        onClicked: {
            if (camera.isRecording)
                return

            if (camera.videoModel.rowCount() > 0) {
                currentIndex = (currentIndex + 1) % camera.videoModel.rowCount();
                const video = camera.videoModel.get(currentIndex);
                code = "\u3010" + video.name + "\u3011";
                camera.setVideoSize(video.resolution.width, video.resolution.height)
            }
        }

        Component.onCompleted: {
            if (camera.videoModel.rowCount() > 0) {
                currentIndex = (currentIndex) % camera.videoModel.rowCount();
                const video = camera.videoModel.get(currentIndex);
                code = "\u3010" + video.name + "\u3011";
                camera.setVideoSize(video.resolution.width, video.resolution.height)
            }
        }
    }

    DefaultButton {
        id: btnVidMode
        Layout.fillWidth: true
        Layout.fillHeight: true
        ffamily: ""
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        color: camera.camMode == HybrisCamera.VideoMode ? ThemeUtils.getAccentColor() : "darkgrey"
        code: "\u{1F4F9}"

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