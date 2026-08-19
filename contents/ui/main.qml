// SPDX-License-Identifier: MIT

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

ContainmentItem {
    id: root

    property var orderedApplets: []
    property var orderedItems: []
    property Item compactItem: null
    property bool popupOpen: false

    readonly property var configuredOrder: Plasmoid.configuration.widgetOrder
    readonly property string configuredCompactAppletId: Plasmoid.configuration.compactAppletId

    Plasmoid.icon: "view-grid-symbolic"
    Plasmoid.title: i18nc("@title", "Panel Widget Group")

    Layout.minimumWidth: compactItem
        ? validMinimum(compactItem.Layout.minimumWidth, Kirigami.Units.gridUnit * 3)
        : Kirigami.Units.gridUnit * 3
    Layout.minimumHeight: compactItem
        ? validMinimum(compactItem.Layout.minimumHeight, Kirigami.Units.gridUnit)
        : Kirigami.Units.gridUnit
    Layout.preferredWidth: compactItem
        ? validPreferred(compactItem.Layout.preferredWidth, compactItem.implicitWidth, Layout.minimumWidth)
        : Kirigami.Units.gridUnit * 6
    Layout.preferredHeight: compactItem
        ? validPreferred(compactItem.Layout.preferredHeight, compactItem.implicitHeight, Layout.minimumHeight)
        : Kirigami.Units.gridUnit * 2
    Layout.maximumWidth: compactItem
        ? validMaximum(compactItem.Layout.maximumWidth)
        : Infinity
    Layout.maximumHeight: compactItem
        ? validMaximum(compactItem.Layout.maximumHeight)
        : Infinity
    Layout.fillWidth: compactItem?.Layout.fillWidth ?? false
    Layout.fillHeight: compactItem?.Layout.fillHeight ?? false

    implicitWidth: Layout.preferredWidth
    implicitHeight: Layout.preferredHeight

    function validMinimum(value: real, fallback: real): real {
        return value > 0 && Number.isFinite(value) ? value : fallback;
    }

    function validPreferred(value: real, implicitValue: real, fallback: real): real {
        if (value > 0 && Number.isFinite(value)) {
            return value;
        }
        if (implicitValue > 0 && Number.isFinite(implicitValue)) {
            return implicitValue;
        }
        return fallback;
    }

    function validMaximum(value: real): real {
        return value > 0 ? value : Infinity;
    }

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

    function orderedAppletList(): var {
        const applets = Array.from(Plasmoid.applets ?? []);
        const appletsById = {};
        for (const applet of applets) {
            appletsById[String(applet.id)] = applet;
        }

        const result = [];
        const seen = {};
        for (const configuredId of configuredOrder ?? []) {
            const id = String(configuredId);
            if (appletsById[id] && !seen[id]) {
                result.push(appletsById[id]);
                seen[id] = true;
            }
        }

        for (const applet of applets) {
            const id = String(applet.id);
            if (!seen[id]) {
                result.push(applet);
                seen[id] = true;
            }
        }
        return result;
    }

    function rebuildAppletItems(): void {
        const applets = orderedAppletList();
        const items = [];
        for (const applet of applets) {
            const item = root.itemFor(applet);
            if (item) {
                items.push(item);
            }
        }

        root.orderedApplets = applets;
        root.orderedItems = items;

        const ids = applets.map(applet => String(applet.id));
        if (!sameStringList(ids, configuredOrder)) {
            Plasmoid.configuration.widgetOrder = ids;
        }

        let compactId = configuredCompactAppletId;
        if (!ids.includes(compactId)) {
            compactId = ids.length > 0 ? ids[0] : "";
            Plasmoid.configuration.compactAppletId = compactId;
        }

        root.compactItem = null;
        for (let index = 0; index < applets.length; ++index) {
            const item = root.itemFor(applets[index]);
            if (!item) {
                continue;
            }

            item.expanded = false;
            if (item.compactRepresentation !== null) {
                item.preferredRepresentation = item.compactRepresentation;
            }
            item.anchors.fill = null;
            if (String(applets[index].id) === compactId) {
                item.parent = compactHost;
                item.anchors.fill = compactHost;
                item.visible = true;
                root.compactItem = item;
            } else {
                item.parent = hiddenStorage;
                item.visible = false;
            }
        }
    }

    Component.onCompleted: rebuildAppletItems()

    onConfiguredOrderChanged: Qt.callLater(rebuildAppletItems)
    onConfiguredCompactAppletIdChanged: Qt.callLater(rebuildAppletItems)

    Connections {
        target: Plasmoid

        function onAppletsChanged(): void {
            Qt.callLater(root.rebuildAppletItems);
        }

        function onActivated(): void {
            root.popupOpen = !root.popupOpen;
        }
    }

    Item {
        id: hiddenStorage

        visible: false
        width: 0
        height: 0
    }

    Item {
        id: compactHost

        anchors.fill: parent

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            enabled: root.compactItem !== null
            z: 1000

            onClicked: root.popupOpen = !root.popupOpen
        }
    }

    PlasmaCore.AppletPopup {
        id: popup

        visualParent: compactHost
        appletInterface: root
        hideOnWindowDeactivate: true
        visible: root.popupOpen && root.orderedItems.length > 0

        function fitHeightToContent(): void {
            if (!visible || !fullRepresentation || fullRepresentation.implicitHeight <= 0) {
                return;
            }
            height = Math.ceil(fullRepresentation.implicitHeight + topPadding + bottomPadding);
        }

        popupDirection: switch (Plasmoid.location) {
        case PlasmaCore.Types.TopEdge:
            return Qt.BottomEdge;
        case PlasmaCore.Types.LeftEdge:
            return Qt.RightEdge;
        case PlasmaCore.Types.RightEdge:
            return Qt.LeftEdge;
        default:
            return Qt.TopEdge;
        }

        onVisibleChanged: {
            if (!visible) {
                root.popupOpen = false;
                Qt.callLater(root.rebuildAppletItems);
            } else {
                Qt.callLater(fitHeightToContent);
            }
        }

        mainItem: GroupFullRepresentation {
            id: fullRepresentation

            appletItems: root.orderedItems
            active: popup.visible
            availableScreenRect: root.availableScreenRect

            onImplicitHeightChanged: Qt.callLater(popup.fitHeightToContent)
            onCloseRequested: root.popupOpen = false
        }
    }
}
