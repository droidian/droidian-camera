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
	id: resolutions
	anchors.fill: parent
	anchors.leftMargin: 40
	model: dcCam.availableResolutions
	visible: true
	focus: true
	spacing: 8
	currentIndex: dcCam.availableResolutionIndex
	delegate: Button {
		width: 140
		height: 40
		palette.buttonText: resolutions.currentIndex == index ? "orange" : "white"

		font.pixelSize: 14
		font.bold: true
		text: modelData.width+" x "+modelData.height

		background: Rectangle {
			anchors.fill: parent
			color: "transparent"
			border.width: 1
			border.color: resolutions.currentIndex == index ? "orange" : "white"
			radius: 8
		}

		onClicked: {
			resolutions.currentIndex = index
			dcCam.availableResolutionIndex = index
			drawer.close()
		}
	}
	highlight: Rectangle { color: "transparent"; radius: 8; border.width: 3; border.color: "orange" }
}