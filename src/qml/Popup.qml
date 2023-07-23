import QtQuick 2.0

Rectangle {
    id: popup

    radius: 5
    border.color: "lightblue"
    border.width: 2
    smooth: true
    color: "#99000000"
    state: "invisible"

    states: [
        State {
            name: "invisible"
            PropertyChanges { target: popup; opacity: 0 }
        },

        State {
            name: "visible"
            PropertyChanges { target: popup; opacity: 1.0 }
        }
        ]

    transitions: Transition {
        NumberAnimation { properties: "opacity"; duration: 100 }
    }

    function toggle() {
        if (state == "visible")
            state = "invisible";
        else
            state = "visible";
    }
}
