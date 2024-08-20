#!/bin/bash

SCREEN_WIDTH=3840
SCREEN_HEIGHT=2160
OUTPUT_DEVICE="*,DP-1"
CLIENTCMD="steam -gamepadui -steamos3 -steampal -steamdeck $@"

_WPAPERD_MANUALLY_CLOSED=0
if systemctl --user is-active wpaperd-hypr >/dev/null; then
  systemctl --user stop wpaperd-hypr
  _WPAPERD_MANUALLY_CLOSED=1
fi

hyprctl --batch "\
  keyword animations:enabled 0;
  keyword decoration:drop_shadow 0;
  keyword decoration:blur:enabled 0"


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

# We have the Mesa integration for the fifo-based dynamic fps-limiter
export STEAM_GAMESCOPE_DYNAMIC_FPSLIMITER=1

# We have NIS support
export STEAM_GAMESCOPE_NIS_SUPPORTED=1

# Let steam know it can unmount drives without superuser privileges
export STEAM_ALLOW_DRIVE_UNMOUNT=1

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

# Enable Mangoapp
export STEAM_USE_MANGOAPP=1
#export MANGOHUD=1
export MANGOHUD_CONFIGFILE="$(mktemp -t "mangohud-cfg-XXX")"
cat $HOME/.config/MangoHud/MangoHud.conf > $MANGOHUD_CONFIGFILE
# Steam will overwrite the config file, we must remove write permission here
chmod -w $MANGOHUD_CONFIGFILE
export MANGOHUD_CONFIG="read_cfg"

ulimit -n 524288

/usr/bin/gamescope \
  -W $SCREEN_WIDTH -H $SCREEN_HEIGHT \
  --hdr-enabled --hdr-itm-enable \
  --hide-cursor-delay 3000 --fade-out-duration 200 \
  --fullscreen \
  --default-touch-mode 4 \
  --mangoapp \
  --steam \
  -- \
  $CLIENTCMD

hyprctl reload
if (( $_WPAPERD_MANUALLY_CLOSED )); then
  systemd-run --user --unit wpaperd-hypr /usr/bin/wpaperd
fi
