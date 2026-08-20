pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.controls
import qs.services
import qs.utils

Column {
    id: root

    required property ScreenState screenState

   function focusEntry(index: int): bool {
        const entry = repeater.itemAt(index);

        if (!entry?.isButton)
            return false;

        entry.item.forceActiveFocus();
        return true;
    }

    function focusAdjacent(from: int, step: int): bool {
        for (let i = from + step; i >= 0 && i < repeater.count; i += step)
            if (focusEntry(i))
                return true;

        return false;
    }

    function focusFirst(): void {
        focusAdjacent(-1, 1);
    }

    padding: Tokens.padding.large
    rightPadding: CUtils.clamp(padding - Config.border.thickness, 0, padding)
    spacing: Tokens.spacing.large

    Component.onCompleted: focusFirst()

    Connections {
        function onLauncherChanged(): void {
            if (!root.screenState.launcher)
                root.focusFirst();
        }

        target: root.screenState
    }

    Repeater {
        id: repeater

        model: Config.session.order

        Loader {
            id: entry

            required property int index
            required property string modelData

            readonly property bool isGif: modelData === "gif"
            readonly property bool isButton: !isGif && Config.session.icons[modelData] !== undefined

            active: isGif || isButton
            sourceComponent: isGif ? gif : button

            Component {
                id: gif

                // AnimatedImage takes its implicit size from the source and does not
                // allow overriding it, so a wrapper carries the size the Loader measures
                Item {
                    implicitWidth: Tokens.sizes.session.button
                    implicitHeight: Tokens.sizes.session.button

                    AnimatedImage {
                        anchors.fill: parent
                        sourceSize.width: width * ((QsWindow.window as QsWindow)?.devicePixelRatio ?? 1)

                        playing: visible
                        asynchronous: true
                        speed: Config.general.sessionGifSpeed
                        source: Paths.absolutePath(Config.paths.sessionGif)
                        fillMode: AnimatedImage.PreserveAspectFit
                    }
                }
            }

            Component {
                id: button

                SessionButton {
                    index: entry.index
                    icon: Config.session.icons[entry.modelData]
                    command: Config.session.commands[entry.modelData]
                }
            }
        }
    }

    component SessionButton: IconButton {
        id: button

        required property int index
        required property list<string> command

        function exec(): void {
            if (!SessionManager.exec(command))
                Quickshell.execDetached(command);
        }

        implicitWidth: Tokens.sizes.session.button
        implicitHeight: Tokens.sizes.session.button

        inactiveColour: activeFocus ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainer
        inactiveOnColour: activeFocus ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
        radius: pressed ? Tokens.rounding.medium : activeFocus ? Tokens.rounding.extraLarge : Tokens.rounding.largeIncreased
        font: Tokens.font.icon.builders.large.scale(1.3).build()
        onClicked: exec()

        Keys.onEnterPressed: exec()
        Keys.onReturnPressed: exec()
        Keys.onEscapePressed: root.screenState.session = false
        Keys.onUpPressed: event => event.accepted = root.focusAdjacent(index, -1)
        Keys.onDownPressed: event => event.accepted = root.focusAdjacent(index, 1)
        Keys.onPressed: event => {
            if (!Config.session.vimKeybinds)
                return;

            if (event.modifiers & Qt.ControlModifier) {
                if (event.key === Qt.Key_J || event.key === Qt.Key_N)
                    event.accepted = root.focusAdjacent(index, 1);
                else if (event.key === Qt.Key_K || event.key === Qt.Key_P)
                    event.accepted = root.focusAdjacent(index, -1);
            } else if (event.key === Qt.Key_Tab) {
                event.accepted = root.focusAdjacent(index, 1);
            } else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                event.accepted = root.focusAdjacent(index, -1);
            }
        }
    }
}
