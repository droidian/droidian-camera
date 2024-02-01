// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2023 Droidian Project
//
// Authors:
// Bardia Moshiri <fakeshell@bardia.tech>
// Erik Inkinen <erik.inkinen@gmail.com>
// Alexander Rutz <alex@familyrutz.com>
// Joaquin Philco <joaquinphilco@gmail.com>

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
    property var countDown: 0
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

    Timer {
        id: swappingDelay
        interval: 400
        repeat: false

        onTriggered: {
            videoBtn.rotation += 180
            shutterBtn.rotation += 180
            cslate.state = (cslate.state == "VideoCapture") ? "PhotoCapture" : "VideoCapture"
            window.blurView = 0
        }
    }

    PinchArea {
        id: pinchArea
        width: parent.width
        height: parent.height * 0.85
        pinch.minimumScale: 0
        enabled: !mediaView.visible && !camGst.recording

        MouseArea {
            id: dragArea
            hoverEnabled: true
            anchors.fill: parent
            enabled: !mediaView.visible && !camGst.recording
            property real startX: 0
            property real startY: 0

            onPressed: {
                startX = mouse.x
                startY = mouse.y
            }

            onReleased: {
                var deltaX = mouse.x - startX
                var deltaY = mouse.y - startY

                if (Math.abs(deltaX) > Math.abs(deltaY)) {
                    if (deltaX > 0 && cslate.state != "PhotoCapture") {
                        window.blurView = 1
                        swappingDelay.start()
                    } else if (deltaX < 0 && cslate.state != "VideoCapture") {
                        window.blurView = 1
                        videoBtn.rotation += 180
                        shutterBtn.rotation += 180
                        swappingDelay.start()
                    }
                }
            }
        }
    }

    function handleVideoRecording() {
        camGst.recording = !camGst.recording;
        camGst.updateSource();
    }

    function imageCaptureLogic() {
        if (!camGst.isFront && window.flash) {
            flashlightController.turnFlashlightOn();
            flashTimer.start();
        } else {
            capturer.capture()
        }

        if (soundButton.soundOn && !window.flash) {
            sound.play()
        }
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
                    delayTime.visible = false
                    backCamSelect.visible = true
                    drawer.close()
                    optionContainer.state = "opened"
                    window.blurView = 1
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

        onClosed: {
            window.blurView = optionContainer.state == "opened" ? 1 : 0
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

            Tumbler {
                id: delayTime

                Layout.alignment: Qt.AlignHCenter
                Layout.fillHeight: true
                Layout.preferredWidth: parent.width * 0.9
                model: 60

                delegate: Text {
                    text: modelData == 0 ? "Off" : modelData
                    color: "white"
                    font.bold: true
                    font.pixelSize: 42
                    horizontalAlignment: Text.AlignHCenter
                    style: Text.Outline;
                    styleColor: "black"
                    opacity: 0.4 + Math.max(0, 1 - Math.abs(Tumbler.displacement)) * 0.6
                }
            }

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
                            window.blurView = 0
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
        interval: 1000
        onTriggered: {
            countDown -= 1
            if (countDown < 1) {
                imageCaptureLogic();
                preCaptureTimer.stop();
                postCaptureTimer.start();
            }
        }

        running: false
        repeat: true
    }

    Timer {
        id: flashTimer
        interval: 2000
        onTriggered: {
            capturer.capture();
            sound.play()
            postCaptureTimer.start();
        }
        running: false
        repeat: false
    }

    Rectangle {
        id: bottomFrame
        anchors.bottom: parent.bottom
        height: 125
        width: parent.width
        color: Qt.rgba(0, 0, 0, 0.6)
        enabled: false
    }

    Rectangle {
        id: menuBtnFrame
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        height: 60
        width: 60
        color: "transparent"
        anchors.rightMargin: 50
        anchors.bottomMargin: 35
        visible: !camGst.recording

        Button {
            id: menuBtn
            anchors.fill: parent
            icon.name: "open-menu-symbolic"
            icon.color: "white"
            icon.width: 32
            icon.height: 32
            enabled: !camGst.recording
            visible: drawer.position == 0.0 && optionContainer.state == "closed"

            background: Rectangle {
                color: "black"
                opacity: 0.4
            }

            onClicked: {
                if (!mediaView.visible) {
                    window.blurView = 1
                    drawer.open()
                }
            }
        }
    }

    Rectangle {
        id: reviewBtnFrame
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        height: 60
        radius: 90
        width: 60
        anchors.leftMargin: 50
        anchors.bottomMargin: 35
        enabled: !camGst.recording
        visible: !camGst.recording

        Rectangle {
            id: reviewBtn
            width: parent.width
            height: parent.height
            radius: 90
            color: "black"
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
                source: (cslate.state == "PhotoCapture")? mediaView.lastImg : ""
                scale: Math.min(parent.width / width, parent.height / height)
            }
        }

        Rectangle {
            anchors.fill: reviewBtn
            color: "transparent"
            border.width: 2
            border.color: "white"
            radius: 90

            MouseArea {
                anchors.fill: parent
                onClicked: mediaView.visible = true
            }
        }
    }

    Rectangle {
        id: videoBtnFrame
        height: 90
        width: 90
        radius: 70
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 15
        visible: cslate.state == "VideoCapture"
        Button {
            id: videoBtn
            anchors.fill: videoBtnFrame
            anchors.centerIn: parent
            enabled: cslate.state == "VideoCapture"

            Rectangle {
                anchors.centerIn: parent
                width: videoBtnFrame.width - 40
                height: videoBtnFrame.height - 40
                color: "red"
                radius: videoBtnFrame.radius
                visible: window.videoCaptured ? false : true
            }

            Rectangle {
                anchors.centerIn: parent
                visible: window.videoCaptured ? true : false
                width: videoBtnFrame.width - 50
                height: videoBtnFrame.height - 50
                color: "black"
            }

            text: preCaptureTimer.running ? countDown : ""

            palette.buttonText: "white"

            font.pixelSize: 64
            font.bold: true

            background: Rectangle {
                anchors.centerIn: parent
                width: videoBtnFrame.width - 20
                height: videoBtnFrame.height - 20
                color: "white"
                radius: videoBtnFrame.radius - 20
            }

            onClicked: {
                handleVideoRecording()
            }

            Behavior on rotation {
                RotationAnimation {
                    duration: 250
                    direction: RotationAnimation.Counterclockwise
                }
            }
        }
    }

    Rectangle {
        id: shutterBtnFrame
        height: 90
        width: 90
        radius: 70
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 15

        visible: cslate.state == "PhotoCapture"

        Button {
            id: shutterBtn
            anchors.fill: parent.fill
            anchors.centerIn: parent
            enabled: cslate.state == "PhotoCapture"
            icon.name: preCaptureTimer.running ? "" :
                            optionContainer.state == "opened" && delayTime.currentIndex < 1 ||
                            optionContainer.state == "opened" && backCamSelect.visible ? "window-close-symbolic" :
                            cslate.state == "VideoCapture" ? "media-playback-stop-symbolic" : "shutter"

            icon.source: preCaptureTimer.running ? "" :
                                optionContainer.state == "opened" && delayTime.currentIndex > 0 ? "icons/timer.svg" : "icons/shutter.svg"

            icon.color: "white"
            icon.width: shutterBtnFrame.width
            icon.height: shutterBtnFrame.height

            text: preCaptureTimer.running ? countDown : ""

            palette.buttonText: "red"

            font.pixelSize: 64
            font.bold: true
            visible: true

            background: Rectangle {
                anchors.centerIn: parent
                width: shutterBtnFrame.width
                height: shutterBtnFrame.height
                color: "black"
                radius: shutterBtnFrame.radius
            }

            onClicked: {
                pinchArea.enabled = true
                window.blurView = 0
                shutterBtn.rotation += optionContainer.state == "opened" ? 0 : 180

                if (optionContainer.state == "opened" && delayTime.currentIndex > 0 && !backCamSelect.visible) {
                    optionContainer.state = "closed"
                    countDown = delayTime.currentIndex
                    preCaptureTimer.start()
                } else if (optionContainer.state == "opened" && delayTime.currentIndex < 1 ||
                            optionContainer.state == "opened" && backCamSelect.visible) {
                    optionContainer.state = "closed"
                } else {
                    imageCaptureLogic()
                }
            }

            onPressAndHold: {
                optionContainer.state = "opened"
                pinchArea.enabled = false
                window.blurView = 1
                shutterBtn.rotation = 0
                delayTime.visible = true
                backCamSelect.visible = false
            }

            Behavior on rotation {
                RotationAnimation {
                    duration: (shutterBtn.rotation >= 180 && optionContainer.state == "opened") ? 0 : 250
                    direction: RotationAnimation.Counterclockwise
                }
            }
        }
    }

    MediaReview {
        id : mediaView
        anchors.fill : parent
        onClosed: camGst.play()
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: 400
        height: 270
        color: "transparent"

        RowLayout {
            anchors.centerIn: parent
            visible: !mediaView.visible && !camGst.recording
            enabled: !mediaView.visible && !camGst.recording
            Rectangle {
                width: 80
                height: 30
                radius: 5
                color: "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "Camera"
                    font.bold: true
                    color: cslate.state == "PhotoCapture" ? "orange" : "lightgray"
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (cslate.state != "PhotoCapture") {
                            optionContainer.state = "closed"  
                            window.blurView = 1
                            swappingDelay.start()
                        }
                    }
                }
            }

            Rectangle {
                width: 80
                height: 30
                radius: 5
                color: "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "Video"
                    font.bold: true
                    color: cslate.state == "VideoCapture" ? "orange" : "lightgray"
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (cslate.state != "VideoCapture") {
                            optionContainer.state = "closed"  
                            window.blurView = 1
                            videoBtn.rotation += 180
                            shutterBtn.rotation += 180
                            swappingDelay.start()
                        }
                    }
                }
            }
        }
    }
}
