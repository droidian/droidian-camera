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
    }

    Camera {
        id: camera
        focus {
            focusMode: Camera.FocusContinuous
        }
    }

    Item {
        id: camZoom
        onScaleChanged: {
            camera.setDigitalZoom(scale)
        }
    }

    PinchArea {
        anchors.fill: parent
        pinch.dragAxis: pinch.XAndYAxis
        pinch.target: camZoom
        pinch.maximumScale: camera.maximumDigitalZoom
        pinch.minimumScale: 0
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
        MouseArea{
            anchors.fill: parent
            onClicked: {
                if (cslate.state == "PhotoCapture") {
                    camera.imageCapture.capture();
                    sound.play();
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
