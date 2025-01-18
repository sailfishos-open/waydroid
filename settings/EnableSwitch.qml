// SPDX-FileCopyrightText: 2025 Miklos C. (edp17)
// SPDX-License-Identifier: Apache-2.0

import QtQuick 2.1
import Sailfish.Silica 1.0
import Nemo.DBus 2.0
import com.jolla.settings 1.0

SettingsToggle {
    id: root

    property bool serviceRunning
    property string serviceName: "waydroid-session.service"
    property string serviceStatus: serviceRunning ? "active" : "inactive"
    property string waydroidServicePath
    icon.source: "image://theme/icon-m-file-apk"
    active: serviceRunning
    name: qsTrId("Waydroid")

    readonly property string buttonName: qsTrId("Waydroid")

    menu: ContextMenu {
        SettingsMenuItem {
            onClicked: goToSettings("system_settings/system/waydroid")
        }
    }

    onToggled: {
        if (!serviceRunning) {
            manager.startWaydroidUnit()
            console.info("Waydroid-Toggle: engaged.")
        } else {
            manager.stopWaydroidUnit()
            console.info("Waydroid-Toggle: dis-engaged.")
        }
        manager.updatePath()
        waydroidSessionService.updateProperties()
    }

    Component.onCompleted: {
        console.info("Waydroid-Toggle loaded.")
    }

    /*
     * Dbus interface to systemd unit
    */
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

        Component.onCompleted: {
            updatePath()
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
                waydroidServicePath = unit
                waydroidSessionService.path = unit
            }, function() {
                waydroidServicePath = ""
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

}