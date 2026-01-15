#!/bin/bash

set -eu

. ./lib.sh

PROGNAME=$(basename "$0")
ARCH=$(uname -m)
IMAGES="base server xfce bspwm kde river"
TRIPLET=
REPO=
DATE=$(date -u +%Y%m%d)

usage() {
	cat <<-EOH
	Usage: $PROGNAME [options ...] [-- mklive options ...]

	Wrapper script around mklive.sh for several standard flavors of live images.
	Adds void-installer and other helpful utilities to the generated images.
        
	create by Gh0sT4n(https://github.com/gh0st4n) 

	OPTIONS
	 -a <arch>     Set architecture (or platform) in the image
	 -b <variant>  One of base, server, bspwm, xfce, river or kde. 
               May be specified multiple times to build multiple variants.
	 -d <date>     Override the datestamp on the generated image (YYYYMMDD format)
	 -t <arch-date-variant>
	               Equivalent to setting -a, -b, and -d
	 -r <repo>     Use this XBPS repository. May be specified multiple times
	 -h            Show this help and exit
	 -V            Show version and exit

	Other options can be passed directly to mklive.sh by specifying them after the --.
	See mklive.sh -h for more details.
	EOH
}

while getopts "a:b:d:t:hr:V" opt; do
case $opt in
    a) ARCH="$OPTARG";;
    b) IMAGES="$OPTARG";;
    d) DATE="$OPTARG";;
    r) REPO="-r $OPTARG $REPO";;
    t) TRIPLET="$OPTARG";;
    V) version; exit 0;;
    h) usage; exit 0;;
    *) usage >&2; exit 1;;
esac
done
shift $((OPTIND - 1))

INCLUDEDIR=$(mktemp -d)
trap "cleanup" INT TERM

cleanup() {
    rm -rf "$INCLUDEDIR"
}

include_installer() {
    if [ -x installer.sh ]; then
        MKLIVE_VERSION="$(PROGNAME='' version)"
        installer=$(mktemp)
        sed "s/@@MKLIVE_VERSION@@/${MKLIVE_VERSION}/" installer.sh > "$installer"
        install -Dm755 "$installer" "$INCLUDEDIR"/usr/bin/void-installer
        rm "$installer"
    else
        echo installer.sh not found >&2
        exit 1
    fi
}

setup_pipewire() {
    PKGS="$PKGS pipewire alsa-pipewire"
    case "$ARCH" in
        asahi*)
            PKGS="$PKGS asahi-audio"
            SERVICES="$SERVICES speakersafetyd"
            ;;
    esac
    mkdir -p "$INCLUDEDIR"/etc/xdg/autostart
    ln -sf /usr/share/applications/pipewire.desktop "$INCLUDEDIR"/etc/xdg/autostart/
    mkdir -p "$INCLUDEDIR"/etc/pipewire/pipewire.conf.d
    ln -sf /usr/share/examples/wireplumber/10-wireplumber.conf "$INCLUDEDIR"/etc/pipewire/pipewire.conf.d/
    ln -sf /usr/share/examples/pipewire/20-pipewire-pulse.conf "$INCLUDEDIR"/etc/pipewire/pipewire.conf.d/
    mkdir -p "$INCLUDEDIR"/etc/alsa/conf.d
    ln -sf /usr/share/alsa/alsa.conf.d/50-pipewire.conf "$INCLUDEDIR"/etc/alsa/conf.d
    ln -sf /usr/share/alsa/alsa.conf.d/99-pipewire-default.conf "$INCLUDEDIR"/etc/alsa/conf.d
}

include_common_cli() {
    cp ./common/os-release "$INCLUDEDIR"/etc/
    cp ./common/grub "$INCLUDEDIR"/etc/default/
}

