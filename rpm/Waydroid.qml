import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.DBus 2.0
import QtQml 2.2

Page {
    id: root

    property bool serviceRunning
    property bool waydroidAutostart
    property bool ready: false


    DBusInterface {
        id: waydroidSessionService

        bus: DBus.SessionBus
        service: "org.freedesktop.systemd1"
        iface: "org.freedesktop.systemd1.Unit"
        signalsEnabled: true

        function updateProperties() {
            var status = waydroidSessionService.getProperty("ActiveState")
            waydroidSystemdStatus.status = status
            if (path !== "") {
                root.serviceRunning = (status === "active")
            } else {
                root.serviceRunning = false
            }
        }
        onPathChanged: updateProperties()
    }

    DBusInterface {
        id: manager

        bus: DBus.SessionBus
        service: "org.freedesktop.systemd1"
        path: "/org/freedesktop/systemd1"
        iface: "org.freedesktop.systemd1.Manager"
        signalsEnabled: true

        signal unitNew(string name)
        onUnitNew: {
            if (name == "waydroid-session.service") {
                pathUpdateTimer.start()
            }
        }

        signal unitRemoved(string name)
        onUnitRemoved: {
            if (name == "waydroid-session.service") {
                waydroidSessionService.path = ""
                pathUpdateTimer.stop()
            }
        }

        signal unitFilesChanged()
        onUnitFilesChanged: {
            updateAutostart()
        }

        Component.onCompleted: {
            updatePath()
            updateAutostart()
        }
        function updateAutostart() {
            manager.typedCall("GetUnitFileState", [{"type": "s", "value": "waydroid-session.service"}],
                              function(state) {
                                  console.log(state)
                                  if (state !== "disabled" && state !== "invalid") {
                                      root.waydroidAutostart = true
                                  } else {
                                      root.waydroidAutostart = false
                                  }
                              },
                              function() {
                                  root.waydroidAutostart = false
                              })
            }

        function setAutostart(isAutostart) {
            if(isAutostart)
                enableWaydroidUnit()
            else
                disableWaydroidUnit()
        }

        function enableaydroidUnit() {
            manager.typedCall( "EnableUnitFiles",[{"type":"as","value":["waydroid-session.service"]},
                                                  {"type":"b","value":false},
                                                  {"type":"b","value":false}],
                              function(carries_install_info,changes){
                                  root.waydroidAutostart = true
                                  console.log(carries_install_info,changes)
                              },
                              function() {
                                  console.log("Enabling error")
                              }
                              )

        }

        function disableWaydroidUnit() {
            manager.typedCall( "DisableUnitFiles",[{"type":"as","value":["waydroid-session.service"]},
                                                   {"type":"b","value":false}],
                              function(changes){
                                  root.waydroidAutostart = false
                                  console.log(changes)
                              },
                              function() {
                                  console.log("Disabling error")
                              }
                              )
        }

        function startWaydroidUnit() {
            manager.typedCall( "StartUnit",[{"type":"s","value":"waydroid-session.service"},
                                            {"type":"s","value":"fail"}],
                              function(job) {
                                  console.log("job started - ", job)
                                  waydroidSessionService.updateProperties()
                                  runningUpdateTimer.start()
                              },
                              function() {
                                  console.log("job started failure")
                              })
        }

        function stopWaydroidUnit() {
            manager.typedCall( "StopUnit",[{"type":"s","value":"waydroid-session.service"},
                                           {"type":"s","value":"replace"}],
                              function(job) {
                                  console.log("job stopped - ", job)
                                  waydroidSessionService.updateProperties()
                                  runningUpdateTimer.start()
                              },
                              function() {
                                  console.log("job stopped failure")
                              })
        }

        function updatePath() {
            manager.typedCall("GetUnit", [{ "type": "s", "value": "waydroid-session.service"}], function(unit) {
                waydroidSessionService.path = unit
            }, function() {
                waydroidSessionService.path = ""
            })
        }
    }

    Timer {
        // starting and stopping can result in lots of property changes
        id: runningUpdateTimer
        interval: 1000
        repeat: true
        onTriggered:{
            waydroidSessionService.updateProperties()
        }
    }

    Timer {
        // stopping service can result in unit appearing and disappering, for some reason.
        id: pathUpdateTimer
        interval: 200
        onTriggered: manager.updatePath()
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height + Theme.paddingMedium
        width: parent.width

        Column {
            id:content
            width:parent.width

            PageHeader {
                id: header
                title: qsTr("Waydroid settings")
            }

            TextSwitch {
                id: autostart
                text: qsTr("Start Waydroid session on bootup")
                description: qsTr("When this is off, you won't have access to android applications")
                enabled: root.ready
                automaticCheck: false
                checked: root.waydroidAutostart
                onClicked: {
                    manager.setAutostart(!checked)
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*Theme.horizontalPageMargin
                text: qsTr("Start/stop Waydroid session daemon.")
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryHighlightColor
            }

            Label {
                id: waydroidSystemdStatus
                property string status: "invalid"
                x: Theme.horizontalPageMargin
                width: parent.width - 2*Theme.horizontalPageMargin
                text: qsTr("Waydroid session current status") + " - " + status
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryHighlightColor
            }

            Item {
                width: 1
                height: Theme.paddingLarge
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingLarge

                Button {
                    enabled: root.ready && (!root.serviceRunning)
                    text: qsTr("Start daemon")
                    width: (content.width - 2*Theme.horizontalPageMargin - parent.spacing) / 2
                    onClicked: manager.startWaydroidUnit()
                }

                Button {
                    enabled: root.ready && (root.serviceRunning)
                    text: qsTr("Stop daemon")
                    width: (content.width - 2*Theme.horizontalPageMargin - parent.spacing) / 2
                    onClicked: manager.stopWaydroidUnit()
                }
            }
        }
    }
    Component.onCompleted: {
        ready = true;
        waydroidSessionService.updateProperties();
    }
}
