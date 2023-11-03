// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2023 Droidian Project
//
// Authors:
// Bardia Moshiri <fakeshell@bardia.tech>
// Erik Inkinen <erik.inkinen@gmail.com>
// Alexander Rutz <alex@familyrutz.com>

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.12
import QtGraphicalEffects 1.0
import QtMultimedia 5.15
import QtQuick.Layouts 1.15
import Qt.labs.settings 1.0
import Qt.labs.platform 1.1
import org.droidian.Camera.CaptureFilter 1.0
import org.droidian.CameraDeviceRangeWrapper 1.0

ApplicationWindow {
    id: window
    width: 400
    height: 800
    visible: true
    title: "Camera"
    property alias cam: camGst
    property bool videoCaptured: false
    property int backCameras: 0
    property var blurView: drawer.position == 0.0 && optionContainer.state == "closed" ? 0 : 1
    property int currentBackCamera: 0
    property bool flash: false

    Settings {
        id: settings
        property int cameraId: 0
        property var soundOn: 1
    }

    Settings {
        id: settingsCommon
        fileName: fileManager.getConfigFile(); //"/etc/droidian-camera.conf" or "/usr/lib/droidian/device/droidian-camera.conf"

        property var blacklist: 0
    }

    background: Rectangle {
        color: "black"
    }

    Item {
        id: cslate

        state: "PhotoCapture"

        states: [
            State {
                name: "PhotoCapture"
            },
            State {
                name: "VideoCapture"
            }
        ]
    }

    SoundEffect {
        id: sound
        source: "sounds/camera-shutter.wav"
    }

    Component.onCompleted: {
        console.log("First Camera Device: " + cameraDeviceRangeWrapper.min);
        console.log("Last Camera Device: " + cameraDeviceRangeWrapper.max);
    }

    ListModel {
        id: allCamerasModel
        Component.onCompleted: {
            var blacklist

            if (settingsCommon.blacklist !== undefined && settingsCommon.blacklist !== "") {
                blacklist = settingsCommon.blacklist.split(',');
            }

            for (var i = 0; i <= cameraDeviceRangeWrapper.max; i++) {
                var isBlacklisted = false;

                for (var p in blacklist) {
                    if (blacklist[p] == i) {
                        console.log("Camera with the id:", blacklist[p], "is blacklisted, not adding to camera list!");
                        isBlacklisted = true;
                        break;
                    }
                }

                if (isBlacklisted) {
                    continue;
                }

                var cameraPosition = (i === 1) ? "FrontFace" : "BackFace";

                if (cameraPosition === "BackFace") {
                    append({"cameraId": i, "index": i, "position": cameraPosition});
                    console.log("Camera with the id:", i, "added as position", cameraPosition);
                    window.backCameras += 1;
                }
            }
        }
    }

    VideoOutput {
        id: viewfinder
        anchors.fill: parent
        autoOrientation: true

        filters: [
        CaptureFilter {
                id: capturer
            }
        ]
    }

    FastBlur {
        id: vBlur
        anchors.fill: parent
        opacity: blurView ? 1 : 0
        source: viewfinder
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
        opacity: blurView ? 1 : 0
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

    MediaPlayer {
        id: camGst
        autoPlay: true
        source: isFront || !("back" in backends[backendId])
            ? backends[backendId].front
            : backends[backendId].back
        videoOutput: viewfinder
        property var backendId: 0
        property string outputPath: StandardPaths.writableLocation(StandardPaths.MoviesLocation).toString().replace("file://","") +
                                            "/droidian-camera/video" + Qt.formatDateTime(new Date(), "yyyyMMdd_hhmmsszzz") + ".mkv"

        Component.onCompleted: {
            fileManager.createDirectory("/Videos/droidian-camera");
        }

        property var backends: [
            {
                front: "gst-pipeline: droidcamsrc mode=2 camera-device=1 ! video/x-raw ! videoconvert ! videoflip video-direction=auto ! qtvideosink",
                frontRecord: "gst-pipeline: droidcamsrc camera_device=1 mode=2 ! tee name=t t. ! queue ! video/x-raw, width=1920, height=1080 ! videoconvert ! videoflip video-direction=auto ! qtvideosink t. ! queue ! video/x-raw, width=1920, height=1080 ! videoconvert ! videoflip video-direction=auto ! jpegenc ! mkv. autoaudiosrc ! queue ! audioconvert ! droidaenc ! mkv. matroskamux name=mkv ! filesink location=" + outputPath,
                back: "gst-pipeline: droidcamsrc mode=2 camera-device=" + currentBackCamera + " ! video/x-raw ! videoconvert ! videoflip video-direction=auto ! qtvideosink",
                backRecord: "gst-pipeline: droidcamsrc camera_device=" + currentBackCamera + " mode=2 ! tee name=t t. ! queue ! video/x-raw, width=1920, height=1080 ! videoconvert ! videoflip video-direction=auto ! qtvideosink t. ! queue ! video/x-raw, width=1920, height=1080 ! videoconvert ! videoflip video-direction=auto ! jpegenc ! mkv. autoaudiosrc ! queue ! audioconvert ! droidaenc ! mkv. matroskamux name=mkv ! filesink location=" + outputPath
            }
        ]

        property bool isFront: false
        property bool recording: false

        function updateSource() {
            var newSource = recording ? 
                (isFront ? backends[backendId].frontRecord : backends[backendId].backRecord) : 
                (isFront ? backends[backendId].front : backends[backendId].back);

            if (source !== newSource) {
                stop();
                source = newSource;
                play();
            }

            window.videoCaptured = recording;
        }

        onError: {
            if (backendId + 1 in backends) {
                backendId++;
            }
        }
    }

    function handleVideoRecording() {
        camGst.recording = !camGst.recording;
        camGst.updateSource();
    }

    Drawer {
        id: drawer
        width: 100
        height: parent.height
        dim: false
        background: Rectangle {
            id: background
            anchors.fill: parent
            color: "transparent"
        }

        ColumnLayout {
            id: btnContainer
            spacing: 25
            anchors.centerIn: parent

            Button {
                id: camSwitchBtn

                height: width
                Layout.alignment: Qt.AlignHCenter
                icon.name: "camera-switch-symbolic"
                icon.height: 40
                icon.width: 40
                icon.color: "white"
                visible: !window.videoCaptured

                background: Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                }

                onClicked: {
                    drawer.close()
                    camGst.isFront = !camGst.isFront;
                    camGst.updateSource();
                }
            }

            Button {
                id: cameraSelectButton
                Layout.topMargin: -35
                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                icon.name: "view-more-horizontal-symbolic"
                icon.height: 40
                icon.width: 40
                icon.color: "white"

                background: Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                }

                visible: window.backCameras > 1 && window.videoCaptured == false

                onClicked: {
                    backCamSelect.visible = true
                    drawer.close()
                    optionContainer.state = "opened"
                }
            }

            Button {
                id: flashButton

                height: width
                Layout.alignment: Qt.AlignHCenter
                icon.name: "thunderbolt-symbolic"
                icon.height: 40
                icon.width: 40
                icon.color: "white"

                visible: !window.videoCaptured

                background: Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                }

                onClicked: {
                    if (!camGst.isFront) {
                        window.flash = !window.flash;
                    }
                }

                Text {
                    anchors.fill: parent
                    text: window.flash ? "\u2714" : "\u2718"
                    color: "white"
                    z: parent.z + 1
                    font.pixelSize: 32
                    font.bold: true
                    style: Text.Outline
                    styleColor: "black"
                    bottomPadding: 10
                }
            }

            Button {
                id: soundButton
                property var soundOn: settings.soundOn

                height: width
                Layout.alignment: Qt.AlignHCenter
                icon.name: soundButton.soundOn == 1 ? "audio-volume-high-symbolic" : "audio-volume-muted-symbolic"
                icon.height: 40
                icon.width: 40
                icon.color: "white"

                background: Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                }

                onClicked: {
                    if (soundButton.soundOn == 1) {
                        soundButton.soundOn = 0
                        settings.setValue("soundOn", 0)
                    } else {
                        soundButton.soundOn = 1
                        settings.setValue("soundOn", 1)
                    }
                }
            }
        }
    }

    Button {
        id: menuBtn
        width: 40
        height: width
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        icon.name: "open-menu-symbolic"
        icon.color: "white"
        icon.width: 32
        icon.height: 32
        visible: drawer.position == 0.0 && optionContainer.state == "closed"

        background: Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 0.4
        }

        onClicked: {
            if (!mediaView.visible) {
                drawer.open()
            }
        }
    }

    Rectangle {
        id: optionContainer
        width: parent.width
        height: parent.height * .5
        anchors.verticalCenter: parent.verticalCenter
        state: "closed"

        color: "transparent"

        states: [
            State {
                name: "opened"
                PropertyChanges {
                    target: optionContainer
                    x: window.width / 2 - optionContainer.width / 2
                }
            },

            State {
                name: "closed"
                PropertyChanges {
                    target: optionContainer
                    x: window.width
                }
            }
        ]

        ColumnLayout {
            anchors.fill: parent

            ColumnLayout {
                id: backCamSelect
                Layout.alignment: Qt.AlignHCenter
                Layout.fillHeight: true

                Repeater {
                    model: allCamerasModel
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: parent.width * 0.9
                    Button {
                        property string pos: model.position === "BackFace" ? "Back" : "Front"
                        Layout.alignment: Qt.AlignLeft
                        visible: parent.visible
                        icon.name: "camera-video-symbolic"
                        icon.color: "white"
                        icon.width: 48
                        icon.height: 48
                        palette.buttonText: "white"

                        font.pixelSize: 32
                        font.bold: true
                        text: " " + model.index + " " + pos

                        background: Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                        }

                        onClicked: {
                            window.currentBackCamera = model.index
                            optionContainer.state = "closed"
                        }
                    }
                }
            }
        }

        Behavior on x {
            PropertyAnimation {
                duration: 300
            }
        }
    }

    RowLayout {
        width: parent.width
        height: 100
        anchors.bottom: parent.bottom

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

            Button {
                id: modeBtn
                anchors.centerIn: parent
                implicitWidth: 80
                implicitHeight: 80
                icon.name: cslate.state == "PhotoCapture" ? "media-record-symbolic" : ""
                icon.source: cslate.state == "VideoCapture" ? "icons/shutter.svg" : ""
                icon.color: cslate.state == "PhotoCapture" ? "red" : "white"
                icon.width: cslate.state == "PhotoCapture" ? modeBtn.width * 0.4 : modeBtn.width
                icon.height: cslate.state == "PhotoCapture" ? modeBtn.width * 0.4 : modeBtn.width

                visible: !mediaView.visible && window.videoCaptured == false

                background: Rectangle {
                    width: cslate.state == "PhotoCapture" ? modeBtn.width * 0.75 : modeBtn.width 
                    height: cslate.state == "PhotoCapture" ? modeBtn.width * 0.75 : modeBtn.width
                    color: cslate.state == "PhotoCapture" ? "white" : "transparent"
                    radius: 90
                    anchors.centerIn: parent
                }

                onClicked: {
                    if (cslate.state == "PhotoCapture") {
                        cslate.state = "VideoCapture"
                    } else {
                        cslate.state = "PhotoCapture"
                    }
                }
            }
        }

        Timer {
            id: postCaptureTimer
            interval: 1000
            onTriggered: {
                flashlightController.turnFlashlightOff();
            }

            running: false
            repeat: false
        }

        Timer {
            id: preCaptureTimer
            interval: 2000
            onTriggered: {
                capturer.capture();
                postCaptureTimer.start();
            }

            running: false
            repeat: false
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

            Button {
                id: shutterBtn
                anchors.centerIn: parent
                implicitHeight: 100
                implicitWidth: 100
                icon.name: cslate.state == "VideoCapture" && !window.videoCaptured ? "media-record-symbolic" :
                            cslate.state == "VideoCapture" && window.videoCaptured ? "media-playback-stop-symbolic" : "shutter"
                icon.source: "icons/shutter.svg"
                icon.color: cslate.state == "VideoCapture" && !window.videoCaptured ? "red" :
                             cslate.state == "VideoCapture" && window.videoCaptured ? "black" : "white"
                icon.width: cslate.state == "VideoCapture" ? shutterBtn.width * .4 : shutterBtn.width
                icon.height: cslate.state == "VideoCapture" ? shutterBtn.height * .4 : shutterBtn.height

                palette.buttonText: "red"

                font.pixelSize: 64
                font.bold: true

                visible: !mediaView.visible

                background: Rectangle {
                    anchors.centerIn: parent
                    width: cslate.state == "VideoCapture" ? shutterBtn.width * .8 : shutterBtn.width
                    height: cslate.state == "VideoCapture" ? shutterBtn.height * .8 : shutterBtn.height
                    color: cslate.state == "PhotoCapture" ? "transparent" : "white"
                    radius: cslate.state == "PhotoCapture" ? 0 : 90
                }

                onClicked: {
                    if (cslate.state == "VideoCapture") {
                        handleVideoRecording()
                    } else {
                        if (!camGst.isFront && window.flash) {
                            flashlightController.turnFlashlightOn();
                            preCaptureTimer.start();
                        } else {
                            capturer.capture()
                        }

                        if (soundButton.soundOn) {
                            sound.play()
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

            Rectangle {
                id: reviewBtn
                anchors.centerIn: parent
                width: modeBtn.width * 0.75
                height: modeBtn.width * 0.75
                color: "black"

                visible: !window.videoCaptured && mediaView.index > -1

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Item {
                        width: reviewBtn.width
                        height: reviewBtn.height

                        Rectangle {
                            anchors.centerIn: parent
                            width: reviewBtn.adapt ? reviewBtn.width : Math.min(reviewBtn.width, reviewBtn.height)
                            height: reviewBtn.adapt ? reviewBtn.height : width
                            radius: 90
                        }
                    }
                }

                Image {
                    anchors.centerIn: parent
                    autoTransform: true
                    transformOrigin: Item.Center
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    source: (cslate.state !== "VideoCapture") ? mediaView.lastImg : ""
                    scale: Math.min(parent.width / width, parent.height / height)
                }
            }

            Rectangle {
                anchors.fill: reviewBtn
                color: "transparent"
                border.width: 2
                border.color: "white"
                radius: 90

                visible: !window.videoCaptured && mediaView.index > -1

                MouseArea {
                    anchors.fill: parent
                    onClicked: mediaView.visible = true
                }
            }
        }
    }

    MediaReview {
        id : mediaView
        anchors.fill : parent
        onClosed: camGst.play()
    }
}
