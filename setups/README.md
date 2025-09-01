# setups/

this folder is a collection of helper scripts that fix common problems on fresh installs.
each script is idempotent.

- **enable-corepack.zsh** .. enable corepack and activate pnpm
- **enable-mac-like-screenshots.zsh** .. mac style screenshot tool with selection, clipboard copy, save, and swappy annotation
- **enable-screen-share.zsh** .. wayland blocks screen share on google meet, this fixes it
- **fix-bluetooth.zsh** .. reset and harden bluetooth stack, patch bluez config, disable autosuspend, watchdog wifi, restart services
- **fix-time.zsh** .. interactive timezone and ntp setup with fzf, sets correct region pool and forces sync
- **fix-voaster-sink.zsh** .. make vocaster one the default pulseaudio or pipewire sink and move streams
- **activate-mic.zsh** .. sometimes the audio fucks up
- **fix-wifi-firmware-patch.zsh** .. patch intel wifi (iwlwifi jf b0) firmware from kernel.org and reload stack
- **fix-zsh.zsh** .. reinstall oh my zsh cleanly with plugins (autosuggestions, syntax highlighting, completions)
- **gtk-shutp.zsh** .. silence gtk cursor theme warnings by setting up a proper default cursor theme
- **install-hyprland-qtutils.zsh** .. build and install hyprland qtutils from source if not already up to date
- **rust-analyzer-install.zsh** .. install rust analyzer via rustup component
- **setup-cliphist.zsh** .. configure cliphist with pruning, watchers, and fzf or wofi pickers, integrates with hyprland binds
- **setup-droid.zsh** .. install waydroid, set up whatsapp inside it, and create a desktop launcher
- **setup-notify-battery.zsh** .. systemd timer to notify on low battery since i don't use top bars, configurable thresholds, test mode included
- **setup-notify-heat.zsh** .. systemd timer to notify on high cpu temps

