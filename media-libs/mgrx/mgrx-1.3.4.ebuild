# Copyright 2019-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit toolchain-funcs multiprocessing

DESCRIPTION="2D graphics library for X11 or Framebuffer"
HOMEPAGE="http://www.fgrim.com/mgrx/"
SRC_URI="http://www.fgrim.com/mgrx/zfiles/${PN}$(ver_rs 1- '').tar.gz"

KEYWORDS="~amd64"
LICENSE="LGPL-2 MIT"
SLOT="0"
IUSE="X jpeg png +grgui"

RDEPEND="
        X? ( x11-libs/libX11 )
		jpeg? ( virtual/jpeg )
		png? ( media-libs/libpng )
"
DEPEND="${RDEPEND}"

# configuration file
CONF_FILE="makedefs.grx"
MAKE_FILE="" # set by src_configure()

S="${WORKDIR}/${PN}$(ver_rs 1- '')"

src_configure() {
	# fix a version string
	sed -i 's/^\(MGRX_VERSION\).*$/\1='"${PV}"'/' ${CONF_FILE} || die

	if use grgui ; then
		sed -i 's/^\(INCLUDE_GRGUI\).*$/\1=y/' ${CONF_FILE} || die
	else
		sed -i 's/^\(INCLUDE_GRGUI\).*$/\1=n/' ${CONF_FILE} || die
	fi

	if use jpeg; then
		sed -i 's/^\(HAVE_LIBJPEG\).*$/\1=y/' ${CONF_FILE} || die
	else
		sed -i 's/^\(HAVE_LIBJPEG\).*$/\1=n/' ${CONF_FILE} || die
	fi

	if use png; then
		sed -i 's/^\(HAVE_LIBPNG\).*$/\1=y/' ${CONF_FILE} || die
		sed -i 's/^\(NEED_ZLIB\).*$/\1=y/' ${CONF_FILE} || die
	else
		sed -i 's/^\(HAVE_LIBPNG\).*$/\1=n/' ${CONF_FILE} || die
		sed -i 's/^\(NEED_ZLIB\).*$/\1=n/' ${CONF_FILE} || die
	fi

	# build shared librarys
	sed -i 's/^\(INCLUDE_SHARED_SUPPORT\).*$/\1=y/' ${CONF_FILE} || die

	# build target (not tested except amd64)
	if use amd64 ; then
		sed -i 's/^\(BUILD_I386\).*$/\1=n/' ${CONF_FILE} || die
		sed -i 's/^\(BUILD_X86_64\).*$/\1=y/' ${CONF_FILE} || die
		sed -i 's/^\(BUILD_ARM\).*$/\1=n/' ${CONF_FILE} || die
	elif use arm64 ; then
		sed -i 's/^\(BUILD_I386\).*$/\1=n/' ${CONF_FILE} || die
		sed -i 's/^\(BUILD_X86_64\).*$/\1=y/' ${CONF_FILE} || die
		sed -i 's/^\(BUILD_ARM\).*$/\1=n/' ${CONF_FILE} || die
	elif use arm ; then
		sed -i 's/^\(BUILD_I386\).*$/\1=n/' ${CONF_FILE} || die
		sed -i 's/^\(BUILD_X86_64\).*$/\1=n/' ${CONF_FILE} || die
		sed -i 's/^\(BUILD_ARM\).*$/\1=y/' ${CONF_FILE} || die
	else
		sed -i 's/^\(BUILD_I386\).*$/\1=y/' ${CONF_FILE} || die
		sed -i 's/^\(BUILD_X86_64\).*$/\1=n/' ${CONF_FILE} || die
		sed -i 's/^\(BUILD_ARM\).*$/\1=n/' ${CONF_FILE} || die
	fi

	# CC and CFLAGS
	sed -i 's/^\(CC\)[ ]*=.*$/\1='"$(tc-getCC)"'/' ${CONF_FILE} || die
	awk '/CCOPT/{c+=1}{if(c==2){sub("^CCOPT.*$","CCOPT='"${CFLAGS}"'",$0)};print}' ${CONF_FILE} > ${CONF_FILE}.new || die
	mv ${CONF_FILE}.new ${CONF_FILE} || die

	# MGRX_DEFAULT_FONT_PATH is a library static vaule
	awk '/MGRX_DEFAULT_FONT_PATH/{c+=1} \
		{if(c==1 || c==2){sub("#MGRX_DEFAULT_FONT_PATH.*$","MGRX_DEFAULT_FONT_PATH='"${EPREFIX}"'/usr/share/mgrx/fonts",$0)};print}' \
		${CONF_FILE} > ${CONF_FILE}.new || die
	mv ${CONF_FILE}.new ${CONF_FILE} || die

	if use X ; then
		MAKE_FILE="makefile.x11"
	else
		MAKE_FILE="makefile.lnx"
	fi
	sed -i '/STRIP/d' src/${MAKE_FILE}  # remove strip processes, this should be done by emerge

	# FIXME Add library linking info for a mgrx shared library
	LINK_OPT=" -lm"
	if use jpeg ; then
		LINK_OPT+=" -ljpeg"
	fi
	if use png ; then
		LINK_OPT+=" -lpng"
	fi
	if use X ; then
		LINK_OPT+=" -lX11"
	fi
	sed -i '/shared/s/$/ '"${LINK_OPT}"'/' src/${MAKE_FILE}
}

src_compile() {
	cd src
	make -j$(makeopts_jobs) -f ${MAKE_FILE} || die
}

src_install() {
	cd src
	make -j$(makeopts_jobs) \
		INSTALLDIR="${ED}/usr" \
		-f ${MAKE_FILE} install || die
	make -j$(makeopts_jobs) \
		INSTALLDIR="${ED}/usr" \
		-f ${MAKE_FILE} install-bin || die
	cd ..

	insinto /usr/share/mgrx/fonts
	doins fonts/*

	local DOCS="readme doc/*.txt"
	local HTML_DOCS="doc/*.htm doc/img"
	einstalldocs

	find "${ED}/usr/$(get_libdir)" -name "*.a" -delete
}
