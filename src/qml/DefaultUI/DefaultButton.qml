/* SPDX-License-Identifier: GPL-2.0-only
 *
 * Copyright (C) 2025 Droidian Project
 *
 * Authors:
 * Alexander Rutz <alex@familyrutz.com>
 */

 import QtQuick

Item {
	id: root

	property var code: ""
	property var color: "black"
	property var ffamily: mdiFont.name
	property bool rotate: false
	signal clicked()
	signal pressAndHold()

	Text {
		anchors.fill: parent
		text: root.code
		font.family: root.ffamily
		fontSizeMode: Text.Fit
		minimumPixelSize: 10
		font.pixelSize: 100
		horizontalAlignment: Text.AlignHCenter
		verticalAlignment: Text.AlignVCenter
		color: root.color
	}

	Rotation {
		id: rotation
		origin.x: root.width / 2
		origin.y: root.height / 2
		angle: 0
	}

	transform: [rotation]

	NumberAnimation {
		id: rotateAnim
		target: rotation
		property: "angle"
        duration: 300
    }

	MouseArea {
		anchors.fill: parent
		pressAndHoldInterval: 800
		onClicked: {
			parent.clicked()

			if(root.rotate){
				rotateAnim.from = rotation.angle
                rotateAnim.to = rotation.angle + 360
                rotateAnim.start()
			}
		}

		onPressAndHold: {
            parent.pressAndHold()
        }
	}
}