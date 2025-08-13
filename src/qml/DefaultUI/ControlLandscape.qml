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

Item {
	id: root

	ColumnLayout {
        spacing: 10
        anchors.fill: parent
        uniformCellSizes: true

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
	        id: btnPicMode
	        Layout.fillWidth: true
	        Layout.fillHeight: true
	        Layout.margins: parent.width * 0.2
	        ffamily: ""
	        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
	        color: camera.camMode == HybrisCamera.PictureMode ? ThemeUtils.getAccentColor() : "darkgrey"
	        code: "\u{1F4F7}"

	        onClicked: camera.camMode = HybrisCamera.PictureMode
	    }

	    DefaultButton {
	        id: btnShatter
	        rotate: true
	        Layout.fillWidth: true
	        Layout.fillHeight: true
	        Layout.margins: parent.width * 0.08
	        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
	        color: camera.camMode == HybrisCamera.VideoMode ? "red" : "white"
	        code: camera.camMode == HybrisCamera.PictureMode ? "\ue3af" : camera.isRecording ? "\uef71" : "\ue837"
	        opacity: timeLapsFps.opacity == 0.0 && vidBitRateTumbler.opacity == 0.0 ? 1.0 : 0.0

	        onClicked: {
	            if(vidBitRateTumbler.opacity > 0.0 || timeLapsFps.opacity > 0.0)
	                return
	            if(camera.camMode == HybrisCamera.PictureMode)
	                camera.takePicture()
	            else
	                camera.isRecording ? camera.stopRecording() : camera.startRecording()
	        }

	        onPressAndHold: {
	            if(vidBitRateTumbler.opacity > 0.0 || timeLapsFps.opacity > 0.0)
	                return
	            if(camera.camMode == HybrisCamera.VideoMode && !camera.isRecording)
	                timeLapsFps.opacity = timeLapsFps.opacity == 0.0 ? 1.0 : 0.0
	        }
	    }

	    DefaultButton {
	        id: btnVidMode
	        Layout.fillWidth: true
	        Layout.fillHeight: true
	        Layout.margins: parent.width * 0.2
	        ffamily: ""
	        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
	        color: camera.camMode == HybrisCamera.VideoMode ? ThemeUtils.getAccentColor() : "darkgrey"
	        code: "\u{1F4F9}"

	        onClicked: camera.camMode = HybrisCamera.VideoMode
	    }

	    Item {
            id: vidBitRateText
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop

            Text {
                visible: camera.camMode === HybrisCamera.VideoMode
                anchors.fill: parent
                color: vidBitRateTumbler.opacity > 0.0 ? ThemeUtils.getAccentColor() : ThemeUtils.getTextColor()
                text: Math.round(vidBitRateTumbler.currentIndex + 3) + "Mbps"
                font.pixelSize: 14
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignTop

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (!camera.isRecording)
                            vidBitRateTumbler.opacity = vidBitRateTumbler.opacity > 0 ? 0.0 : 1.0
                    }
                }
            }
        }
    }
}
