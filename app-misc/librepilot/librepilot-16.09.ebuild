# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit eutils
inherit git-r3

DESCRIPTION="Software suite to control for Multicopters and other RC models"
HOMEPAGE="http://librepilot.org/"

EGIT_REPO_URI="https://bitbucket.org/librepilot/librepilot.git"

if [[ "${PV}" != "9999" ]]; then
	KEYWORDS="~amd64 ~x86"  # Note: ~x86 NOT tested
fi

# TODO: Check if this is needed lower down when setting up with tagged versions
#    S=${WORKDIR}/${PN}-${P}

RESTRICT="network-sandbox"
LICENSE="GPL-3"
SLOT="0"
REQUIRED_USE="qt5 osg"
IUSE="doc qt5 osg"

RDEPEND="
	osg? ( sci-geosciences/osgearth
		>=dev-games/openscenegraph-3.2.1
		sci-libs/gdal
		sci-libs/geos )
	x11-libs/libX11
	dev-qt/qtcore:5
	dev-qt/qtgui:5
	dev-qt/qtopengl:5
	dev-qt/qtsql:5
	dev-qt/qtserialport:5
	dev-qt/qtdeclarative:5
	dev-qt/qtwebkit:5
	dev-qt/qtscript:5
	dev-qt/qtprintsupport:5
	doc? (
		app-doc/doxygen )
	"

DEPEND="${RDEPEND}"



PATCHES=( "${FILESDIR}"/${P}-{remove_uninstall}.patch )

src_unpack() {
	if [[ "${PV}" = "9999" ]]; then
        # Current development branch
		echo "Development Branch checkout"
		git-r3_fetch
		git-r3_checkout
	else
		# Release branch
		EGIT_COMMIT="${PV}"
		git-r3_fetch "${EGIT_REPO_URI}" "${EGIT_COMMIT}"
		git-r3_checkout
	fi
}

src_prepare() {
	epatch "${FILESDIR}/${P}-remove_uninstall.patch"
	use osg && epatch "${FILESDIR}/${P}-config_osg.patch"
	eapply_user
}

src_compile() {
	# Need to get the tools first, which don't get installed in main system
	# The following tools are assumed to be installed:
	#  - qt5
	#  - doxygen (if required - set / unset doc flag)
	#  - osg     (dev-games/openscenegraph)
	#  - osgearth (Not in main tree - see separate ebuild)

	# The arm_sdk package will be installed, to avoid challenges with
	# crossdev

	make fw_recourse && QT_SELECT=5 make gcs

	# TODO:: Add building of the doc files
}


src_install() {
	emake DESTDIR="${D}" install
	doenvd ${FILESDIR}/99librepilot
	# TODO:: Add installation of the doc files
}

pkg_postinst() {
	elog "During the installation, an environment variable is set to ensure the"
	elog "correct google satellite version is used. This is not present in the "
	elog "environment until you log out and back in."
}
