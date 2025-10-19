/* SPDX-License-Identifier: GPL-2.0-only
 *
 * Copyright (C) 2025 Droidian Project
 *
 * Authors:
 * Alexander Rutz <alex@familyrutz.com>
 */
 
import QtQuick
import QtQuick.Controls

Item {
    id: root
    visible: false
    property var source: ""

    onVisibleChanged: {
        imageRect.scaleFactor = 1.0
        imageRect.offsetX = 0
        imageRect.offsetY = 0
    }

    Rectangle {
        id: imageRect
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
        color: "black"
        property real scaleFactor: 1.0
        property real offsetX: 0
        property real offsetY: 0

        Image {
            id: zoomImage
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            fillMode: Image.PreserveAspectFit
            source: root.source
            smooth: true

            transform: [
                Scale {
                    id: scaleTransform
                    origin.x: zoomImage.width / 2
                    origin.y: zoomImage.height / 2
                    xScale: imageRect.scaleFactor
                    yScale: imageRect.scaleFactor
                },
                Translate {
                    id: translateTransform
                    x: imageRect.offsetX
                    y: imageRect.offsetY
                }
            ]
        }
        PinchArea {
            anchors.fill: parent
            pinch.target: null
            pinch.minimumScale: 1.0
            pinch.maximumScale: 10.0

            property real startScale: 1.0
            property real startOffsetX: 0
            property real startOffsetY: 0

            onPinchStarted: (pinch) => {
                startScale = imageRect.scaleFactor
                startOffsetX = imageRect.offsetX
                startOffsetY = imageRect.offsetY
            }

            onPinchUpdated: (pinch) => {
                let newScale = startScale * pinch.scale
                imageRect.scaleFactor = Math.max(1.0, Math.min(10.0, newScale))

                imageRect.offsetX = startOffsetX + pinch.center.x - pinch.startCenter.x
                imageRect.offsetY = startOffsetY + pinch.center.y - pinch.startCenter.y
            }

            onPinchFinished: (pinch) => {
                imageRect.scaleFactor = Math.max(1.0, Math.min(10.0, imageRect.scaleFactor))
            }

            TapHandler {
                acceptedDevices: PointerDevice.TouchScreen
                onTapped: {
                    root.visible = false
                    root.source = ""
                    imageRect.scaleFactor = 1.0
                    imageRect.offsetX = 0
                    imageRect.offsetY = 0
                }
            }
        }
    }
}