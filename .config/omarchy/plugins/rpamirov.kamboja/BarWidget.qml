import QtQuick
import Quickshell.Io
import qs.Ui

BarWidget {
  id: root
  moduleName: "rpamirov.kamboja"

  property string vpnState: "inactive"
  property bool actionPending: false
  property string pendingAction: ""

  readonly property bool inactive: vpnState === "inactive"
  readonly property bool active: vpnState === "active"
  readonly property bool changing: vpnState === "changing"
  readonly property bool failed: vpnState === "failed"
  readonly property bool inactiveRevealed: inactive && !!bar
    && bar.centerSectionRevealHeld === true
    && bar.centerHoverRevealSuppressed !== true
  readonly property bool shown: !inactive || inactiveRevealed
  readonly property color stateColor: changing ? "#e5c07b"
    : failed ? "#e06c75"
    : active ? "#69d391"
    : (bar ? bar.barForeground : "#a0a0a0")

  implicitWidth: shown ? button.implicitWidth : 0
  implicitHeight: button.implicitHeight
  clip: true

  Behavior on implicitWidth {
    NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
  }

  function applyServiceState(rawState, exitCode) {
    if (actionPending) return

    var state = String(rawState || "").trim()
    if (exitCode !== 0) vpnState = "failed"
    else if (state === "active") vpnState = "active"
    else if (state === "activating" || state === "deactivating" || state === "reloading") vpnState = "changing"
    else if (state === "inactive") vpnState = "inactive"
    else vpnState = "failed"
  }

  function refresh() {
    if (!actionPending && !statusProcess.running) statusProcess.running = true
  }

  function toggle() {
    if (actionPending || changing) return

    actionPending = true
    vpnState = "changing"
    toggleDecisionProcess.running = true
  }

  Process {
    id: statusProcess
    command: [
      "/usr/bin/systemctl", "show",
      "--property=ActiveState", "--value",
      "kamboja.service"
    ]
    stdout: StdioCollector {
      id: statusOutput
      waitForEnd: true
    }
    onExited: function(exitCode) {
      root.applyServiceState(statusOutput.text, exitCode)
    }
  }

  Process {
    id: toggleDecisionProcess
    command: [
      "/usr/bin/systemctl", "show",
      "--property=ActiveState", "--value",
      "kamboja.service"
    ]
    stdout: StdioCollector {
      id: toggleDecisionOutput
      waitForEnd: true
    }
    onExited: function(exitCode) {
      var serviceState = String(toggleDecisionOutput.text || "").trim()
      if (exitCode !== 0) {
        console.warn("Kamboja toggle: state query failed, exit=" + exitCode)
        root.actionPending = false
        root.vpnState = "failed"
        return
      }

      root.pendingAction = serviceState === "active" || serviceState === "activating"
        ? "stop"
        : "start"
      console.info("Kamboja toggle: state=" + serviceState + " action=" + root.pendingAction)

      if (root.pendingAction === "start") {
        stopOthersProcess.running = true
        return
      }

      root.runPendingAction()
    }
  }

  Process {
    id: stopOthersProcess
    command: ["/home/rpamirov/.local/bin/vpn-stop-others", "kamboja"]
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        root.pendingAction = ""
        root.actionPending = false
        root.vpnState = "failed"
      } else {
        root.runPendingAction()
      }
    }
  }

  function runPendingAction() {
    toggleProcess.command = [
      "sudo", "-n", "/usr/bin/systemctl",
      root.pendingAction,
      "kamboja.service"
    ]
    toggleProcess.running = true
  }

  Process {
    id: idecoStatusProcess
    command: [
      "/usr/bin/systemctl", "--user", "show",
      "--property=ActiveState", "--value",
      "ideco-session.service"
    ]
    stdout: StdioCollector {
      id: idecoStatusOutput
      waitForEnd: true
    }
    onExited: function(exitCode) {
      var serviceState = String(idecoStatusOutput.text || "").trim()
      var mustStop = exitCode === 0
        && (serviceState === "active" || serviceState === "activating"
            || serviceState === "deactivating" || serviceState === "reloading")
      if (mustStop) {
        console.info("Kamboja toggle: stopping Ideco before start")
        idecoStopProcess.running = true
      } else {
        root.runPendingAction()
      }
    }
  }

  Process {
    id: idecoStopProcess
    command: [
      "/usr/bin/systemctl", "--user", "stop",
      "ideco-session.service"
    ]
    stderr: StdioCollector {
      id: idecoStopError
      waitForEnd: true
    }
    onExited: function(exitCode) {
      var errorText = String(idecoStopError.text || "").trim()
      if (exitCode !== 0) {
        console.warn("Kamboja toggle: could not stop Ideco, exit=" + exitCode
          + (errorText ? " error=" + errorText : ""))
        root.pendingAction = ""
        root.actionPending = false
        root.vpnState = "failed"
        return
      }
      root.runPendingAction()
    }
  }

  Process {
    id: toggleProcess
    stderr: StdioCollector {
      id: toggleError
      waitForEnd: true
    }
    onExited: function(exitCode) {
      var action = root.pendingAction
      var errorText = String(toggleError.text || "").trim()
      console.info("Kamboja toggle: action=" + action + " exit=" + exitCode
        + (errorText ? " error=" + errorText : ""))
      root.pendingAction = ""
      if (exitCode !== 0) {
        root.actionPending = false
        root.vpnState = "failed"
      } else {
        settleTimer.restart()
      }
    }
  }

  Timer {
    id: settleTimer
    interval: 150
    onTriggered: {
      root.actionPending = false
      root.refresh()
    }
  }

  Timer {
    interval: 1000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰇧"
    active: root.active || root.changing || root.failed
    activeColor: root.stateColor
    useActiveColor: true
    dimmed: root.inactive
    concealed: !root.shown
    interactive: root.shown
    tooltipText: "Kamboja VPN"

    onPressed: function(buttonId) {
      if (buttonId === Qt.LeftButton) root.toggle()
    }
  }
}
