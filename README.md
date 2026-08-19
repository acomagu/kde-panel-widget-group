# Panel Widget Group

A KDE Plasma 6 widget that combines multiple widgets into one panel item.

<img width="468" height="446" alt="Image" src="https://github.com/user-attachments/assets/dbf21144-2ed4-4fe2-8f31-729798ace149" />

## Settings

<img width="506" height="394" alt="image" src="https://github.com/user-attachments/assets/769cd79c-d308-448d-8de4-db0c6c3db8fa" />

Open **Configure Panel Widget Group** from the widget's context menu.

- Select a widget and click **Add** to include it in the group.
- Select **Compact** for the widget to display in the panel.
- Use the arrow buttons to change the order in the popup.
- Use the configure and remove buttons to manage each widget.

## Install

### Nix

```sh
nix profile install github:acomagu/kde-panel-widget-group
```

### Other distributions

```sh
git clone https://github.com/acomagu/kde-panel-widget-group.git
cd kde-panel-widget-group
kpackagetool6 --type Plasma/Applet --install .
```

Then add **Panel Widget Group** from Plasma's widget explorer.
