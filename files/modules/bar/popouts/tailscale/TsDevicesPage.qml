pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services

// This machine and the other devices on the tailnet. Click a name to copy its
// MagicDNS name, the copy button copies its Tailscale IP.
ColumnLayout {
    id: root

    readonly property list<var> shown: Tailscale.filter === "online" ? Tailscale.peers.filter(p => p.online) : Tailscale.peers

    spacing: Tokens.spacing.small

    TsSection {
        text: Tr.tr("This device")
    }

    DeviceRow {
        visible: Tailscale.self !== null
        node: Tailscale.self ?? ({})
        isSelf: true
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.spacing.small

        TsSection {
            Layout.topMargin: 0
            text: Tr.tr("Devices · %1 of %2 online").arg(Tailscale.onlineCount).arg(Tailscale.peers.length)
        }

        TsChip {
            text: Tr.tr("Online")
            checked: Tailscale.filter === "online"
            onClicked: Tailscale.filter = "online"
        }

        TsChip {
            text: Tr.tr("All")
            checked: Tailscale.filter === "all"
            onClicked: Tailscale.filter = "all"
        }
    }

    StyledText {
        visible: root.shown.length === 0
        text: Tailscale.peers.length ? Tr.tr("No other devices online") : Tr.tr("No other devices in this tailnet")
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.small
    }

    StyledFlickable {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(column.implicitHeight, 340)
        contentHeight: column.implicitHeight
        clip: true
        flickableDirection: Flickable.VerticalFlick

        ColumnLayout {
            id: column

            width: parent.width
            spacing: Tokens.spacing.small

            Repeater {
                model: ScriptModel {
                    values: root.shown
                    objectProp: "id"
                }

                DeviceRow {
                    required property var modelData

                    node: modelData
                }
            }
        }
    }

    component DeviceRow: RowLayout {
        id: row

        property var node
        property bool isSelf

        Layout.fillWidth: true
        Layout.rightMargin: Tokens.padding.extraSmall
        spacing: Tokens.spacing.small

        MaterialIcon {
            text: Tailscale.osIcon(row.node.os)
            color: row.node.online || row.isSelf ? Colours.palette.m3primary : Colours.palette.m3outline
            fill: row.node.online || row.isSelf ? 1 : 0
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.spacing.extraSmall
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall

                StyledText {
                    Layout.fillWidth: true
                    text: row.node.name ?? ""
                    elide: Text.ElideRight
                    color: row.node.online || row.isSelf ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
                    font.underline: nameArea.containsMouse

                    MouseArea {
                        id: nameArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Tailscale.copy(row.node.dns, Tr.tr("MagicDNS name"))
                    }
                }

                MaterialIcon {
                    visible: row.node.exitNode ?? false
                    text: "logout"
                    color: Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.small
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: {
                    const n = row.node;
                    const parts = [n.ips?.[0] ?? ""];
                    if (row.isSelf) {
                        parts.push(n.os);
                    } else if (n.online) {
                        if (n.active)
                            parts.push(n.direct ? Tr.tr("direct") : n.relay ? Tr.tr("relay %1").arg(n.relay) : Tr.tr("connecting"));
                        else
                            parts.push(Tr.tr("idle"));
                        if (n.rx || n.tx)
                            parts.push(`↓${Tailscale.formatBytes(n.rx)} ↑${Tailscale.formatBytes(n.tx)}`);
                    } else {
                        parts.push(Tailscale.lastSeenText(n.lastSeen));
                    }
                    if (n.expired)
                        parts.push(Tr.tr("key expired"));
                    return parts.filter(p => p).join(" · ");
                }
                color: row.node.expired ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }
        }

        IconButton {
            type: IconButton.Text
            icon: "content_copy"
            onClicked: Tailscale.copy(row.node.ips[0], Tr.tr("IP"))
        }
    }
}
