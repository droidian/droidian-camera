// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2024 Droidian Project
//
// Authors:
// Bardia Moshiri <fakeshell@bardia.tech>
// Erik Inkinen <erik.inkinen@gmail.com>
// Alexander Rutz <alex@familyrutz.com>
// Joaquin Philco <joaquinphilco@gmail.com>

import QtQuick
import Qt5Compat.GraphicalEffects

Item{
    anchors.fill: parent
    property var blurSrc;
    property var blureOn: 0;

    FastBlur {
        id: vBlur
        anchors.fill: parent
        opacity: blureOn ? 1 : 0
        source: blurSrc
        radius: 128
        visible: opacity != 0
        transparentBorder: false
        Behavior on opacity {
            NumberAnimation {
                duration: 300
            }
        }
    }

    Glow {
        anchors.fill: vBlur
        opacity: blureOn ? 1 : 0
        radius: 4
        samples: 1
        color: "black"
        source: vBlur
        visible: opacity != 0
        Behavior on opacity {
            NumberAnimation {
                duration: 300
            }
        }
    }
}