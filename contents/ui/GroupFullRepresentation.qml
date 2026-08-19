// SPDX-License-Identifier: MIT

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

Item {
    id: root

    required property var appletItems
    required property bool active
    required property rect availableScreenRect

    signal closeRequested

    readonly property real maximumPopupWidth: Math.max(
        Kirigami.Units.gridUnit * 18,
        availableScreenRect.width * 0.85
    )
    readonly property real maximumPopupHeight: Math.max(
        Kirigami.Units.gridUnit * 16,
        availableScreenRect.height * 0.85
    )
    readonly property real childMinimumWidth: {
        let result = 0;
        for (let index = 0; index < hostRepeater.count; ++index) {
            const host = hostRepeater.itemAt(index) as AppletFullHost;
            if (host) {
                result = Math.max(result, host.minimumContentWidth);
            }
        }
        return result;
    }
    readonly property real effectiveMinimumWidth: childMinimumWidth > 0
        ? childMinimumWidth
        : Kirigami.Units.gridUnit * 18

    Layout.minimumWidth: Math.min(effectiveMinimumWidth, maximumPopupWidth)
    Layout.minimumHeight: Math.min(contentLayout.implicitHeight, maximumPopupHeight)
    Layout.maximumWidth: maximumPopupWidth
    Layout.maximumHeight: maximumPopupHeight

    implicitWidth: Math.min(
        Math.max(Kirigami.Units.gridUnit * 18, contentLayout.implicitWidth),
        maximumPopupWidth
    )
    implicitHeight: Math.min(
        Math.max(Kirigami.Units.gridUnit * 12, contentLayout.implicitHeight),
        maximumPopupHeight
    )

    Keys.onEscapePressed: root.closeRequested()

    QQC2.ScrollView {
        id: scrollView

        anchors.fill: parent
        clip: true
        contentWidth: availableWidth
        contentHeight: contentLayout.implicitHeight

        ColumnLayout {
            id: contentLayout

            width: scrollView.contentWidth
            spacing: Kirigami.Units.largeSpacing

            Repeater {
                id: hostRepeater

                model: root.appletItems

                delegate: AppletFullHost {
                    required property int index
                    required property Item modelData

                    appletItem: modelData
                    active: root.active
                    separatorVisible: index > 0
                }
            }
        }
    }
}
