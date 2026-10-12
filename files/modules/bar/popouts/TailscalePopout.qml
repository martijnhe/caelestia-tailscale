pragma ComponentBehavior: Bound

import "./tailscale"
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services

ColumnLayout {
    id: root

    required property PopoutState popouts

    width: 380
    implicitWidth: 380
    spacing: Tokens.spacing.small

    Component.onCompleted: Tailscale.refresh()

    // Header
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.padding.medium
        Layout.rightMargin: Tokens.padding.extraSmall
        spacing: Tokens.spacing.small

        Image {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            Layout.rightMargin: Tokens.spacing.extraSmall
            source: Tailscale.logo
            sourceSize: Qt.size(56, 56)
            fillMode: Image.PreserveAspectFit
            smooth: true
            opacity: Tailscale.running ? 1 : 0.4

            layer.enabled: true
            layer.effect: Colouriser {
                sourceColor: "black"
                colorizationColor: Colours.palette.m3onSurface
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                text: "Tailscale"
                font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
            }

            StyledText {
                Layout.fillWidth: true
                text: {
                    if (!Tailscale.installed)
                        return Tr.tr("tailscale not installed");
                    if (!Tailscale.daemonOnline)
                        return Tr.tr("tailscaled is not running");
                    switch (Tailscale.backendState) {
                    case "Running":
                        {
                            const parts = [Tailscale.tailnet?.Name ?? Tailscale.account, Tailscale.selfIps[0] ?? ""];
                            if (Tailscale.currentExitNode)
                                parts.push(Tr.tr("via %1").arg(Tailscale.currentExitNode.name));
                            return parts.filter(p => p).join(" · ");
                        }
                    case "Stopped":
                        return Tr.tr("Disconnected");
                    case "NeedsLogin":
                        return Tr.tr("Logged out");
                    case "NeedsMachineAuth":
                        return Tr.tr("Waiting for admin approval");
                    case "Starting":
                        return Tr.tr("Connecting…");
                    }
                    return Tailscale.backendState;
                }
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }
        }

        IconButton {
            type: IconButton.Text
            icon: "settings"
            onClicked: Tailscale.page = Tailscale.page === "settings" ? "devices" : "settings"
        }

        StyledSwitch {
            checked: Tailscale.running
            disabled: Tailscale.pending !== "" || !Tailscale.daemonOnline || Tailscale.backendState === "NeedsLogin"
            onToggled: {
                Tailscale.setRunning(checked);
                checked = Qt.binding(() => Tailscale.running);
            }
        }
    }

    // Permission banner
    StyledRect {
        Layout.fillWidth: true
        visible: !Tailscale.isOperator
        implicitHeight: permRow.implicitHeight + Tokens.padding.small * 2
        radius: Tokens.rounding.medium
        color: Colours.palette.m3secondaryContainer

        RowLayout {
            id: permRow

            anchors.fill: parent
            anchors.margins: Tokens.padding.small
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: "admin_panel_settings"
                color: Colours.palette.m3onSecondaryContainer
            }

            StyledText {
                Layout.fillWidth: true
                text: Tr.tr("Changing Tailscale needs sudo. Allow %1 to control it (asks for your password once).").arg(Tailscale.user)
                color: Colours.palette.m3onSecondaryContainer
                font: Tokens.font.body.small
                wrapMode: Text.Wrap
            }

            TextButton {
                text: Tailscale.pending === "operator" ? Tr.tr("…") : Tr.tr("Allow control")
                disabled: Tailscale.pending !== ""
                onClicked: Tailscale.grantOperator()
            }
        }
    }

    // Error banner
    StyledRect {
        Layout.fillWidth: true
        visible: Tailscale.lastError !== ""
        implicitHeight: errorRow.implicitHeight + Tokens.padding.small * 2
        radius: Tokens.rounding.medium
        color: Colours.palette.m3errorContainer

        RowLayout {
            id: errorRow

            anchors.fill: parent
            anchors.margins: Tokens.padding.small
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: "error"
                color: Colours.palette.m3onErrorContainer
            }

            StyledText {
                Layout.fillWidth: true
                text: Tailscale.lastError
                color: Colours.palette.m3onErrorContainer
                font: Tokens.font.body.small
                wrapMode: Text.Wrap
            }

            IconButton {
                type: IconButton.Text
                icon: "close"
                onClicked: Tailscale.lastError = ""
            }
        }
    }

    // Logged out
    IconTextButton {
        Layout.fillWidth: true
        visible: Tailscale.backendState === "NeedsLogin"
        verticalPadding: Tokens.padding.extraSmall
        disabled: Tailscale.pending !== ""
        text: Tailscale.pending === "login" ? Tr.tr("Waiting for login in browser…") : Tr.tr("Log in")
        icon: "login"
        onClicked: Tailscale.addAccount()
    }

    // Tabs
    RowLayout {
        Layout.fillWidth: true
        visible: Tailscale.daemonOnline && Tailscale.page !== "settings"
        spacing: Tokens.spacing.extraSmall

        Repeater {
            model: [
                {
                    id: "devices",
                    label: Tr.tr("Devices"),
                    icon: "devices"
                },
                {
                    id: "exit",
                    label: Tr.tr("Exit node"),
                    icon: "logout"
                },
                {
                    id: "accounts",
                    label: Tr.tr("Accounts"),
                    icon: "switch_account"
                }
            ]

            TsChip {
                required property var modelData

                Layout.fillWidth: true
                text: modelData.label
                icon: modelData.icon
                checked: Tailscale.page === modelData.id
                onClicked: Tailscale.page = modelData.id
            }
        }
    }

    Loader {
        Layout.fillWidth: true
        sourceComponent: {
            if (!Tailscale.daemonOnline)
                return null;
            switch (Tailscale.page) {
            case "settings":
                return settingsPage;
            case "exit":
                return exitPage;
            case "accounts":
                return accountsPage;
            }
            return devicesPage;
        }
    }

    // Footer
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.spacing.small
        spacing: Tokens.spacing.small

        IconTextButton {
            Layout.fillWidth: true
            inactiveColour: Colours.palette.m3primaryContainer
            inactiveOnColour: Colours.palette.m3onPrimaryContainer
            verticalPadding: Tokens.padding.extraSmall
            text: Tr.tr("Admin console")
            icon: "open_in_new"
            onClicked: Tailscale.openAdmin()
        }

        IconTextButton {
            Layout.fillWidth: true
            type: IconTextButton.Tonal
            verticalPadding: Tokens.padding.extraSmall
            visible: Tailscale.selfIps.length > 0
            text: Tr.tr("Copy my IP")
            icon: "content_copy"
            onClicked: Tailscale.copy(Tailscale.selfIps[0], Tr.tr("IP"))
        }
    }

    Component {
        id: devicesPage

        TsDevicesPage {}
    }

    Component {
        id: exitPage

        TsExitPage {}
    }

    Component {
        id: accountsPage

        TsAccountsPage {}
    }

    Component {
        id: settingsPage

        TsSettingsPage {}
    }
}
