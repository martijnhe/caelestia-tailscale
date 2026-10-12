import QtQuick
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services

// Tailscale logo tinted to the bar colour. Dimmed when stopped, a dot when an
// exit node is in use (primary) or Tailscale needs attention (error).
Item {
    id: root

    required property color colour
    readonly property bool attention: Tailscale.daemonOnline && (Tailscale.backendState === "NeedsLogin" || Tailscale.backendState === "NeedsMachineAuth")

    implicitWidth: sizer.implicitHeight
    implicitHeight: sizer.implicitHeight

    // Match the size of the other Material status icons
    MaterialIcon {
        id: sizer

        visible: false
        text: "vpn_lock"
    }

    Image {
        anchors.fill: parent
        anchors.margins: 2
        source: Tailscale.logo
        sourceSize: Qt.size(width * 2, height * 2)
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        opacity: Tailscale.running ? 1 : 0.4

        layer.enabled: true
        layer.effect: Colouriser {
            sourceColor: "black"
            colorizationColor: root.colour
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    StyledRect {
        visible: root.attention || (Tailscale.running && Tailscale.currentExitNode !== null)
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: -1
        implicitWidth: parent.width * 0.38
        implicitHeight: implicitWidth
        radius: Tokens.rounding.full
        color: root.attention ? Colours.palette.m3error : Colours.palette.m3primary
        border.width: 1.5
        border.color: Colours.tPalette.m3surfaceContainer
    }
}
