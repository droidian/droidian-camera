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
	            onCamIdChanged: {
	                if (camera.videoModel.rowCount() > 0) {
	                    const video = camera.videoModel.get(camera.videoModel.currentIndex());
	                    btnVidResolution.code = "\u3010" + video.name + "\u3011";
	                }
	            }
	            onCamModeChanged: {
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
	        id: btnPicMode
	        Layout.fillWidth: true
	        Layout.fillHeight: true
	        Layout.margins: parent.width * 0.1
	        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
	        color: camera.camMode == HybrisCamera.PictureMode ? ThemeUtils.getAccentColor() : "darkgrey"
	        code: "\ue412"

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

	    DefaultButton {
	        id: btnVidMode
	        Layout.fillWidth: true
	        Layout.fillHeight: true
	        Layout.margins: parent.width * 0.1
	        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
	        color: camera.camMode == HybrisCamera.VideoMode ? ThemeUtils.getAccentColor() : "darkgrey"
	        code: "\ue04b"

	        onClicked: camera.camMode = HybrisCamera.VideoMode
	    }

        Rectangle {
            id: encBtn
            visible: camera.camMode === HybrisCamera.VideoMode && !camera.isRecording
            Layout.fillWidth: true
            height: 24
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            color: Qt.rgba(0, 0, 0, 0.7)
            border.color: ThemeUtils.getAccentColor()
            border.width: 1
            radius: 15
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
            visible: !encBtn.visible
        }
    }
}
