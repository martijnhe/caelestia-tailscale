pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services

// Route internet traffic through another device
ColumnLayout {
    id: root

    spacing: Tokens.spacing.small

    TsSection {
        text: Tailscale.currentExitNode ? Tr.tr("Exit node · %1").arg(Tailscale.currentExitNode.name) : Tr.tr("Exit node · none")
    }

    StyledText {
        Layout.fillWidth: true
        visible: Tailscale.exitNodes.length === 0
        text: Tr.tr("No devices in this tailnet offer an exit node. Enable “Run as exit node” on a device and approve it in the admin console.")
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.small
        wrapMode: Text.Wrap
    }

    ExitRow {
        visible: Tailscale.exitNodes.length > 0
        label: Tr.tr("None")
        detail: Tr.tr("Use your own internet connection")
        icon: "public"
        selected: Tailscale.currentExitNode === null
        onPicked: Tailscale.setExitNode(null)
    }

    Repeater {
        model: ScriptModel {
            values: Tailscale.exitNodes
            objectProp: "id"
        }

        ExitRow {
            required property var modelData

            label: modelData.name
            detail: modelData.online ? (modelData.owner || modelData.ips[0]) : Tailscale.lastSeenText(modelData.lastSeen)
            icon: Tailscale.osIcon(modelData.os)
            selected: modelData.exitNode
            available: modelData.online
            onPicked: Tailscale.setExitNode(modelData)
        }
    }

    TsToggle {
        Layout.topMargin: Tokens.spacing.small
        visible: Tailscale.exitNodes.length > 0
        label: Tr.tr("Allow local network access")
        description: Tr.tr("Reach printers and other LAN devices while using an exit node")
        isOn: Tailscale.prefs.exitNodeAllowLan ?? false
        busy: Tailscale.pending === "allowLan"
        onToggled: value => Tailscale.setPref("allowLan", "exit-node-allow-lan-access", value)
    }

    TsToggle {
        label: Tr.tr("Run as exit node")
        description: Tr.tr("Offer this device as an exit node (needs approval in the admin console)")
        isOn: Tailscale.prefs.advertiseExitNode ?? false
        busy: Tailscale.pending === "advertiseExit"
        onToggled: value => Tailscale.setPref("advertiseExit", "advertise-exit-node", value)
    }

    component ExitRow: RowLayout {
        id: exitRow

        required property string label
        property string detail
        property string icon
        property bool selected
        property bool available: true

        signal picked

        Layout.fillWidth: true
        Layout.rightMargin: Tokens.padding.extraSmall
        spacing: Tokens.spacing.small
        opacity: available ? 1 : 0.5

        MaterialIcon {
            text: exitRow.icon
            color: exitRow.selected ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            fill: exitRow.selected ? 1 : 0
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: exitRow.label
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                visible: text
                text: exitRow.detail
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }
        }

        StyledRadioButton {
            checked: exitRow.selected
            enabled: exitRow.available && Tailscale.pending === ""
            onClicked: {
                if (!exitRow.selected)
                    exitRow.picked();
                checked = Qt.binding(() => exitRow.selected);
            }
        }
    }
}
