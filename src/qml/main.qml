import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.12
import QtGraphicalEffects 1.0
import QtMultimedia 5.15

import Cutie 1.0
import Cutie.Camera 1.0

CutieWindow {
    id: window
    width: 400
    height: 800
    visible: true
    title: "Camera"
    property alias cam: camTest
    
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

    initialPage: CutiePage {  
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
    }

    MediaPlayer {
        id: camTest
        autoPlay: true
        videoOutput: viewfinder
        source: isFront || !("back" in backends[backendId])
            ? backends[backendId].front 
            : backends[backendId].back
        property var backendId: 0
        property var backends: [
            {
                front: "gst-pipeline: v4l2src ! qtvideosink"
            },
            {
                front: "gst-pipeline: droidcamsrc mode=2 camera-device=1 ! video/x-raw  ! videoconvert ! videoflip method=counterclockwise ! qtvideosink",
                back: "gst-pipeline: droidcamsrc mode=2 camera-device=0 ! video/x-raw  ! videoconvert ! videoflip method=clockwise ! qtvideosink"
            }
        ]
        property bool isFront: false

        onError: {
            if (backendId + 1 in backends)
                backendId++;
        }
    }

    Image {
        id: image
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
                if(cslate.state=="PhotoCapture"){
                    capturer.capture()
                    sound.play()
                }/*else{
                    cslate.state =  "PhotoCapture"
                    if(window.videoCaptured==true){
                        camera.videoRecorder.stop()
                        image.source="icons/record_video@27.png"
                        window.videoCaptured=false
                    }else{
                        camera.videoRecorder.record()
                            image.source="icons/record_video_stop@27.png"
                        window.videoCaptured=true
                    }
                }*/
            }
        }
    }

    Image {
        id: otherBtn
        x: 66
        y: 719
        width: 51
        height: 56
        anchors.right: image.left
        anchors.bottom: parent.bottom
        source: "icons/record_video@27.png"
        anchors.rightMargin: 38
        sourceSize.height: 512
        sourceSize.width: 513
        fillMode: Image.PreserveAspectFit
        anchors.bottomMargin: 25

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            onClicked: {
              if(cslate.state=="PhotoCapture"){
                  cslate.state =  "VideoCapture"
              }else{
                   cslate.state =  "PhotoCapture"
              }

            }
        }
    }

    Image {
        id: image2
        x: 19
        y: 11
        width: 40
        height: 40
        source: "icons/icon-s-sync.svg"
        fillMode: Image.PreserveAspectFit
        sourceSize.height: 40
        sourceSize.width: 40
        visible: "back" in camTest.backends[camTest.backendId]

        MouseArea {
            id: mouseArea2
            anchors.fill: parent
            onClicked: {
                camTest.isFront = !camTest.isFront;
            }
        }
    }
}