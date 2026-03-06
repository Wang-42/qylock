import QtQuick
import Quickshell
import Quickshell.Wayland
import "./shim"

ShellRoot {
    id: shellRoot

    property string activeTheme: Quickshell.env("QS_THEME") || "Genshin"
    property string themePath: Quickshell.shellDir + "/themes_link/" + activeTheme

    readonly property var sddm: sddmShim.sddm
    readonly property var config: sddmShim.config
    readonly property var userModel: sddmShim.userModel
    readonly property var sessionModel: sddmShim.sessionModel
    readonly property bool isWayland: Quickshell.env("XDG_SESSION_TYPE") === "wayland"

    SddmShim {
        id: sddmShim
        themePath: shellRoot.themePath
    }

    Component {
        id: themeComponent
        Loader {
            anchors.fill: parent
            source: "file://" + shellRoot.themePath + "/Main.qml"
            
            onLoaded: {
                item.forceActiveFocus()
            }
            onStatusChanged: {
                if (status === Loader.Error) {
                    console.error("FAILED to load theme:", source)
                }
            }
            Keys.onPressed: (event) => {
                if (item) item.forceActiveFocus()
            }
        }
    }

    Loader {
        active: shellRoot.isWayland
        sourceComponent: Component {
            WlSessionLock {
                id: lock
                locked: true
                surface: Component {
                    WlSessionLockSurface {
                        color: "black"
                        Loader {
                            anchors.fill: parent
                            sourceComponent: themeComponent
                        }
                    }
                }
            }
        }
    }

    Loader {
        active: !shellRoot.isWayland
        sourceComponent: Component {
            Variants {
                model: Quickshell.screens
                delegate: Window {
                    id: window
                    required property var modelData
                    screen: modelData
                    width: screen.width
                    height: screen.height
                    visible: true
                    visibility: Window.FullScreen
                    
                    onClosing: (close) => {
                        close.accepted = false;
                    }
                    
                    flags: Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint | Qt.MaximizeUsingFullscreenGeometryHint
                    color: "black"

                    Loader {
                        anchors.fill: parent
                        sourceComponent: themeComponent
                    }
                }
            }
        }
    }
}
