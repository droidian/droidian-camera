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

ListView {
	id: scene
	anchors.fill: parent
	anchors.leftMargin: 40
	model: dcCam.sceneModes
	visible: true
	focus: true
	spacing: 8
	currentIndex: dcCam.sceneModeIndex
	delegate: Button {
		width: 140
		height: 40
		palette.buttonText: scene.currentIndex == index ? "orange" : "white"

		font.pixelSize: 14
		font.bold: true
		text: modelData

		background: Rectangle {
			anchors.fill: parent
			color: "transparent"
			border.width: 1
			border.color: scene.currentIndex == index ? "orange" : "white"
			radius: 8
		}

		onClicked: {
			scene.currentIndex = index
			dcCam.sceneModeIndex = index
			drawer.close()
		}
	}
	highlight: Rectangle { color: "transparent"; radius: 8; border.width: 3; border.color: "orange" }
}