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

    property var blurView: drawer.position == 0.0 && tmDrawer.position == 0.0 ? 0 : 1

    Settings {
        id: settings
        property var soundOn: 1
    }

    Settings {
        id: settingsCommon
        fileName: fileManager.getConfigFile(); //"/etc/droidian-camera.conf" or "/usr/lib/droidian/device/droidian-camera.conf"
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
                back: "gst-pipeline: droidcamsrc mode=2 camera-device=0 ! video/x-raw ! videoconvert ! videoflip video-direction=auto ! qtvideosink",
                backRecord: "gst-pipeline: droidcamsrc camera_device=0 mode=2 ! tee name=t t. ! queue ! video/x-raw, width=1920, height=1080 ! videoconvert ! videoflip video-direction=auto ! qtvideosink t. ! queue ! video/x-raw, width=1920, height=1080 ! videoconvert ! videoflip video-direction=auto ! jpegenc ! mkv. autoaudiosrc ! queue ! audioconvert ! droidaenc ! mkv. matroskamux name=mkv ! filesink location=" + outputPath
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
        visible: drawer.position == 0.0

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

    Drawer {
        id: tmDrawer
        width: parent.width
        edge: Qt.BottomEdge
        dim: true
        background: Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 0.9
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
                        capturer.capture()

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