include_common_gui() {
    mkdir -p "$INCLUDEDIR"/boot/grub/themes
    mkdir -p "$INCLUDEDIR"/etc
    mkdir -p "$INCLUDEDIR"/etc/skel/.config
    mkdir -p "$INCLUDEDIR"/usr/share/plymouth
	mkdir -p "$INCLUDEDIR"/usr/share/polkit-1/rules.d

	cp -r ./common/t4n-grub-theme "$INCLUDEDIR"/boot/grub/themes/
    cp -r ./common/t4n "$INCLUDEDIR"/usr/share/plymouth/themes/
	cp -r ./common/t4n-spinner "$INCLUDEDIR"/usr/share/plymouth/themes/
	cp -r ./common/config/* "$INCLUDEDIR"/etc/skel/.config/
	cp -r ./common/Wallpaper "$INCLUDEDIR"/etc/skel/
	cp -r ./common/Wallpaper "$INCLUDEDIR"/usr/share/

    cp ./common/os-release "$INCLUDEDIR"/etc/
    cp ./common/grub "$INCLUDEDIR"/etc/default/
	cp ./common/T4n-OS.png "$INCLUDEDIR"/usr/share/pixmaps/
	cp ./common/splash.png "$INCLUDEDIR"/usr/share/void-artwork/
	cp ./common/.bashrc "$INCLUDEDIR"/etc/skel/
	cp ./common/.Xresources "$INCLUDEDIR"/etc/skel/
}

include_polybar() {
    PKGS="$PKGS polybar cbatticon network-manager-applet redshift-gtk volumeicon"
	mkdir -p "$INCLUDEDIR"/etc/skel/.config
	mkdir -p "$INCLUDEDIR"/etc/skel/.local/share
	cp -r ./common/polybar "$INCLUDEDIR"/etc/skel/.config/
	cp -r ./common/fonts "$INCLUDEDIR"/etc/skel/.local/share/
}
include_rofi() {
    PKGS="$PKGS rofi"
	mkdir -p "$INCLUDEDIR"/etc/skel/.config
	mkdir -p "$INCLUDEDIR"/usr/bin
	cp -r ./common/rofi_c/rofi "$INCLUDEDIR"/etc/skel/.config
	cp ./common/rofi_c/rofi-power-menu "$INCLUDEDIR"/usr/bin/
}


include_wofi() {
    PKGS="$PKGS wofi"
	mkdir -p "$INCLUDEDIR"/etc/skel/.config
	mkdir -p "$INCLUDEDIR"/usr/bin
	cp -r ./common/wofi_c/wofi "$INCLUDEDIR"/etc/skel/.config
	cp ./common/wofi_c/wofi-power-menu "$INCLUDEDIR"/usr/bin/
}


include_way() {
    PKGS="$PKGS cliphist network-manager-applet nwg-look nwg-launchers pavucontrol SwayNotificationCenter Waybar wlsunset xorg-server-xwayland xwayland-satellite"
	cp ./common/wswap-way "$INCLUDEDIR"/usr/bin/
	mkdir -p "$INCLUDEDIR"/etc/skel/.config
	cp -r ./common/waybar "$INCLUDEDIR"/etc/skel/.config/
}
include_x11() {
    PKGS="$PKGS dunst redshift scrot slock st transset xautolock xcompmgr"
	cp ./common/wswap-X "$INCLUDEDIR"/usr/bin/
}

include_base
include_server

include_xfce() {
	mkdir -p "$INCLUDEDIR"/usr/share/backgrounds/xfce
	cp ./common/Wallpaper/background3.png "$INCLUDEDIR"/usr/share/backgrounds/xfce/
}

include_bspwm
include_kde

include_river() {
	mkdir -p "$INCLUDEDIR"/usr/bin
	cp ./common/screenlock "$INCLUDEDIR"/usr/bin/
}

build_variant() {
    variant="$1"
    shift
    IMG=t4n_os-live-${ARCH}-${DATE}-${variant}.iso

    # el-cheapo installer is unsupported on arm because arm doesn't install a kernel by default
    # and to work around that would add too much complexity to it
    # thus everyone should just do a chroot install anyways
    WANT_INSTALLER=no
    case "$ARCH" in
        x86_64*|i686*)
            GRUB_PKGS="grub-i386-efi grub-x86_64-efi"
            GFX_PKGS="xorg-video-drivers xf86-video-intel"
            GFX_WL_PKGS="mesa-dri"
            WANT_INSTALLER=yes
            TARGET_ARCH="$ARCH"
            ;;
        aarch64*)
            GRUB_PKGS="grub-arm64-efi"
            GFX_PKGS="xorg-video-drivers"
            GFX_WL_PKGS="mesa-dri"
            TARGET_ARCH="$ARCH"
            ;;
        asahi*)
            GRUB_PKGS="asahi-base asahi-scripts grub-arm64-efi"
            GFX_PKGS="mesa-asahi-dri"
            GFX_WL_PKGS="mesa-asahi-dri"
            KERNEL_PKG="linux-asahi"
            TARGET_ARCH="aarch64${ARCH#asahi}"
            if [ "$variant" = xfce ]; then
                info_msg "xfce is not supported on asahi, switching to xfce-wayland"
                variant="xfce-wayland"
            fi
            ;;
    esac

    A11Y_PKGS="espeakup void-live-audio brltty"
    PKGS="dialog cryptsetup lvm2 mdadm void-docs-browse xtools-minimal xmirror chrony tmux $A11Y_PKGS $GRUB_PKGS"
    FONTS="font-misc-misc terminus-font dejavu-fonts-ttf"
    WAYLAND_PKGS="$GFX_WL_PKGS $FONTS orca"
    XORG_PKGS="$GFX_PKGS $FONTS xorg-minimal xorg-input-drivers setxkbmap xauth orca"
    SERVICES="sshd chronyd"

    LIGHTDM_SESSION=''

    case $variant in
        base)
            SERVICES="$SERVICES dbus NetworkManager"
        ;;
        server)
            # SERVICES="$SERVICES dhcpcd wpa_supplicant acpid"
            echo "on Going"
        ;;
        enlightenment)
            PKGS="$PKGS $XORG_PKGS lightdm lightdm-gtk-greeter enlightenment terminology udisks2 firefox"
            SERVICES="$SERVICES acpid dhcpcd wpa_supplicant lightdm dbus polkitd"
            LIGHTDM_SESSION=enlightenment
        ;;
        xfce)
            # PKGS="$PKGS $XORG_PKGS lightdm lightdm-gtk-greeter xfce4 gnome-themes-standard gnome-keyring network-manager-applet gvfs-afc gvfs-mtp gvfs-smb udisks2 firefox xfce4-pulseaudio-plugin"
            # SERVICES="$SERVICES dbus lightdm NetworkManager polkitd"
            # LIGHTDM_SESSION=xfce
            #
            # if [ "$variant" == "xfce-wayland" ]; then
            #     PKGS="$PKGS $WAYLAND_PKGS labwc"
            #     LIGHTDM_SESSION="xfce-wayland"
            # fi

            #COMMON=yes
            #X11=yes
            #XFCE=yes
            # Paket sangat minimal untuk XFCE
            #PKGS="$PKGS $XORG_PKGS $CALAMARES_MINIMAL xfce4 xfce4-terminal mousepad ristretto"
            #SERVICES="$SERVICES dbus elogind sddm NetworkManager polkitd"
            echo "on Going"
        ;;
        bspwm)
            # PKGS="$PKGS $XORG_PKGS lightdm lightdm-gtk-greeter mate mate-extra gnome-keyring network-manager-applet gvfs-afc gvfs-mtp gvfs-smb udisks2 firefox"
            # SERVICES="$SERVICES dbus lightdm NetworkManager polkitd"
            # LIGHTDM_SESSION=mate

            #COMMON=yes
            #X11=yes
            #DMENU=yes  # hanya dmenu, tanpa rofi/polybar
            # Paket dasar untuk bspwm
            #PKGS="$PKGS $XORG_PKGS $D77_CORE_MINIMAL bspwm sxhkd dmenu st"
            #SERVICES="$SERVICES dbus elogind sddm NetworkManager polkitd"
        ;;
        kde)
            # PKGS="$PKGS $XORG_PKGS kde5 konsole firefox dolphin NetworkManager"
            # SERVICES="$SERVICES dbus NetworkManager sddm"
            echo "on Going"
        ;;
        river)
            # PKGS="$PKGS $XORG_PKGS river lightdm lightdm-gtk-greeter gvfs-afc gvfs-mtp gvfs-smb udisks2 firefox"
            # SERVICES="$SERVICES acpid dbus dhcpcd wpa_supplicant lightdm polkitd"
            # LIGHTDM_SESSION=LXDE

            #COMMON=yes
            #RIVER=yes
            #WAY=yes
            #FUZZEL=yes
            # Paket dasar Wayland + river
            #PKGS="$PKGS $XORG_PKGS $WAYLAND_PKGS $D77_CORE_MINIMAL river fuzzel foot"
            #SERVICES="$SERVICES dbus elogind sddm NetworkManager polkitd"
            echo "on Going"
        ;;
        *)
            >&2 echo "Unknown variant $variant"
            exit 1
        ;;
    esac

    if [ -n "$LIGHTDM_SESSION" ]; then
        mkdir -p "$INCLUDEDIR"/etc/lightdm
        echo "$LIGHTDM_SESSION" > "$INCLUDEDIR"/etc/lightdm/.session
        # needed to show the keyboard layout menu on the login screen
        cat <<- EOF > "$INCLUDEDIR"/etc/lightdm/lightdm-gtk-greeter.conf
[greeter]
indicators = ~host;~spacer;~clock;~spacer;~layout;~session;~a11y;~power
EOF
    fi

    if [ "$WANT_INSTALLER" = yes ]; then
        include_installer
    else
        mkdir -p "$INCLUDEDIR"/usr/bin
        printf "#!/bin/sh\necho 'void-installer is not supported on this live image'\n" > "$INCLUDEDIR"/usr/bin/void-installer
        chmod 755 "$INCLUDEDIR"/usr/bin/void-installer
    fi

    if [ "$variant" != base ]; then
        setup_pipewire
    fi

    ./mklive.sh -a "$TARGET_ARCH" -o "$IMG" -p "$PKGS" -S "$SERVICES" -I "$INCLUDEDIR" \
        ${KERNEL_PKG:+-v $KERNEL_PKG} ${REPO} "$@"

	cleanup
}

if [ ! -x mklive.sh ]; then
    echo mklive.sh not found >&2
    exit 1
fi

if [ -n "$TRIPLET" ]; then
    IFS=: read -r ARCH DATE VARIANT _ < <( echo "$TRIPLET" | sed -Ee 's/^(.+)-([0-9rc]+)-(.+)$/\1:\2:\3/' )
    build_variant "$VARIANT" "$@"
else
    for image in $IMAGES; do
        build_variant "$image" "$@"
    done
fi
