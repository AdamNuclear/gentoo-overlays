# Copyright 2025-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cargo desktop xdg-utils

DESCRIPTION="Linux software for Elgato Stream Deck with support for original plugins"
HOMEPAGE="https://github.com/nekename/OpenDeck"
SRC_URI="https://github.com/nekename/OpenDeck/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

S="${WORKDIR}/OpenDeck-${PV}"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64"
IUSE="wayland"

# network-sandbox is required because:
# - cargo fetches crates during build
# - deno installs JS dependencies during build
RESTRICT="network-sandbox"

RDEPEND="
	dev-libs/glib:2
	dev-libs/openssl:=
	media-libs/fontconfig
	media-libs/freetype
	net-libs/libsoup:3.0
	net-libs/webkit-gtk:4.1
	sys-apps/dbus
	virtual/udev
	x11-libs/cairo
	x11-libs/gdk-pixbuf:2
	x11-libs/gtk+:3
	x11-libs/pango
	wayland? ( dev-libs/wayland )
"
DEPEND="${RDEPEND}"
BDEPEND="
	virtual/pkgconfig
	|| ( dev-lang/rust-bin dev-lang/rust )
	dev-lang/deno-bin
	net-misc/curl
"

QA_FLAGS_IGNORED="usr/bin/opendeck"



src_prepare() {
	default
}

src_compile() {
	export CARGO_HOME="${WORKDIR}/cargo-home"
	export DENO_DIR="${WORKDIR}/deno-dir"

	# Install JS dependencies
	deno install || die "deno install failed"

	# Build the Tauri application (skip bundling, we only need the binary)
	deno task tauri build --no-bundle || die "tauri build failed"
}

src_install() {
	# Install the binary
	dobin "src-tauri/target/release/opendeck"

	# Install desktop file
	make_desktop_entry opendeck "OpenDeck" opendeck "Utility;HardwareSettings;" \
		"Comment=Use stream controllers"

	# Install icons if available
	local icon_src="src-tauri/icons"
	if [[ -d "${icon_src}" ]]; then
		local size
		for size in 32 128 256; do
			if [[ -f "${icon_src}/${size}x${size}.png" ]]; then
				insinto "/usr/share/icons/hicolor/${size}x${size}/apps"
				newins "${icon_src}/${size}x${size}.png" opendeck.png
			fi
		done
		if [[ -f "${icon_src}/icon.png" ]]; then
			insinto /usr/share/icons/hicolor/512x512/apps
			newins "${icon_src}/icon.png" opendeck.png
		fi
	fi

	# Install udev rules for Stream Deck hardware access
	insinto /etc/udev/rules.d
	if [[ -f "40-streamdeck.rules" ]]; then
		doins 40-streamdeck.rules
	else
		# Provide standard Stream Deck udev rules
		cat > "${T}/40-streamdeck.rules" <<-'EOF'
		SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", TAG+="uaccess"
		EOF
		doins "${T}/40-streamdeck.rules"
	fi

	einstalldocs
}

pkg_postinst() {
	xdg_desktop_database_update
	xdg_icon_cache_update

	elog "To access your Stream Deck without root, ensure udev rules are loaded:"
	elog "  sudo udevadm control --reload-rules && sudo udevadm trigger"
	elog ""
	elog "For Windows-only plugins, install app-emulation/wine."
	elog "For Node.js-based plugins, install net-libs/nodejs."
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_icon_cache_update
}
