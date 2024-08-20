Script to run Steam in Deck mode. Design for using Hyprland in Arch Linux w/ Nvidia graphic card.

## Usage

* Place `steam.sh` under ~/.local/bin
* Place `Steam Deck.desktop` under ~/.local/share/applications
* Edit ~/.local/share/applications/Steam Deck.desktop, replace `path/to/steam.sh` to `/home/<your username>/.local/bin/steam.sh`
* Edit `~/.local/bin/steam.sh`, replace `SCREEN_WIDTH`, `SCREEN_HEIGHT`, `OUTPUT_DEVICE`
* Install packages:

```bash
paru -S mangohud-git lib32-mangohud-git gamescope-nvidia-git
```

* Add mungohud config

```bash
mkdir -p ~/.config/MangoHud/MangoHud.conf
echo "full" > ~/.config/MangoHud/MangoHud.conf
```
