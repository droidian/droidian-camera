import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.12
import QtGraphicalEffects 1.0
import QtMultimedia 5.15
import QtQuick.Layouts 1.15
import Qt.labs.settings 1.0

ApplicationWindow {
    id: window
    width: 400
    height: 800
    visible: true
    title: "Camera"
    property alias cam: camGst

    Settings {
        id: settings
        property int cameraId: 0
        property var resArray: []
    }

    ListModel {
        id: resolutionModel
    }

    ListModel {
        id: backFacingCamerasModel
        Component.onCompleted: {
            for (var i = 0; i < QtMultimedia.availableCameras.length; i++){
                var cameraInfo = QtMultimedia.availableCameras[i];

                if (cameraInfo.position === Camera.BackFace) {
                    append({"cameraId": cameraInfo.deviceId, "index": count + 1});
                }
            }
        }
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
    }

    Camera {
        id: camera
        captureMode: Camera.CaptureStillImage

        property variant firstFourThreeResolution
        property variant firstSixteenNineResolution

        focus {
            focusMode: Camera.FocusMacro
            focusPointMode: Camera.FocusPointCustom
        }

        onCameraStateChanged: {
            console.log(camera.cameraState)
        }

        Component.onCompleted: {
            if(!settings.resArray.length || (settings.resArray.length < QtMultimedia.availableCameras.length)) {
                var arr = []
                for (var i = 0; i < QtMultimedia.availableCameras.length; i++){
                    arr.push(0)
                }

                settings.setValue("resArray", arr)
            }

            if (QtMultimedia.availableCameras.length > 0) {
                camera.deviceId = QtMultimedia.availableCameras[0].deviceId;
            }

            camera.deviceId = settings.cameraId
            resolutionModel.clear()

            var maxResolution = {width: 0, height: 0};

            function gcd(a, b) {
                if (b == 0) {
                    return a;
                } else {
                    return gcd(b, a % b);
                }
            }

            for (var p in camera.imageCapture.supportedResolutions) {
                var res = camera.imageCapture.supportedResolutions[p];

                var gcdValue = gcd(res.width, res.height);
                var aspectRatio = (res.width / gcdValue) + ":" + (res.height / gcdValue);

                if (res.width * res.height > maxResolution.width * maxResolution.height) {
                    maxResolution = res;
                }

                if (aspectRatio === "4:3" && !firstFourThreeResolution) {
                    firstFourThreeResolution = res;
                    console.log("4:3 " + firstFourThreeResolution);
                }

                if (aspectRatio === "16:9" && !firstSixteenNineResolution) {
                    firstSixteenNineResolution = res;
                    console.log("16:9 " + firstSixteenNineResolution);
                }

                 resolutionModel.append({"widthR": res.width, "heightR": res.height})
            }

            camera.imageCapture.resolution = maxResolution;

            if (camera.deviceId in settings.resArray) {
                settings.resArray[camera.deviceId] = camera.imageCapture.supportedResolutions.indexOf(maxResolution);
                settings.setValue("resArray", settings.resArray);
            }

            console.log("Highest resolution: " + maxResolution.width + "x" + maxResolution.height);
        }
    }

    property bool videoCaptured: false

    MediaPlayer {
        id: camGst
        autoPlay: false
        videoOutput: viewfinder
        property var backendId: 0
        property string outputPath: "Videos/droidian-camera/video" + Qt.formatDateTime(new Date(), "yyyyMMdd_hhmmsszzz") + ".mkv"

        Component.onCompleted: {
            fileManager.createDirectory("Videos/droidian-camera");
        }

        property var backends: [
            {
                front: "gst-pipeline: droidcamsrc mode=2 camera-device=1 ! video/x-raw  ! videoconvert ! qtvideosink",
                frontRecord: "gst-pipeline: droidcamsrc camera_device=1 mode=2 ! tee name=t t. ! queue ! video/x-raw, width=1920, height=1080 ! videoconvert ! videoflip video-direction=2 ! qtvideosink t. ! queue ! video/x-raw, width=1920, height=1080 ! videoconvert ! videoflip video-direction=auto ! jpegenc ! mkv. autoaudiosrc ! queue ! audioconvert ! droidaenc ! mkv. matroskamux name=mkv ! filesink location=" + outputPath,
                back: "gst-pipeline: droidcamsrc mode=2 camera-device=0 ! video/x-raw  ! videoconvert ! qtvideosink",
                backRecord: "gst-pipeline: droidcamsrc camera_device=0 mode=2 ! tee name=t t. ! queue ! video/x-raw, width=1920, height=1080 ! videoconvert ! qtvideosink t. ! queue ! video/x-raw, width=1920, height=1080  ! videoconvert ! videoflip video-direction=auto ! jpegenc ! mkv. autoaudiosrc ! queue ! audioconvert ! droidaenc ! mkv. matroskamux name=mkv ! filesink location=" + outputPath
            }
        ]

        onError: {
            if (backendId + 1 in backends)
                backendId++;
        }
    }

    function handleVideoRecording() {
        if (window.videoCaptured == false) {
            if (camera.position === Camera.BackFace) {
                camGst.source = camGst.backends[camGst.backendId].backRecord;
            } else {
                camGst.source = camGst.backends[camGst.backendId].frontRecord;
            }

            camera.stop();

            camGst.play();
            shutterBtn.source = "icons/record_video_stop@27.png";
            window.videoCaptured = true;
        } else {
            camGst.stop();
            shutterBtn.source = "icons/record_video@27.png";
            window.videoCaptured = false;

            camera.cameraState = Camera.UnloadedState;
            camera.start();
        }
    }

    Item {
        id: camZoom
        property real zoomFactor: 2.0
        property real zoom: 0
        NumberAnimation on zoom { duration: 200; easing.type: Easing.InOutQuad } 

        onScaleChanged: {
            camera.setDigitalZoom(scale * zoomFactor)
        }
    }

    PinchArea {
        enabled: cslate.state !== "VideoCapture"
        anchors.fill:parent
        pinch.target: camZoom
        pinch.maximumScale: camera.maximumDigitalZoom / camZoom.zoomFactor
        pinch.minimumScale: 0

        MouseArea {
            id: dragArea
            hoverEnabled: true
            anchors.fill: parent
            scrollGestureEnabled: false

            onClicked: {
                if (cslate.state === "VideoCapture") {
                    return;
                }

                camera.focus.customFocusPoint = Qt.point(mouse.x/dragArea.width, mouse.y/dragArea.height)
                camera.focus.focusMode = Camera.FocusMacro
                focusPointRect.width = 60
                focusPointRect.height = 60
                focusPointRect.visible = true
                focusPointRect.x = mouse.x - (focusPointRect.width/2)
                focusPointRect.y = mouse.y - (focusPointRect.height/2)
                visTm.start()
                camera.searchAndLock()

                if (flashButton.flashOn && camera.position !== Camera.FrontFace) {
                    flashlightController.turnFlashlightOn()
                    focusFlashlightTimer.start()
                }
            }
        }

        onPinchStarted: {
        }

        onPinchUpdated: {
            camZoom.zoom = pinch.scale * camZoom.zoomFactor
        }
    }

    Timer {
        id: focusFlashlightTimer
        interval: 2000
        running: false
        repeat: false
        onTriggered: flashlightController.turnFlashlightOff()
    }

    Image {
        id: flashButton
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 20
        width: 40
        height: 40
        source: flashOn ? "icons/flash_on.svg" : "icons/flash_off.svg"
        fillMode: Image.PreserveAspectFit
        sourceSize.height: 40
        sourceSize.width: 40
        property bool flashOn: false
        enabled: cslate.state !== "VideoCapture"
        
        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (camera.position !== Camera.FrontFace) {
                    flashButton.flashOn = !flashButton.flashOn;
                }
            }
        }
    }

    Image {
        id: soundButton
        anchors.right: parent.right
        anchors.top: flashButton.bottom
        anchors.margins: 20
        width: 40
        height: 40
        source: soundOn ? "icons/sound_on.svg" : "icons/sound_off.svg"
        fillMode: Image.PreserveAspectFit
        sourceSize.height: 40
        sourceSize.width: 40
        property bool soundOn: true
        enabled: cslate.state !== "VideoCapture"
    
        MouseArea {
            anchors.fill: parent
            onClicked: {
                soundButton.soundOn = !soundButton.soundOn;
            }
        }
    }

    Image {
        id: timerSelectButton
        anchors.left: camSwitchBtn.left
        anchors.top: camSwitchBtn.bottom
        anchors.topMargin: 20
        source: "icons/timer.svg"
        sourceSize.height: 40
        sourceSize.width: 40
        width: 40
        height: 40
        fillMode: Image.PreserveAspectFit
        visible: true
        enabled: cslate.state !== "VideoCapture"

        MouseArea {
            anchors.fill: parent
            onClicked: timerSelectMenu.open()
        }

        Menu {
            id: timerSelectMenu
            width: timerSelectButton.width

            Repeater {
                model: [ "Off", "5", "10", "15" ]
                delegate: MenuItem {
                    text: modelData
                    width: timerSelectMenu.width / 1.2
                    height: timerSelectButton.height / 1.5

                    onTriggered: {
                        var timeInSeconds = parseInt(text);
                        if (isNaN(timeInSeconds)) {
                            preCaptureTimer.interval = 0;
                        } else {
                            preCaptureTimer.interval = timeInSeconds * 1000;
                        }

                        preCaptureTimer.running = false;
                    }
                }
            }
        }
    }

    Image {
        id: aspectRatioButton
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 20
        source: "icons/aspect_ratio.svg"
        sourceSize.height: 40
        sourceSize.width: 40
        width: 40
        height: 40
        fillMode: Image.PreserveAspectFit
        visible: true
        enabled: cslate.state !== "VideoCapture"

        MouseArea {
            anchors.fill: parent
            onClicked: aspectRatioMenu.open()
        }

        Menu {
            id: aspectRatioMenu
            width: aspectRatioButton.width * 2
            visible: false

            Repeater {
                model: [ "4:3", "16:9" ]
                delegate: MenuItem {
                    text: modelData
                    width: aspectRatioMenu.width
                    height: aspectRatioButton.height / 1.5

                    onTriggered: {
                        switch (text) {
                            case "4:3":
                                camera.imageCapture.resolution = camera.firstFourThreeResolution;
                                break;
                            case "16:9":
                                camera.imageCapture.resolution = camera.firstSixteenNineResolution;
                                break;
                        }
                    }
                }
            }
        }
    }

    Image {
        id: shutterBtn
        width: 90
        height: 90
        anchors.bottom: parent.bottom
        source: "icons/shutter.svg"
        sourceSize: Qt.size(180, 180)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 8
        fillMode: Image.PreserveAspectFit

        Timer {
            id: preCaptureTimer
            interval: 1000
            onTriggered: {
                camera.imageCapture.capture();
                postCaptureTimer.start();

                if (soundButton.soundOn) {
                    sound.play();
                }
            }

            running: false
            repeat: false
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

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (cslate.state == "PhotoCapture") {
                    if (flashButton.flashOn && camera.position !== Camera.FrontFace) {
                        flashlightController.turnFlashlightOn();
                        preCaptureTimer.start();
                    } else {
                        camera.imageCapture.capture();
                        preCaptureTimer.start();
                    }
                } else {
                    handleVideoRecording();
                }
            }
        }
    }

    Image {
        id: modeBtn
        anchors.left: parent.left
        anchors.margins: 20
        anchors.verticalCenter: shutterBtn.verticalCenter
        source: "icons/record_video@27.png"
        sourceSize.height: 40
        sourceSize.width: 40
        width: 40
        height: 40
        fillMode: Image.PreserveAspectFit

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            onClicked: {
                camera.cameraState = Camera.UnloadedState;
                if (cslate.state === "PhotoCapture") {
                    cslate.state = "VideoCapture";
                    camera.captureMode = Camera.CaptureVideo;
                    modeBtn.source = "icons/shutter.svg";
                    shutterBtn.source = "icons/record_video@27.png";
                } else {
                    cslate.state = "PhotoCapture";
                    camera.captureMode = Camera.CaptureStillImage;
                    modeBtn.source = "icons/record_video@27.png";
                    shutterBtn.source = "icons/shutter.svg";
                }

                camera.cameraState = Camera.ActiveState;
                camera.videoRecorder.resolution = camera.viewfinder.resolution;
            }
        }
    }

    Image {
        id: cameraSelectButton
        anchors.right: parent.right
        anchors.rightMargin: parent.width * 0.10
        anchors.verticalCenter: shutterBtn.verticalCenter
        source: "icons/list_cameras.svg"
        sourceSize.height: 40
        sourceSize.width: 40
        width: 40
        height: 40
        fillMode: Image.PreserveAspectFit
        visible: backFacingCamerasModel.count > 1

        MouseArea {
            enabled: cslate.state !== "VideoCapture"
            anchors.fill: parent
            onClicked: cameraSelectMenu.open()
        }

        Menu {
            id: cameraSelectMenu
            width: cameraSelectButton.width * 3.7
            Repeater {
                model: backFacingCamerasModel
                delegate: MenuItem {
                    text: "Camera " + model.index
                    width: cameraSelectMenu.width / 2
                    height: cameraSelectButton.height / 1.5

                    onTriggered: {
                        camera.deviceId = model.cameraId
                        settings.setValue("cameraId", model.index - 1)
                        resolutionModel.clear()
                        for (var p in camera.imageCapture.supportedResolutions){
                            resolutionModel.append({"widthR": camera.imageCapture.supportedResolutions[p].width, "heightR": camera.imageCapture.supportedResolutions[p].height})
                        }

                        camera.imageCapture.resolution = camera.imageCapture.supportedResolutions[settings.resArray[model.index - 1]]
                    }
                }
            }
        }
    }

    Image {
        id: camSwitchBtn
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 20
        width: 40
        height: 40
        source: "icons/switch_camera.svg"
        fillMode: Image.PreserveAspectFit
        sourceSize.height: 40
        sourceSize.width: 40
        visible: camera.position !== Camera.UnspecifiedPosition
        enabled: !videoCaptured

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (cslate.state == "PhotoCapture") {
                    if (camera.position === Camera.BackFace) {
                        camera.position = Camera.FrontFace;
                    } else if (camera.position === Camera.FrontFace) {
                        camera.position = Camera.BackFace;
                    }
                } else {
                    if (!(camGst.source === camGst.backends[camGst.backendId].frontRecord || camGst.source === camGst.backends[camGst.backendId].backRecord)) {
                        if (camera.position === Camera.BackFace) {
                            camera.position = Camera.FrontFace;
                        } else if (camera.position === Camera.FrontFace) {
                            camera.position = Camera.BackFace;
                        }
                    }
                }
            }
        }
    }
}
