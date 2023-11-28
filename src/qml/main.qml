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

ApplicationWindow {
    id: window
    width: 400
    height: 800
    visible: true
    title: "Camera"
    property alias cam: camGst
    property bool videoCaptured: false

    property var countDown: 0
    property var blurView: drawer.position == 0.0 && optionContainer.state == "closed" && tmDrawer.position == 0.0 ? 0 : 1
    property var useFlash: 0
    property var frontCameras: 0
    property var backCameras: 0
    property bool camEnable : true
    property bool videoEnable : false
    property int videoState:  1 //1 --> nonRecording 0--> recording

    Settings {
        id: settings
        property int cameraId: 0
        property int aspWide: 0
        property var flash: "flashAuto"
        property var cameras: [{"cameraId": 0, "resolution": 0},
                                {"cameraId": 1, "resolution": 0},
                                {"cameraId": 2, "resolution": 0},
                                {"cameraId": 3, "resolution": 0},
                                {"cameraId": 4, "resolution": 0},
                                {"cameraId": 5, "resolution": 0},
                                {"cameraId": 6, "resolution": 0},
                                {"cameraId": 7, "resolution": 0},
                                {"cameraId": 8, "resolution": 0},
                                {"cameraId": 9, "resolution": 0}]

        property var soundOn: 1
        property var hideTimerInfo: 1
        
    }

    Settings {
        id: settingsCommon
        fileName: fileManager.getConfigFile(); //"/etc/droidian-camera.conf" or "/usr/lib/droidian/device/droidian-camera.conf"

        property var blacklist: 0
    }
    
    ListModel {
        id: allCamerasModel
        Component.onCompleted: {
            var blacklist

            if (settingsCommon.blacklist != "") {
                blacklist = settingsCommon.blacklist.split(',')
            }

            for (var i = 0; i < QtMultimedia.availableCameras.length; i++) {
                var cameraInfo = QtMultimedia.availableCameras[i];
                var isBlacklisted = false;

                for (var p in blacklist) {
                    if (blacklist[p] == cameraInfo.deviceId) {
                        console.log("Camera with the id:", blacklist[p], "is blacklisted, not adding to camera list!");
                        isBlacklisted = true;
                        break;
                    }
                }

                if (isBlacklisted) {
                    continue;
                }

                if (cameraInfo.position === Camera.BackFace) {
                    append({"cameraId": cameraInfo.deviceId, "index": i, "position": cameraInfo.position});
                    window.backCameras += 1;
                } else if (cameraInfo.position === Camera.FrontFace) {
                    insert(0, {"cameraId": cameraInfo.deviceId, "index": i, "position": cameraInfo.position});
                    window.frontCameras += 1;
                }
            }
        }
    }

    background: Rectangle {
        color: "black"
    }

    Item { // cslate is in charge of that annoying swapping button! found you !
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

    VideoOutput {
        id: viewfinder
        anchors.fill: parent
        source: camera
        autoOrientation: true

        Rectangle {
            id: focusPointRect
            border {
                width: 3
                color: "#000000"
            }

            color: "transparent"
            radius: 90
            width: 80
            height: 80
            visible: false

            Timer {
                id: visTm
                interval: 500; running: false; repeat: false
                onTriggered: focusPointRect.visible = false
            }
        }

        Rectangle {
            anchors.fill: parent
            opacity: blurView ? 1 : 0
            color: "#40000000"
            visible: opacity != 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 300
                }
            }
        }
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

    function gcd(a, b) {
        if (b == 0) {
            return a;
        } else {
            return gcd(b, a % b);
        }
    }

    function fnAspectRatio() {
        var maxResolution = {width: 0, height: 0};
        var new43 = 0;
        var new169 = 0;

        for (var p in camera.imageCapture.supportedResolutions) {
            var res = camera.imageCapture.supportedResolutions[p];

            var gcdValue = gcd(res.width, res.height);
            var aspectRatio = (res.width / gcdValue) + ":" + (res.height / gcdValue);

            if (res.width * res.height > maxResolution.width * maxResolution.height) {
                maxResolution = res;
            }

            if (aspectRatio === "4:3" && !new43) {
                new43 = 1;
                camera.firstFourThreeResolution = res;
            }

            if (aspectRatio === "16:9" && !new169) {
                new169 = 1;
                camera.firstSixteenNineResolution = res;
            }
        }

        if (camera.aspWide) {
            camera.imageCapture.resolution = camera.firstSixteenNineResolution;
        } else {
            camera.imageCapture.resolution = camera.firstFourThreeResolution
        }

        //if (settings.cameras[camera.deviceId].resolution == 0) {
          //  settings.cameras[camera.deviceId].resolution = Math.round((camera.imageCapture.supportedResolutions[0].width * camera.imageCapture.supportedResolutions[0].height) / 1000000)
        //}
    }
    
    Camera {
        id: camera
        captureMode: Camera.CaptureStillImage

        property variant firstFourThreeResolution
        property variant firstSixteenNineResolution
        property var aspWide: 0

        focus {
            focusMode: Camera.FocusMacro
            focusPointMode: Camera.FocusPointCustom
        }

        imageProcessing {
            denoisingLevel: 1.0
            sharpeningLevel: 1.0
            whiteBalanceMode: Camera.WhiteBalanceAuto
        }

        flash.mode: Camera.FlashOff

        imageCapture {
            onImageCaptured: {
                if (soundButton.soundOn) {
                    sound.play()
                }
                if (settings.hideTimerInfo) { // this opens timer info shit
                    tmDrawer.open()
                }

                if (mediaView.index < 0) {
                    mediaView.folder = StandardPaths.writableLocation(StandardPaths.PicturesLocation) + "/droidian-camera"
                }
            }
        }

        Component.onCompleted: {
            camera.stop()
            var currentCam = settings.cameraId
            for (var i = 0; i < QtMultimedia.availableCameras.length; i++) {
                if (settings.cameras[i].resolution == 0)
                    camera.deviceId = i
            }

            if (settings.aspWide == 1 || settings.aspWide == 0) {
                camera.aspWide = settings.aspWide
            }

            window.fnAspectRatio()

            camera.deviceId = currentCam
            camera.start()
        }

        onCameraStatusChanged: {
            if (camera.cameraStatus == Camera.LoadedStatus) {
                window.fnAspectRatio()
            }
        }

        onDeviceIdChanged: {
            settings.setValue("cameraId", deviceId);
        }

        onAspWideChanged: {
            settings.setValue("aspWide", aspWide);
        }
    }

    MediaPlayer {
        id: camGst
        autoPlay: false
        videoOutput: viewfinder
        property var backendId: 0
        property string outputPath: StandardPaths.writableLocation(StandardPaths.MoviesLocation).toString().replace("file://","") +
                                            "/droidian-camera/video" + Qt.formatDateTime(new Date(), "yyyyMMdd_hhmmsszzz") + ".mkv"

        Component.onCompleted: {
            fileManager.createDirectory("/Videos/droidian-camera");
        }

        property var backends: [
            {
                front: "gst-pipeline: droidcamsrc mode=2 camera-device=1 ! video/x-raw ! videoconvert ! qtvideosink",
                frontRecord: "gst-pipeline: droidcamsrc camera_device=1 mode=2 ! tee name=t t. ! queue ! video/x-raw, width=" + camera.viewfinder.resolution.width + ", height=" + camera.viewfinder.resolution.height + " ! videoconvert ! videoflip video-direction=2 ! qtvideosink t. ! queue ! video/x-raw, width=" + camera.viewfinder.resolution.width + ", height=" + camera.viewfinder.resolution.height + " ! videoconvert ! videoflip video-direction=auto ! jpegenc ! mkv. autoaudiosrc ! queue ! audioconvert ! droidaenc ! mkv. matroskamux name=mkv ! filesink location=" + outputPath,
                back: "gst-pipeline: droidcamsrc mode=2 camera-device=" + camera.deviceId + " ! video/x-raw ! videoconvert ! qtvideosink",
                backRecord: "gst-pipeline: droidcamsrc camera_device=" + camera.deviceId + " mode=2 ! tee name=t t. ! queue ! video/x-raw, width=" + camera.viewfinder.resolution.width + ", height=" + camera.viewfinder.resolution.height + " ! videoconvert ! qtvideosink t. ! queue ! video/x-raw, width=" + camera.viewfinder.resolution.width + ", height=" + camera.viewfinder.resolution.height + " ! videoconvert ! videoflip video-direction=auto ! jpegenc ! mkv. autoaudiosrc ! queue ! audioconvert ! droidaenc ! mkv. matroskamux name=mkv ! filesink location=" + outputPath
            }
        ]

        onError: {
            if (backendId + 1 in backends) {
                backendId++;
            }
        }
    }

    function handleVideoRecording() {
        if (window.videoCaptured == false) {
            camGst.outputPath = StandardPaths.writableLocation(StandardPaths.MoviesLocation).toString().replace("file://","") +
                                            "/droidian-camera/video" + Qt.formatDateTime(new Date(), "yyyyMMdd_hhmmsszzz") + ".mkv"

            if (camera.position == Camera.BackFace) {
                camGst.source = camGst.backends[camGst.backendId].backRecord;
            } else {
                camGst.source = camGst.backends[camGst.backendId].frontRecord;
            }

            camera.stop();

            camGst.play();
            window.videoCaptured = true;

            console.log(window.videoCaptured)
        } else {
            camGst.stop();
            window.videoCaptured = false;

            camera.cameraState = Camera.UnloadedState;
            camera.start();
        }
    }

    Item {
        id: camZoom
        property real zoomFactor: 2.0
        property real zoom: 0
        NumberAnimation on zoom {
            duration: 200
            easing.type: Easing.InOutQuad
        }

        onScaleChanged: {
            camera.setDigitalZoom(scale * zoomFactor)
        }
    }

    PinchArea { //Area that controls the focus point and swipeView bar
        width: parent.width
        height: parent.height * 0.85
        pinch.target: camZoom
        pinch.maximumScale: camera.maximumDigitalZoom / camZoom.zoomFactor
        pinch.minimumScale: 0
        

        MouseArea {
            id: dragArea
            anchors.fill: parent

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
                    // Horizontal swipe detected
                    if (deltaX > 0) {// Handle swipe right action
                        console.log("Swipe right")
                        window.camEnable = true
                        window.videoEnable = false
                        console.log("camEnable: " + window.camEnable )
                        console.log("videoEnable: " + window.videoEnable )
                        
                    } else {// Handle swipe left action
                        console.log("Swipe left")
                        window.camEnable = false
                        window.videoEnable = true
                        console.log("camEnable: " + window.camEnable )
                        console.log("videoEnable: " + window.videoEnable )
                        
                    }
                } else { // Handle clicks
                    camera.focus.customFocusPoint = Qt.point(mouse.x / dragArea.width, mouse.y / dragArea.height)
                    camera.focus.focusMode = Camera.FocusMacro
                    focusPointRect.width = 60
                    focusPointRect.height = 60
                    focusPointRect.visible = true
                    focusPointRect.x = mouse.x - (focusPointRect.width / 2)
                    focusPointRect.y = mouse.y - (focusPointRect.height / 2)
                    visTm.start()
                    camera.searchAndLock()
                }
            }
        }

        onPinchUpdated: {
            camZoom.zoom = pinch.scale * camZoom.zoomFactor
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
                visible: camera.position !== Camera.UnspecifiedPosition && !window.videoCaptured

                background: Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                }

                onClicked: {
                    if (camera.position === Camera.BackFace) {
                        drawer.close()
                        camera.position = Camera.FrontFace;
                    } else if (camera.position === Camera.FrontFace) {
                        drawer.close()
                        camera.position = Camera.BackFace;
                    }
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
                state: settings.flash

                visible: !window.videoCaptured

                states: [
                    State {
                        name: "flashOff"
                        PropertyChanges {
                            target: camera
                            flash.mode: Camera.FlashOff
                        }

                        PropertyChanges {
                            target: settings
                            flash: "flashOff"
                        }
                    },

                    State {
                        name: "flashOn"
                        PropertyChanges {
                            target: camera
                            flash.mode: Camera.FlashOn
                        }

                        PropertyChanges {
                            target: settings
                            flash: "flashOn"
                        }
                    },

                    State {
                        name: "flashAuto"
                            PropertyChanges {
                            target: camera
                            flash.mode: Camera.FlashAuto
                        }

                        PropertyChanges {
                            target: settings
                            flash: "flashAuto"
                        }
                    }
                ]

                background: Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                }

                onClicked: {
                    if (camera.position !== Camera.FrontFace) {
                        if (flashButton.state == "flashOff") {
                            flashButton.state = "flashOn"
                        } else if (flashButton.state == "flashOn") {
                            flashButton.state = "flashAuto"
                        } else if (flashButton.state == "flashAuto") {
                            flashButton.state = "flashOff"
                        }
                    }
                }

                Text {
                    anchors.fill: parent
                    text: flashButton.state == "flashOn" ? "\u2714" :
                            flashButton.state == "flashOff" ? "\u2718" : "A"
                    color: "white"
                    z: parent.z + 1
                    font.pixelSize: 32
                    font.bold: true
                    style: Text.Outline;
                    styleColor: "black"
                    bottomPadding: 10
                }
            }

            Button {
                id: aspectRatioButton
                Layout.preferredWidth: 60
                Layout.preferredHeight: 40
                Layout.alignment: Qt.AlignHCenter
                palette.buttonText: "white"

                font.pixelSize: 14
                font.bold: true
                text: camera.aspWide ? "16:9" : "4:3"

                visible: !window.videoCaptured

                background: Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.width: 2
                    border.color: "white"
                    radius: 8
                }

                onClicked: {
                    if (!camera.aspWide) {
                        drawer.close()
                        camera.aspWide = 1;
                        camera.imageCapture.resolution = camera.firstSixteenNineResolution
                    } else {
                        drawer.close()
                        camera.aspWide = 0;
                        camera.imageCapture.resolution = camera.firstFourThreeResolution
                    }
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

                function getSpaces(numDigits) {
                    if (numDigits === 1) {
                        return "      ";
                    } else if (numDigits === 2) {
                        return "    ";
                    } else if (numDigits === 3) {
                        return " ";
                    } else {
                        return "";
                    }
                }

                Repeater {
                    model: allCamerasModel
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: parent.width * 0.9
                    Button {
                        property var pos: model.position == 1 ? "Back" : "Front"
                        property var numDigits: settings.cameras[model.cameraId].resolution.toString().length
                        Layout.alignment: Qt.AlignLeft
                        visible: parent.visible
                        icon.name: "camera-video-symbolic"
                        icon.color: "white"
                        icon.width: 48
                        icon.height: 48
                        palette.buttonText: "white"

                        font.pixelSize: 32
                        font.bold: true
                        text: " " + settings.cameras[model.cameraId].resolution + "MP" + backCamSelect.getSpaces(numDigits) + pos

                        background: Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                        }

                        onClicked: {
                            camera.deviceId = model.cameraId
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
        id: preCaptureTimer
        interval: 1000
        onTriggered: {
            countDown -= 1
            if (countDown < 1) {
                camera.imageCapture.capture();
                preCaptureTimer.stop();
            }
        }

        running: false
        repeat: true
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

        GridLayout {
            columnSpacing: 5
            rowSpacing: 25
            anchors.centerIn: parent
            width: parent.width * 0.9
            columns: 2
            rows: 2

            Button {
                icon.name: "help-about-symbolic"
                icon.color: "lightblue"
                icon.width: 48
                icon.height: 48
                Layout.preferredWidth: icon.width * 1.5
                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                Layout.topMargin: 10

                background: Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                }
            }

            Text {
                Layout.alignment: Qt.AlignLeft
                Layout.fillWidth: true
                Layout.topMargin: 10
                text: "Press & hold to use the timer"
                horizontalAlignment: Text.AlignHCenter
                color: "white"
                font.pixelSize: 32
                font.bold: true
                style: Text.Outline;
                styleColor: "black"
                wrapMode: Text.WordWrap
            }

            Button {
                icon.name: "emblem-default-symbolic"
                icon.color: "red"
                icon.width: 100
                icon.height: 100
                Layout.columnSpan: 2
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true

                background: Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                }

                onClicked: {
                    console.log("Before: hideTimerInfo =", settings.hideTimerInfo);
                    settings.hideTimerInfo = 1;
                    settings.setValue("hideTimerInfo", 1);
                    console.log("After: hideTimerInfo =", settings.hideTimerInfo);
                    tmDrawer.close()
                    
                }
            }
        }
    }

    Rectangle {
        id: menuBtn2Frame
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        height: 60
        width: 60
        anchors.rightMargin: 50
        anchors.bottomMargin: 35

        Button {
            id: menuBtn2
            anchors.fill: parent
            icon.name: "open-menu-symbolic"
            icon.color: "white"
            icon.width: 32
            icon.height: 32
            visible: drawer.position == 0.0 && optionContainer.state == "closed"

            background: Rectangle {

                color: "black"
                opacity: 0.4
            }

            onClicked: {
                if (!mediaView.visible) {
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
        radius:90
        width: 60
        anchors.leftMargin: 50
        anchors.bottomMargin: 35

        Rectangle {
            id: reviewBtn
            
            width: parent.width
            height: parent.height
            radius: 90
            color: "black"

            visible: true   

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
                source:  (window.videoEnable)? mediaView.lastImg : ""
                scale: Math.min(parent.width / width, parent.height / height)
            }
        }

        Rectangle {
            anchors.fill: reviewBtn
            color: "transparent"
            border.width: 2
            border.color: "white"
            radius: 90

            visible: true

            MouseArea {
                anchors.fill: parent
                onClicked: mediaView.visible = true;
            }
        }
    }

    

    Rectangle {// video
        id: videoBtn
        height: 100
        width: 100
        radius: 70
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter 
        anchors.bottomMargin: 15  
        visible: window.videoEnable
        
        color: Qt.rgba(0, 0, 0, 0.6) // light black with 60% transparency

        Button {
            anchors.fill: videoBtn
            anchors.centerIn: parent
            enabled: window.videoEnable

            Rectangle {
                anchors.centerIn: parent
                width: 50
                visible: window.videoState ? true: false
                height: 50
                color:  "red"
                radius: 70
            }

            Rectangle {
                anchors.centerIn: parent
                width: 40
                visible: !window.videoState ? true: false
                height: 40
                color:  "black"
            }
            text: preCaptureTimer.running ? countDown : ""

            palette.buttonText: "white"

            font.pixelSize: 64
            font.bold: true

            background: Rectangle {
                anchors.centerIn: parent
                width: 70
                height: 70
                color:  "white"
                radius: 50
            }

            onClicked: { // video
                console.log("clicked")
                window.videoState = 1 - window.videoState; 
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

    Rectangle {// camera
        id: shutterBtn
        anchors.bottom: parent.bottom
        height: 125
        width: parent.width
        visible: window.camEnable
        color: Qt.rgba(0, 0, 0, 0.6) // light black with 60% transparency

        Button {
            anchors.centerIn: parent
            enabled: window.camEnable

            icon.name: preCaptureTimer.running ? "" :
                            optionContainer.state == "opened" && delayTime.currentIndex < 1 ||
                            optionContainer.state == "opened" && backCamSelect.visible ? "window-close-symbolic" :
                            !window.videoCaptured ? "media-record-symbolic" :
                            window.videoCaptured ? "media-playback-stop-symbolic" : "shutter"
            
            icon.source: preCaptureTimer.running ? "" :
                                optionContainer.state == "opened" && delayTime.currentIndex > 0 ? "icons/timer.svg" : "icons/shutter.svg"

            icon.color:  "white"
            icon.width: 100
            icon.height: 100
            rotation: shutterBtn.pressed ? 180 : 0
            text: preCaptureTimer.running ? countDown : ""
            palette.buttonText: "red"
            font.pixelSize: 64
            font.bold: true
            visible: true

            background: Rectangle {// camera
                anchors.centerIn: parent
                width: 100
                height: 100
                color:  "black"
                radius: 70
            }

            onClicked: { // camera 
                if (optionContainer.state == "opened" && delayTime.currentIndex > 0 && !backCamSelect.visible) {
                        optionContainer.state = "closed"
                        countDown = delayTime.currentIndex
                        preCaptureTimer.start()
                    } else if (optionContainer.state == "opened" && delayTime.currentIndex < 1 || 
                                    optionContainer.state == "opened" && backCamSelect.visible) {
                        optionContainer.state = "closed"
                    } else  {
                        camera.imageCapture.capture()
                    }
            }

            onPressAndHold: {
                delayTime.visible = true
                backCamSelect.visible = false
                optionContainer.state = "opened"
            }

            Behavior on rotation {
                RotationAnimation { 
                    duration: 250
                    direction: RotationAnimation.Counterclockwise
                }
            }
        }
    }

    MediaReview {
        id : mediaView
        anchors.fill : parent
        onClosed: camera.start()
        focus: visible
    }
}