/* SPDX-License-Identifier: GPL-2.0-only
 *
 * Copyright (C) 2026 Droidian Project
 *
 * Authors:
 * Alexander Rutz <alex@familyrutz.com>
 */

 import QtQuick
 import QtQuick.Layouts
 import QtQuick.Controls
 import HybrisCamera
 import ThemeUtils

 Rectangle {
 	id: scanRect
 	property var text: ""
 	visible: camera.camMode === HybrisCamera.QrMode || qrText.text.length > 0
 	height: parent.height
 	width: 2
 	y: 0
 	x: 0
 	color: camera.blur ? "transparent" : Qt.rgba(0, 0, 0, 0.8)
 	border.color: ThemeUtils.getAccentColor()
 	border.width: !qrText.text ? 1 : 0

 	Behavior on width {
 		NumberAnimation { duration: 500 }
 	}

 	SequentialAnimation {
 		running: camera.camMode === HybrisCamera.QrMode && !qrText.text
 		loops: Animation.Infinite

 		NumberAnimation {
 			target: scanRect
 			property: "x"
 			from: 2
 			to: camera.width - 2
 			duration: 1000
 		}

 		NumberAnimation {
 			target: scanRect
 			property: "x"
 			from: camera.width - 2
 			to: 2
 			duration: 1000
 		}
 	}

 	Text {
 		width: parent.width
 		height: 100
 		anchors.horizontalCenter: parent.horizontalCenter
 		anchors.bottom: qrText.top
 		fontSizeMode: Text.Fit
 		minimumPixelSize: 10
 		font.pixelSize: 100
 		horizontalAlignment: Text.AlignHCenter
 		verticalAlignment: Text.AlignVCenter
 		color: ThemeUtils.getAccentColor()
 		text: "\ue00a"
 	}

 	Text {
 		id: qrText
 		width: parent.width
 		height: 50
 		anchors.centerIn: parent
 		text: scanRect.text
 		font.family: ""
 		fontSizeMode: Text.Fit
 		minimumPixelSize: 10
 		font.pixelSize: 24
 		horizontalAlignment: Text.AlignHCenter
 		verticalAlignment: Text.AlignVCenter
 		color: ThemeUtils.getAccentColor()

 		onTextChanged: {
 			btnUrl.visible =
 			qrText.text.includes("://") ||
 			qrText.text.startsWith("mailto:") ||
 			qrText.text.startsWith("tel:")
 		}
 	}

 	RowLayout {
 		spacing: 10
 		anchors.horizontalCenter: parent.horizontalCenter
 		anchors.top: qrText.bottom
 		anchors.margins: 30
 		width: parent.width * 0.8
 		height: 50
 		uniformCellSizes: true

 		DefaultButton {
 			id: btnUrl
 			visible: false
 			Layout.fillWidth: true
 			Layout.fillHeight: true
 			Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
 			color: "darkgrey"
 			code: "\ue89e"

 			onClicked: {
 				if(qrText.text.length > 0)
 					Qt.openUrlExternally(qrText.text)
 				scanRect.text = ""
 				scanRect.width = 2
 			}
 		}

 		DefaultButton {
 			id: btnClipBoard
 			visible: qrText.text.length > 0
 			Layout.fillWidth: true
 			Layout.fillHeight: true
 			Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
 			color: "darkgrey"
 			code: "\ue14d"

 			onClicked: {
 				camera.copyToClipboard(qrText.text)
 				scanRect.text = ""
 				scanRect.width = 2
 			}
 		}

 		DefaultButton {
 			id: btnRestart
 			visible: qrText.text.length > 0
 			Layout.fillWidth: true
 			Layout.fillHeight: true
 			Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
 			color: "darkgrey"
 			code: "\ue5d5"

 			onClicked: {
 				scanRect.width = 2
 				scanRect.text = ""
 				camera.camMode = HybrisCamera.QrMode
 			}
 		}

 		DefaultButton {
 			id: btnCancel
 			visible: qrText.text.length > 0
 			Layout.fillWidth: true
 			Layout.fillHeight: true
 			Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
 			color: "darkgrey"
 			code: "\ue5c9"

 			onClicked: {
 				scanRect.width = 2
 				scanRect.text = ""
 			}
 		}
 	}
 }