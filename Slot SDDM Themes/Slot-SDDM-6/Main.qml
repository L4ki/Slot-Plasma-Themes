
import Qt5Compat.GraphicalEffects
import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11
import QtQuick.Window 2.11
import "Components"

Pane {
    id: root

    height: config.ScreenHeight || Screen.height
    width: config.ScreenWidth || Screen.ScreenWidth

    LayoutMirroring.enabled: config.ForceRightToLeft == "true" ? true : Qt.application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    padding: config.ScreenPadding
    palette.button: "transparent"
    palette.highlight: config.AccentColour
    palette.text: config.MainColour
    palette.buttonText: config.MainColour
    palette.window: config.BackgroundColour

    font.family: config.Font
    font.pointSize: config.FontSize !== "" ? config.FontSize :
        Screen.primaryOrientation == Qt.PortraitOrientation ? parseInt(height / 160) : parseInt(height / 80)
    focus: true

    property bool leftleft: config.HaveFormBackground == "true" &&
                            config.PartialBlur == "false" &&
                            config.FormPosition == "left" &&
                            config.BackgroundImageHAlignment == "left"

    property bool leftcenter: config.HaveFormBackground == "true" &&
                              config.PartialBlur == "false" &&
                              config.FormPosition == "left" &&
                              config.BackgroundImageHAlignment == "center"

    property bool rightright: config.HaveFormBackground == "true" &&
                              config.PartialBlur == "false" &&
                              config.FormPosition == "right" &&
                              config.BackgroundImageHAlignment == "right"

    property bool rightcenter: config.HaveFormBackground == "true" &&
                               config.PartialBlur == "false" &&
                               config.FormPosition == "right" &&
                               config.BackgroundImageHAlignment == "center"
    Component.onCompleted: {
        Orientation.getOrientation()
        console.log('called orientation')
    }
    Item {
        id: sizeHelper

        anchors.fill: parent
        height: parent.height
        width: parent.width

        Rectangle {
            id: tintLayer
            anchors.fill: parent
            width: parent.width
            height: parent.height
            color: "white"
            opacity: config.DimBackgroundImage
            z: 1
        }

        Rectangle {
            id: formBackground
            anchors.fill: form
            anchors.centerIn: form
            color: root.palette.window
            visible: config.HaveFormBackground == "true" ? true : false
            opacity: config.PartialBlur == "true" ? 0.3 : 1
            z: 1
        }

        LoginForm {
            id: form
            height: parent.height
            // If in portrait orientation we should take up half instead of 40% of the screen to avoid crowding
            width: parent.width / 2.5
            anchors.horizontalCenter: config.FormPosition == "center" ? parent.horizontalCenter : undefined
            anchors.left: config.FormPosition == "left" ? parent.left : undefined
            anchors.right: config.FormPosition == "right" ? parent.right : undefined
            virtualKeyboardActive: virtualKeyboard.state == "visible" ? true : false
            z: 1
        }

        Button {
            id: vkb
            onClicked: virtualKeyboard.switchState()
            visible: virtualKeyboard.status == Loader.Ready && config.ForceHideVirtualKeyboardButton == "false"
            anchors.bottom: parent.bottom
            anchors.bottomMargin: implicitHeight
            anchors.horizontalCenter: form.horizontalCenter
            z: 1
            contentItem: Text {
                text: config.TranslateVirtualKeyboardButton || "Virtual Keyboard"
                color: parent.visualFocus ? palette.highlight : palette.text
                font.pointSize: root.font.pointSize * 0.8
            }
            background: Rectangle {
                id: vkbbg
                color: "transparent"
            }
        }

        Loader {
            id: virtualKeyboard
            source: "Components/VirtualKeyboard.qml"
            state: "hidden"
            property bool keyboardActive: item ? item.active : false
            onKeyboardActiveChanged: keyboardActive ? state = "visible" : state = "hidden"
            width: parent.width
            z: 1
            function switchState() { state = state == "hidden" ? "visible" : "hidden" }
            states: [
                State {
                    name: "visible"
                    PropertyChanges {
                        target: form
                        systemButtonVisibility: false
                        clockVisibility: false
                    }
                    PropertyChanges {
                        target: virtualKeyboard
                        y: root.height - virtualKeyboard.height
                        opacity: 1
                    }
                },
                State {
                    name: "hidden"
                    PropertyChanges {
                        target: virtualKeyboard
                        y: root.height - root.height/4
                        opacity: 0
                    }
                }
            ]
            transitions: [
                Transition {
                    from: "hidden"
                    to: "visible"
                    SequentialAnimation {
                        ScriptAction {
                            script: {
                                virtualKeyboard.item.activated = true;
                                Qt.inputMethod.show();
                            }
                        }
                        ParallelAnimation {
                            NumberAnimation {
                                target: virtualKeyboard
                                property: "y"
                                duration: 100
                                easing.type: Easing.OutQuad
                            }
                            OpacityAnimator {
                                target: virtualKeyboard
                                duration: 100
                                easing.type: Easing.OutQuad
                            }
                        }
                    }
                },
                Transition {
                    from: "visible"
                    to: "hidden"
                    SequentialAnimation {
                        ParallelAnimation {
                            NumberAnimation {
                                target: virtualKeyboard
                                property: "y"
                                duration: 100
                                easing.type: Easing.InQuad
                            }
                            OpacityAnimator {
                                target: virtualKeyboard
                                duration: 100
                                easing.type: Easing.InQuad
                            }
                        }
                        ScriptAction {
                            script: {
                                Qt.inputMethod.hide();
                            }
                        }
                    }
                }
            ]
        }

        Image {
            id: backgroundImage

            height: parent.height
            width: config.HaveFormBackground == "true" && config.FormPosition != "center" && config.PartialBlur != "true" ? parent.width - formBackground.width : parent.width
            anchors.left: leftleft ||
                          leftcenter ?
                                formBackground.right : undefined

            anchors.right: rightright ||
                           rightcenter ?
                                formBackground.left : undefined

            horizontalAlignment: config.BackgroundImageHAlignment == "left" ?
                                 Image.AlignLeft :
                                 config.BackgroundImageHAlignment == "right" ?
                                 Image.AlignRight : Image.AlignHCenter

            verticalAlignment: config.BackgroundImageVAlignment == "top" ?
                               Image.AlignTop :
                               config.BackgroundImageVAlignment == "bottom" ?
                               Image.AlignBottom : Image.AlignVCenter

            source: config.background || config.Background
            fillMode: config.ScaleImageCropped == "true" ? Image.PreserveAspectCrop : Image.PreserveAspectFit
            asynchronous: true
            cache: true
            clip: true
            mipmap: true
        }

        MouseArea {
            anchors.fill: backgroundImage
            onClicked: parent.forceActiveFocus()
        }

        ShaderEffectSource {
            id: blurMask

            sourceItem: backgroundImage
            width: form.width
            height: parent.height
            anchors.centerIn: form
            sourceRect: Qt.rect(x,y,width,height)
            visible: config.FullBlur == "true" || config.PartialBlur == "true" ? true : false
        }

        GaussianBlur {
            id: blur

            height: parent.height
            width: config.FullBlur == "true" ? parent.width : form.width
            source: config.FullBlur == "true" ? backgroundImage : blurMask
            radius: config.BlurRadius
            samples: config.BlurRadius * 2 + 1
            cached: true
            anchors.centerIn: config.FullBlur == "true" ? parent : form
            visible: config.FullBlur == "true" || config.PartialBlur == "true" ? true : false
        }
    }
}

