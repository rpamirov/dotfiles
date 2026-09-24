import QtQuick
import QtQuick.Effects
import Quickshell.Io
import qs.Ui

BarWidget {
  id: root
  moduleName: "rpamirov.ideco"

  property string vpnState: "inactive"
  property bool actionPending: false
  property string pendingAction: ""
  readonly property url idecoIconSource: Qt.resolvedUrl("client_logo.svg")

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

  function applyState(rawState, exitCode) {
    if (actionPending) return
    var state = String(rawState || "").trim()
    if (exitCode !== 0) vpnState = "failed"
    else if (state === "active" || state === "changing"
             || state === "inactive" || state === "failed") vpnState = state
    else vpnState = "failed"
  }

  function refresh() {
    if (!actionPending && !statusProcess.running) statusProcess.running = true
  }

  function toggle() {
    if (actionPending) return
    actionPending = true
    pendingAction = inactive ? "start" : "stop"
    vpnState = "changing"
    if (pendingAction === "start") stopOthersProcess.running = true
    else startIdecoProcess()
  }

  function startIdecoProcess() {
    toggleProcess.command = ["/home/rpamirov/.local/bin/idecoctl", pendingAction]
    toggleProcess.running = true
  }

  Process {
    id: stopOthersProcess
    command: ["/home/rpamirov/.local/bin/vpn-stop-others", "ideco"]
    onExited: function(exitCode) {
      if (exitCode !== 0) { root.actionPending = false; root.vpnState = "failed" }
      else root.startIdecoProcess()
    }
  }

  Process {
    id: statusProcess
    command: ["/home/rpamirov/.local/bin/idecoctl", "status", "--plain"]
    stdout: StdioCollector {
      id: statusOutput
      waitForEnd: true
    }
    onExited: function(exitCode) {
      root.applyState(statusOutput.text, exitCode)
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
      console.info("Ideco toggle: action=" + action + " exit=" + exitCode
        + (errorText ? " error=" + errorText : ""))
      root.pendingAction = ""
      root.actionPending = false
      if (exitCode !== 0) root.vpnState = "failed"
      else settleTimer.restart()
    }
  }

  Timer {
    id: settleTimer
    interval: 250
    onTriggered: root.refresh()
  }

  Timer {
    interval: 5000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: ""
    iconComponent: Component {
      Item {
        Image {
          id: idecoIcon
          anchors.fill: parent
          source: root.idecoIconSource
          fillMode: Image.PreserveAspectFit
          asynchronous: true
          smooth: true
          visible: false
          layer.enabled: true
        }

        MultiEffect {
          anchors.fill: idecoIcon
          source: idecoIcon
          colorization: 1.0
          colorizationColor: root.stateColor
          opacity: root.active ? 1.0 : root.changing || root.failed ? 0.85 : 0.55
        }
      }
    }
    active: root.active || root.changing || root.failed
    activeColor: root.stateColor
    useActiveColor: true
    dimmed: root.inactive
    concealed: !root.shown
    interactive: root.shown
    tooltipText: "Ideco VPN"

    onPressed: function(buttonId) {
      if (buttonId === Qt.LeftButton) root.toggle()
    }
  }
}
