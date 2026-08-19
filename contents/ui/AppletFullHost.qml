// SPDX-License-Identifier: MIT

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

ColumnLayout {
    id: root

    required property var appletItem
    required property bool active
    property bool separatorVisible: false

    readonly property bool hasSeparateFullRepresentation: appletItem.fullRepresentation !== null
    readonly property Item representation: hasSeparateFullRepresentation
        ? appletItem.fullRepresentationItem
        : appletItem
    readonly property real minimumContentWidth: representation
        ? validMinimum(representation.Layout.minimumWidth)
        : 0

    spacing: Kirigami.Units.largeSpacing

    Layout.fillWidth: true
    Layout.maximumWidth: Infinity

    function validMinimum(value: real): real {
        return value > 0 && Number.isFinite(value) ? value : 0;
    }

    function validPreferred(value: real, implicitValue: real): real {
        if (value > 0 && Number.isFinite(value)) {
            return value;
        }
        return Math.max(0, implicitValue);
    }

    function validMaximum(value: real): real {
        return value > 0 ? value : Infinity;
    }

    function attachRepresentation(): void {
        if (!root.active || !root.representation) {
            return;
        }

        root.representation.anchors.fill = null;
        root.representation.parent = representationHost;
        root.representation.anchors.fill = representationHost;
        root.representation.visible = true;
    }

    Component.onCompleted: {
        appletItem.preloadFullRepresentation = true;
        Qt.callLater(attachRepresentation);
    }

    onActiveChanged: {
        if (active) {
            appletItem.preloadFullRepresentation = true;
            Qt.callLater(attachRepresentation);
        } else if (representation) {
            representation.visible = false;
        }
    }

    onRepresentationChanged: Qt.callLater(attachRepresentation)

    Kirigami.Separator {
        Layout.fillWidth: true
        visible: root.separatorVisible
    }

    Item {
        id: representationHost

        Layout.minimumWidth: root.representation
            ? root.validMinimum(root.representation.Layout.minimumWidth)
            : 0
        Layout.minimumHeight: root.representation
            ? root.validMinimum(root.representation.Layout.minimumHeight)
            : 0
        Layout.preferredWidth: root.representation
            ? root.validPreferred(root.representation.Layout.preferredWidth, root.representation.implicitWidth)
            : 0
        Layout.preferredHeight: root.representation
            ? root.validPreferred(root.representation.Layout.preferredHeight, root.representation.implicitHeight)
            : 0
        Layout.maximumWidth: Infinity
        Layout.maximumHeight: root.representation
            ? root.validMaximum(root.representation.Layout.maximumHeight)
            : Infinity
        Layout.fillWidth: true
        Layout.fillHeight: root.representation?.Layout.fillHeight ?? false
    }

    Connections {
        target: root.appletItem

        function onFullRepresentationItemChanged(): void {
            Qt.callLater(root.attachRepresentation);
        }
    }

    Connections {
        target: root.representation

        function onParentChanged(): void {
            if (root.active && root.representation.parent !== representationHost) {
                Qt.callLater(root.attachRepresentation);
            }
        }

        function onVisibleChanged(): void {
            if (root.active && !root.representation.visible) {
                root.representation.visible = true;
            }
        }
    }

    Timer {
        interval: 250
        repeat: true
        running: root.active

        onTriggered: {
            if (root.representation
                    && (root.representation.parent !== representationHost
                        || !root.representation.visible)) {
                root.attachRepresentation();
            }
        }
    }
}
