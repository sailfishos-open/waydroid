import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.DBus 2.0
import QtQml 2.2

Page {
    id: root

    property bool serviceRunning
    property bool waydroidAutostart
    property bool ready: false
    property string serviceStatus: serviceRunning ? "active" : "inactive"
    property string serviceName: "waydroid-session.service"

    DBusInterface {
        id: waydroidSessionService

        bus: DBus.SessionBus
        service: "org.freedesktop.systemd1"
        iface: "org.freedesktop.systemd1.Unit"
        signalsEnabled: true

        function updateProperties() {
            if (path !== "") {
                var s = waydroidSessionService.getProperty("ActiveState")
                root.serviceRunning = (s === "active")
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
        signal unitFilesChanged()

        onUnitFilesChanged: {
            updateAutostart()
        }

        Component.onCompleted: {
            updatePath()
            updateAutostart()
        }
        function updateAutostart() {
            manager.typedCall("GetUnitFileState", [{"type": "s", "value": serviceName}],
                              function(state) {
                                  console.log(state)
                                  if (state !== "disabled" && state !== "invalid") {
                                      root.waydroidAutostart = true
                                  } else {
                                      root.waydroidAutostart = false
                                      root.serviceRunning = false
                                  }
                              },
                              function() {
                                  root.waydroidAutostart = false
                                  root.serviceRunning = false
                              })
            }

        function setAutostart(isAutostart) {
            if(isAutostart)
                enableWaydroidUnit()
            else
                disableWaydroidUnit()
        }

        function enableWaydroidUnit() {
            manager.typedCall( "EnableUnitFiles",[{"type":"as","value":[serviceName]},
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
            manager.typedCall( "DisableUnitFiles",[{"type":"as","value":[serviceName]},
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
            manager.typedCall( "StartUnit",[{"type":"s","value":serviceName},
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
            manager.typedCall( "StopUnit",[{"type":"s","value":serviceName},
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
             manager.typedCall("LoadUnit", [{ "type": "s", "value": serviceName}]);
            manager.typedCall("GetUnit", [{ "type": "s", "value": serviceName}], function(unit) {
                waydroidSessionService.path = unit
            }, function() {
                waydroidSessionService.path = ""
            })
        }
    }

    Timer {
        id: runningUpdateTimer
        interval: 1000
        running: true
        repeat: true
        onTriggered:{
            manager.updatePath()
            waydroidSessionService.updateProperties()
        }
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
                x: Theme.horizontalPageMargin
                width: parent.width - 2*Theme.horizontalPageMargin
                text: qsTr("Waydroid session current status") + " - " + root.serviceStatus
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
        manager.call( "Reload" )
    }
}
