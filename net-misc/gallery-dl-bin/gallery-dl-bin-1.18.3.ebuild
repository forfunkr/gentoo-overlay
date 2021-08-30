# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

DESCRIPTION="A tool for downloading from several image hosting sites"
HOMEPAGE="https://github.com/mikf/gallery-dl"
SRC_URI="https://github.com/mikf/gallery-dl/releases/download/v${PV}/gallery-dl.bin"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="sys-libs/glibc"
DEPEND="${RDEPEND}"

S="${WORKDIR}/${PN}"

QA_FLAGS_IGNORED="opt/gallery-dl/gallery-dl.bin"
QA_PRESTRIPPED=${QA_FLAGS_IGNORED}

src_unpack() {
	mkdir -p ${S} || die
	cp ${DISTDIR}/gallery-dl.bin ${S} || die
}

src_compile() { :; }

src_install() {
	exeinto /opt/gallery-dl
	doexe gallery-dl.bin

	dodir /opt/bin
	dosym ../gallery-dl/gallery-dl.bin /opt/bin/gallery-dl
}
