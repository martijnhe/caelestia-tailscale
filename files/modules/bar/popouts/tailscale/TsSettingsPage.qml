pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services

// Tailscale preferences, health warnings and widget settings
ColumnLayout {
    id: root

    spacing: Tokens.spacing.small

    TsSection {
        text: Tr.tr("Network")
    }

    TsToggle {
        label: Tr.tr("Use Tailscale DNS")
        description: Tr.tr("MagicDNS names and your tailnet's DNS settings")
        isOn: Tailscale.prefs.acceptDns ?? true
        busy: Tailscale.pending === "acceptDns"
        onToggled: value => Tailscale.setPref("acceptDns", "accept-dns", value)
    }

    TsToggle {
        label: Tr.tr("Accept subnet routes")
        description: Tr.tr("Reach subnets advertised by other devices")
        isOn: Tailscale.prefs.acceptRoutes ?? false
        busy: Tailscale.pending === "acceptRoutes"
        onToggled: value => Tailscale.setPref("acceptRoutes", "accept-routes", value)
    }

    TsToggle {
        label: Tr.tr("Shields up")
        description: Tr.tr("Block all incoming connections from the tailnet")
        isOn: Tailscale.prefs.shieldsUp ?? false
        busy: Tailscale.pending === "shieldsUp"
        onToggled: value => Tailscale.setPref("shieldsUp", "shields-up", value)
    }

    TsToggle {
        label: Tr.tr("Tailscale SSH")
        description: Tr.tr("Run the Tailscale SSH server on this device")
        isOn: Tailscale.prefs.runSsh ?? false
        busy: Tailscale.pending === "ssh"
        onToggled: value => Tailscale.setPref("ssh", "ssh", value)
    }

    TsSection {
        visible: Tailscale.health.length > 0
        text: Tr.tr("Health warnings")
    }

    Repeater {
        model: Tailscale.health

        RowLayout {
            id: warning

            required property string modelData

            Layout.fillWidth: true
            Layout.rightMargin: Tokens.padding.extraSmall
            spacing: Tokens.spacing.small

            MaterialIcon {
                Layout.alignment: Qt.AlignTop
                text: "warning"
                color: Colours.palette.m3error
            }

            StyledText {
                Layout.fillWidth: true
                text: warning.modelData.replace(/(https:\/\/\S+)/g, "<a href=\"$1\">$1</a>")
                textFormat: Text.StyledText
                linkColor: Colours.palette.m3primary
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
                wrapMode: Text.Wrap
                onLinkActivated: link => Qt.openUrlExternally(link)
            }
        }
    }

    TsSection {
        text: Tr.tr("Widget")
    }

    TsToggle {
        label: Tr.tr("Notifications")
        description: Tr.tr("Connect, disconnect and failed actions")
        isOn: Tailscale.settings.notifications
        onToggled: value => Tailscale.settings.notifications = value
    }

    Repeater {
        model: [
            [Tr.tr("Account"), Tailscale.account || "–"],
            [Tr.tr("Tailnet"), Tailscale.tailnet?.Name ?? "–"],
            [Tr.tr("DNS suffix"), Tailscale.tailnet?.MagicDNSSuffix ?? "–"],
            [Tr.tr("State"), Tailscale.backendState],
            [Tr.tr("Control"), Tailscale.isOperator ? Tr.tr("allowed for %1").arg(Tailscale.user) : Tr.tr("needs sudo")]
        ]

        RowLayout {
            id: info

            required property var modelData

            Layout.fillWidth: true
            Layout.rightMargin: Tokens.padding.extraSmall

            StyledText {
                Layout.preferredWidth: 80
                text: info.modelData[0]
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
            }

            StyledText {
                Layout.fillWidth: true
                text: info.modelData[1]
                font: Tokens.font.body.small
                elide: Text.ElideMiddle
            }
        }
    }
}
