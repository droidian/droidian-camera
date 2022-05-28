import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.12
import QtGraphicalEffects 1.0
import QtMultimedia 5.15

Window {
    id: window
    width: 400
    height: 800
    visible: true
    title: "Camera"
    property bool videoCaptured: false
    /*
    Image {
        id: bug
        width: 0
        height: 0
        source: "file:/usr/share/atmospheres/air/wallpaper.jpg"
        sourceSize.height: 1080
        sourceSize.width: 1920
        fillMode: Image.PreserveAspectCrop

        smooth: true
        visible: false
        anchors.fill: parent
    }


    FastBlur {
        source: bug
        radius: 32
        anchors.fill: parent
    }
*/
    Item {
        id: cslate

    state: "PhotoCapture"

       states: [
           State {
               name: "PhotoCapture"
               StateChangeScript {
                   script: {
                       camera.captureMode = Camera.CaptureStillImage
                       otherBtn.source = "icons/record_video@27.png"
                       image.source= "icons/shutter_stills@27.png"

                       camera.start()
                   }
               }
           },
           State {
               name: "PhotoPreview"
           },
           State {
               name: "VideoCapture"
               StateChangeScript {
                   script: {
                       camera.captureMode = Camera.CaptureVideo
                        otherBtn.source = "icons/shutter_stills@27.png"
                        image.source= "icons/record_video@27.png"
                       camera.start()
                   }
               }
           },
           State {
               name: "VideoPreview"
               StateChangeScript {
                   script: {
                       camera.stop()
                   }
               }
           }
       ]
    }



    Rectangle {
        id: mainUi
        color: "#000000"
        anchors.fill: parent


    Camera {
        id: camera
        captureMode: Camera.CaptureStillImage

        imageCapture {
            onImageCaptured: {
                //photoPreview.source = preview
              //  stillControls.previewAvailable = true
              //  cameraUI.state = "PhotoPreview"
                previewd.source = preview
            }
        }

        videoRecorder {
            resolution: "1280x720"
            frameRate: 60
        }
    }
    SoundEffect {
           id: sound
           source: "sounds/camera-shutter-click-03.wav"
       }
    VideoOutput {
        id: viewfinder
        anchors.fill: parent
        //  visible: cameraUI.state == "PhotoCapture" || cameraUI.state == "VideoCapture"


        source: camera
        autoOrientation: true
    }

    Image {
        id: image
        x: 155
        y: 702
        width: 91
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
                      camera.imageCapture.capture()
                      sound.play()
                  }else{
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
                  }


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

        MouseArea {
            id: mouseArea2
            anchors.fill: parent
            onClicked: {

            }
        }
    }

    Image {
        id: image3
        x: 65
        y: 11
        width: 40
        height: 40
        visible: false
        source: "icons/icon-l-developer-mode.svg"
        fillMode: Image.PreserveAspectFit
        sourceSize.height: 40
        sourceSize.width: 40
    }

    Image {
        id: previewd
        y: 719
        width: 51
        height: 56
        anchors.left: image.right
        source: "../Изображения/IMG_00000006.jpg"
        anchors.leftMargin: 38
        sourceSize.width: 513
        fillMode: Image.PreserveAspectFit
        sourceSize.height: 512

        MouseArea {
            id: mouseArea1
            anchors.fill: parent
        }
    }


}




}

/*##^##
Designer {
    D{i:0;formeditorZoom:0.75}D{i:10}
}
##^##*/
