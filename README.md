# Panel Widget Group

A KDE Plasma 6 widget that combines multiple widgets into one panel item.

One child widget is used for the panel representation. Clicking it opens a popup
containing the full representations of all child widgets in the configured
order.

## Requirements

- KDE Plasma 6

## Install

```sh
kpackagetool6 --type Plasma/Applet --install .
```

To update an existing installation:

```sh
kpackagetool6 --type Plasma/Applet --upgrade .
```

The plugin ID is `com.acomagu.panelwidgetgroup`.
