pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services

// Fast user switching between Tailscale accounts (tailscale switch)
ColumnLayout {
    id: root

    spacing: Tokens.spacing.small

    Component.onCompleted: Tailscale.refreshAccounts()

    TsSection {
        text: Tr.tr("Accounts")
    }

    StyledText {
        Layout.fillWidth: true
        visible: !Tailscale.isOperator
        text: Tr.tr("Listing and switching accounts needs control permission. Select “Allow control” above.")
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.small
        wrapMode: Text.Wrap
    }

    Repeater {
        model: Tailscale.accounts

        RowLayout {
            id: acc

            required property var modelData

            Layout.fillWidth: true
            Layout.rightMargin: Tokens.padding.extraSmall
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: acc.modelData.current ? "account_circle" : "person"
                color: acc.modelData.current ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                fill: acc.modelData.current ? 1 : 0
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: acc.modelData.account
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: acc.modelData.current ? Tr.tr("%1 · current").arg(acc.modelData.tailnet) : acc.modelData.tailnet
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }
            }

            TextButton {
                visible: !acc.modelData.current
                type: TextButton.Tonal
                text: Tailscale.pending === "switch" ? Tr.tr("…") : Tr.tr("Switch")
                disabled: Tailscale.pending !== ""
                onClicked: Tailscale.switchAccount(acc.modelData)
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.spacing.small
        spacing: Tokens.spacing.small

        IconTextButton {
            Layout.fillWidth: true
            type: IconTextButton.Tonal
            verticalPadding: Tokens.padding.extraSmall
            visible: Tailscale.accounts.length > 1
            disabled: Tailscale.pending !== ""
            text: Tr.tr("Next account")
            icon: "switch_account"
            onClicked: Tailscale.cycleAccount()
        }

        IconTextButton {
            Layout.fillWidth: true
            type: IconTextButton.Tonal
            verticalPadding: Tokens.padding.extraSmall
            disabled: Tailscale.pending !== "" || !Tailscale.isOperator
            text: Tailscale.pending === "login" ? Tr.tr("Waiting for login…") : Tr.tr("Add account")
            icon: "person_add"
            onClicked: Tailscale.addAccount()
        }
    }

    StyledText {
        Layout.fillWidth: true
        visible: Tailscale.loginUrl !== ""
        text: Tr.tr("Finish signing in in your browser: %1").arg(Tailscale.loginUrl)
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.small
        wrapMode: Text.WrapAnywhere
    }
}
