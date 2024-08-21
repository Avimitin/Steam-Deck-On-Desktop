#!/bin/bash

SCREEN_WIDTH=3840
SCREEN_HEIGHT=2160
OUTPUT_DEVICE="*,DP-1"
CLIENTCMD="steam -gamepadui -steamos3 -steampal -steamdeck $@"
CURSOR_FILE="/usr/share/icons/Adwaita/cursors/arrow"

# if wpaperd is enabled
_WPAPERD_MANUALLY_CLOSED=0
if systemctl --user is-active wpaperd-hypr >/dev/null; then
  systemctl --user stop wpaperd-hypr
  _WPAPERD_MANUALLY_CLOSED=1
fi

_HYPRCTL_OFF=0
if command -v hyprctl >/dev/null; then
  hyprctl --batch "\
    keyword animations:enabled 0;
    keyword decoration:drop_shadow 0;
    keyword decoration:blur:enabled 0"
  _HYPRCTL_OFF=1
fi

export QT_QPA_PLATFORM=xcb
export ENABLE_GAMESCOPE_WSI=1
export SDL_VIDEO_MINIMIZE_ON_FOCUS_LOSS=0
export STEAM_GAMESCOPE_VRR_SUPPORTED=1

export STEAM_USE_DYNAMIC_VRS=1

# Support for gamescope tearing with GAMESCOPE_ALLOW_TEARING atom
export STEAM_GAMESCOPE_HAS_TEARING_SUPPORT=1

# Enable tearing controls in steam
export STEAM_GAMESCOPE_TEARING_SUPPORTED=1

export STEAM_GAMESCOPE_HDR_SUPPORTED=1

# Enable volume key management via steam for this session
export STEAM_ENABLE_VOLUME_HANDLER=1

# Have SteamRT's xdg-open send http:// and https:// URLs to Steam
export SRT_URLOPEN_PREFER_STEAM=1

# Disable automatic audio device switching in steam, now handled by wireplumber
export STEAM_DISABLE_AUDIO_DEVICE_SWITCHING=1

# We have NIS support
export STEAM_GAMESCOPE_NIS_SUPPORTED=1

# Scaling support
export STEAM_GAMESCOPE_FANCY_SCALING_SUPPORT=1

# Color management support
export STEAM_GAMESCOPE_COLOR_MANAGED=1
export STEAM_GAMESCOPE_VIRTUAL_WHITE=1

# There is no way to set a color space for an NV12
# buffer in Wayland. And the color management protocol that is
# meant to let this happen is missing the color range...
# So just workaround this with an ENV var that Remote Play Together
# and Gamescope will use for now.
export GAMESCOPE_NV12_COLORSPACE=k_EStreamColorspace_BT601

# Workaround older versions of vkd3d-proton setting this
# too low (desc.BufferCount), resulting in symptoms that are potentially like
# swapchain starvation.
export VKD3D_SWAPCHAIN_LATENCY_FRAMES=3

# Temporary crutch until dummy plane interactions / etc are figured out
export GAMESCOPE_DISABLE_ASYNC_FLIPS=1

# To expose vram info from radv
export WINEDLLOVERRIDES=dxgi=n

# Don't wait for buffers to idle on the client side before sending them to gamescope
export vk_xwayland_wait_ready=false

# Set input method modules for Qt/GTK that will show the Steam keyboard
export QT_IM_MODULE=steam
export GTK_IM_MODULE=Steam

# Workaround for steam getting killed immediatly during reboot
export STEAMOS_STEAM_REBOOT_SENTINEL="/tmp/steamos-reboot-sentinel"
export REBOOT_SENTINEL=$STEAMOS_STEAM_REBOOT_SENTINEL
# Workaround for steam getting killed immediatly during shutdown
# Same idea as reboot sentinel above
export STEAMOS_STEAM_SHUTDOWN_SENTINEL="/tmp/steamos-shutdown-sentinel"
export SHUTDOWN_SENTINEL=$STEAMOS_STEAM_SHUTDOWN_SENTINEL

# Enable Mangoapp
export STEAM_USE_MANGOAPP=1
#export MANGOHUD=1
export MANGOHUD_CONFIGFILE="$(mktemp -t "mangohud-cfg-XXX")"
# Use user configs
if [ -r $HOME/.config/MangoHud/MangoHud.conf ]; then
  cat $HOME/.config/MangoHud/MangoHud.conf > $MANGOHUD_CONFIGFILE
fi
# Steam will overwrite the config file, we must remove write permission here
chmod -w $MANGOHUD_CONFIGFILE
export MANGOHUD_CONFIG="read_cfg"

steamos-select-branch() {
  :
}

steamos-session-select() {
  steam -shutdown
}

export -f steamos-session-select steamos-select-branch

ulimit -n 524288

/usr/bin/gamescope \
  -W $SCREEN_WIDTH -H $SCREEN_HEIGHT \
  --hdr-enabled --hdr-itm-enable \
  --hide-cursor-delay 3000 --fade-out-duration 200 \
  --fullscreen \
  --default-touch-mode 4 \
  --mangoapp \
  --cursor $CURSOR_FILE \
  --xwayland-count 2 \
  --steam \
  -- \
  $CLIENTCMD

# Catch reboot and powerof sentinels here
if [[ -e "$REBOOT_SENTINEL" ]]; then
  rm -f "$REBOOT_SENTINEL"
  reboot
fi
if [[ -e "$SHUTDOWN_SENTINEL" ]]; then
  rm -f "$SHUTDOWN_SENTINEL"
  poweroff
fi

if (( $_HYPRCTL_OFF )); then
  hyprctl reload
fi
if (( $_WPAPERD_MANUALLY_CLOSED )); then
  systemd-run --user --unit wpaperd-hypr /usr/bin/wpaperd
fi
