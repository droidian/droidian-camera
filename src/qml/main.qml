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
                width: 4
                color: "steelblue"
            }
            color: "transparent"
            radius: 90
            width: 100
            height: 100
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
            camera.deviceId = settings.cameraId
            resolutionModel.clear()
            for (var p in camera.imageCapture.supportedResolutions){
                resolutionModel.append({"widthR": camera.imageCapture.supportedResolutions[p].width, "heightR": camera.imageCapture.supportedResolutions[p].height})
            }
            camera.imageCapture.resolution = camera.imageCapture.supportedResolutions[settings.resArray[camera.deviceId]]
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
        enabled: !photoView.visible

        MouseArea {
            id: dragArea
            hoverEnabled: true
            anchors.fill: parent
            scrollGestureEnabled: false

            onClicked: {
                camera.focus.customFocusPoint = Qt.point(mouse.x/dragArea.width, mouse.y/dragArea.height)
                camera.focus.focusMode = Camera.FocusMacro
                focusPointRect.width = 60
                focusPointRect.height = 60
                focusPointRect.visible = true
                focusPointRect.x = mouse.x - (focusPointRect.width/2)
                focusPointRect.y = mouse.y - (focusPointRect.height/2)
                visTm.start()
                camera.searchAndLock()
            }
        }
        anchors.fill:parent
        pinch.dragAxis: pinch.XAndYAxis
        pinch.target: camZoom
        pinch.maximumScale: camera.maximumDigitalZoom / camZoom.zoomFactor
        pinch.minimumScale: 0

        onPinchStarted: {
        }

        onPinchUpdated: {
            camZoom.zoom = pinch.scale * camZoom.zoomFactor
        }
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
        
        MouseArea {
            anchors.fill: parent
            onClicked: {
                flashButton.flashOn = !flashButton.flashOn;
            }
        }
    }

    Image {
        id: shutterBtn
        width: 90
        height: 90
        anchors.bottom: parent.bottom
        source: "icons/shutter_stills@27.png"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 8
        fillMode: Image.PreserveAspectFit

        Timer {
            id: preCaptureTimer
            interval: 1000
            onTriggered: {
                camera.imageCapture.capture();
                sound.play();
                postCaptureTimer.start();
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

        MouseArea{
            anchors.fill: parent
            onClicked: {
                if (cslate.state == "PhotoCapture") {
                    if (flashButton.flashOn) {
                        flashlightController.turnFlashlightOn();
                        preCaptureTimer.start();
                    } else {
                        camera.imageCapture.capture();
                        sound.play();
                    }
                } else {
                    if (camera.videoRecorder.recorderState === CameraRecorder.RecordingState) {
                        camera.videoRecorder.stop();
                        shutterBtn.source="icons/record_video@27.png";
                    } else {
                        camera.videoRecorder.record();
                        shutterBtn.source="icons/record_video_stop@27.png";
                    }
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
                    modeBtn.source = "icons/shutter_stills@27.png";
                    shutterBtn.source = "icons/record_video@27.png";
                } else {
                    cslate.state = "PhotoCapture";
                    camera.captureMode = Camera.CaptureStillImage;
                    modeBtn.source = "icons/record_video@27.png";
                    shutterBtn.source = "icons/shutter_stills@27.png";
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
            anchors.fill: parent
            onClicked: cameraSelectMenu.open()
        }

        Menu {
            id: cameraSelectMenu
            Repeater {
                model: backFacingCamerasModel
                delegate: MenuItem {
                    text: "Camera " + model.index
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
        source: "icons/icon-s-sync.svg"
        fillMode: Image.PreserveAspectFit
        sourceSize.height: 40
        sourceSize.width: 40
        visible: camera.position !== Camera.UnspecifiedPosition

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (camera.position === Camera.BackFace) {
                    camera.position = Camera.FrontFace;
                } else if (camera.position === Camera.FrontFace) {
                    camera.position = Camera.BackFace;
                }
            }
        }
    }
}
