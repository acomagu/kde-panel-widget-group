// SPDX-License-Identifier: MIT

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.private.shell as PlasmaPrivate
import org.kde.plasma.plasmoid

KCM.SimpleKCM {
    id: root

    signal configurationChanged

    property var cfg_widgetOrder: []
    property var cfg_widgetOrderDefault: []
    property string cfg_compactAppletId: ""
    property var cfg_compactAppletIdDefault: ""

    // Supplied by Plasma for embedded containments.
    property var cfg_expanding
    property var cfg_length

    readonly property string ownPluginId: "com.acomagu.widgetgroup"

    function sameStringList(left, right): bool {
        if (!left || !right || left.length !== right.length) {
            return false;
        }
        for (let index = 0; index < left.length; ++index) {
            if (String(left[index]) !== String(right[index])) {
                return false;
            }
        }
        return true;
    }

    function rebuildAppletModel(): void {
        const applets = Array.from(Plasmoid.applets ?? []);
        const byId = {};
        for (const applet of applets) {
            byId[String(applet.id)] = applet;
        }

        const ordered = [];
        const seen = {};
        for (const configuredId of cfg_widgetOrder ?? []) {
            const id = String(configuredId);
            if (byId[id] && !seen[id]) {
                ordered.push(byId[id]);
                seen[id] = true;
            }
        }
        for (const applet of applets) {
            const id = String(applet.id);
            if (!seen[id]) {
                ordered.push(applet);
                seen[id] = true;
            }
        }

        appletModel.clear();
        for (const applet of ordered) {
            appletModel.append({
                "appletId": String(applet.id),
                "appletObject": applet,
                "appletTitle": applet.title,
                "appletIcon": applet.icon
            });
        }

        writeOrder();
    }

    function writeOrder(): void {
        const ids = [];
        for (let index = 0; index < appletModel.count; ++index) {
            ids.push(appletModel.get(index).appletId);
        }
        if (!sameStringList(ids, cfg_widgetOrder)) {
            cfg_widgetOrder = ids;
        }
        if (!ids.includes(cfg_compactAppletId)) {
            cfg_compactAppletId = ids.length > 0 ? ids[0] : "";
        }
    }

    function moveApplet(from: int, to: int): void {
        if (from < 0 || to < 0 || from >= appletModel.count || to >= appletModel.count) {
            return;
        }
        appletModel.move(from, to, 1);
        writeOrder();
    }

    Component.onCompleted: Qt.callLater(rebuildAppletModel)
    onCfg_widgetOrderChanged: Qt.callLater(rebuildAppletModel)

    Connections {
        target: Plasmoid

        function onAppletsChanged(): void {
            Qt.callLater(root.rebuildAppletModel);
        }
    }

    PlasmaPrivate.WidgetExplorer {
        id: widgetExplorer

        containment: Plasmoid
        showSpecialFilters: false
    }

    ListModel {
        id: appletModel
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.largeSpacing

        Kirigami.Heading {
            Layout.fillWidth: true
            level: 3
            text: i18nc("@title", "Widgets in this group")
        }

        RowLayout {
            Layout.fillWidth: true

            PlasmaComponents3.ComboBox {
                id: widgetChooser

                Layout.fillWidth: true
                model: widgetExplorer.widgetsModel
                textRole: "name"
                valueRole: "pluginName"
            }

            PlasmaComponents3.Button {
                text: i18nc("@action:button", "Add")
                icon.name: "list-add"
                enabled: Boolean(widgetChooser.currentValue)
                    && widgetChooser.currentValue !== root.ownPluginId

                onClicked: {
                    widgetExplorer.addApplet(widgetChooser.currentValue);
                    root.configurationChanged();
                }
            }
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            visible: widgetChooser.currentValue === root.ownPluginId
            type: Kirigami.MessageType.Warning
            text: i18nc("@info", "A Panel Widget Group cannot contain itself.")
        }

        PlasmaComponents3.ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: appletList

                model: appletModel
                spacing: Kirigami.Units.smallSpacing
                clip: true

                delegate: PlasmaComponents3.ItemDelegate {
                    id: delegate

                    required property int index
                    required property string appletId
                    required property var appletObject
                    required property string appletTitle
                    required property string appletIcon

                    width: ListView.view.width

                    contentItem: RowLayout {
                        spacing: Kirigami.Units.smallSpacing

                        PlasmaComponents3.RadioButton {
                            checked: root.cfg_compactAppletId === delegate.appletId
                            text: i18nc("@option:radio", "Compact")

                            onToggled: {
                                if (checked) {
                                    root.cfg_compactAppletId = delegate.appletId;
                                }
                            }
                        }

                        Kirigami.Icon {
                            source: delegate.appletIcon || "plasma"
                            implicitWidth: Kirigami.Units.iconSizes.smallMedium
                            implicitHeight: implicitWidth
                        }

                        PlasmaComponents3.Label {
                            Layout.fillWidth: true
                            text: delegate.appletTitle
                            elide: Text.ElideRight
                        }

                        PlasmaComponents3.ToolButton {
                            icon.name: "go-up-symbolic"
                            text: i18nc("@action:button", "Move up")
                            display: PlasmaComponents3.AbstractButton.IconOnly
                            enabled: delegate.index > 0

                            onClicked: root.moveApplet(delegate.index, delegate.index - 1)

                            PlasmaComponents3.ToolTip {
                                text: i18nc("@action:button", "Move up")
                            }
                        }

                        PlasmaComponents3.ToolButton {
                            icon.name: "go-down-symbolic"
                            text: i18nc("@action:button", "Move down")
                            display: PlasmaComponents3.AbstractButton.IconOnly
                            enabled: delegate.index < appletModel.count - 1

                            onClicked: root.moveApplet(delegate.index, delegate.index + 1)

                            PlasmaComponents3.ToolTip {
                                text: i18nc("@action:button", "Move down")
                            }
                        }

                        PlasmaComponents3.ToolButton {
                            readonly property var configureAction: delegate.appletObject?.internalAction("configure") ?? null

                            icon.name: "configure"
                            text: i18nc("@action:button", "Configure widget")
                            display: PlasmaComponents3.AbstractButton.IconOnly
                            visible: configureAction !== null && configureAction.visible
                            enabled: configureAction !== null && configureAction.enabled

                            onClicked: configureAction.trigger()

                            PlasmaComponents3.ToolTip {
                                text: i18nc("@action:button", "Configure widget")
                            }
                        }

                        PlasmaComponents3.ToolButton {
                            readonly property var removeAction: delegate.appletObject?.internalAction("remove") ?? null

                            icon.name: "edit-delete-remove"
                            text: i18nc("@action:button", "Remove widget")
                            display: PlasmaComponents3.AbstractButton.IconOnly
                            visible: removeAction !== null && removeAction.visible
                            enabled: removeAction !== null && removeAction.enabled

                            onClicked: {
                                removeAction.trigger();
                                root.configurationChanged();
                            }

                            PlasmaComponents3.ToolTip {
                                text: i18nc("@action:button", "Remove widget")
                            }
                        }
                    }
                }
            }
        }
    }
}
