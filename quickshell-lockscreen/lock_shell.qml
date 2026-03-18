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
    property bool authenticated: false
    property bool sessionLocked: true

    SddmShim {
        id: sddmShim
        themePath: shellRoot.themePath
    }

    Connections {
        target: sddmShim.sddm
        function onLoginSucceeded() {
            shellRoot.authenticated = true
            shellRoot.sessionLocked = false
            
            // Hyprland Hack: Explicitly tell the compositor that it's okay for 
            // the session lock to vanish. This stops the "Oopsie daisy" screen.
            Quickshell.execDetached(["hyprctl", "keyword", "misc:allow_session_lock_restore", "1"]);
            Quickshell.execDetached(["loginctl", "unlock-session"]);

            // Transition gracefully like caelestia does.
            quitTimer.start()
        }
    }

    Timer {
        id: quitTimer
        interval: 1500
        onTriggered: {
            Qt.quit();
        }
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
        id: waylandLoader
        active: shellRoot.isWayland
        sourceComponent: Component {
            WlSessionLock {
                id: lock
                locked: shellRoot.sessionLocked
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
        id: x11Loader
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
                    visible: shellRoot.sessionLocked
                    visibility: Window.FullScreen
                    
                    onClosing: (close) => {
                        close.accepted = shellRoot.authenticated;
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
