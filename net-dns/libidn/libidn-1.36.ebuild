# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
inherit elisp-common java-pkg-opt-2 mono-env multilib-minimal libtool

DESCRIPTION="Internationalized Domain Names (IDN) implementation"
HOMEPAGE="https://www.gnu.org/software/libidn/"
SRC_URI="mirror://gnu/libidn/${P}.tar.gz"

LICENSE="GPL-2 GPL-3 LGPL-3 java? ( Apache-2.0 )"
SLOT="0/12"
KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~riscv ~s390 ~sparc ~x86 ~ppc-aix ~x64-cygwin ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~m68k-mint ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE="doc emacs java mono nls"

DOCS=( AUTHORS ChangeLog FAQ NEWS README THANKS TODO )
COMMON_DEPEND="
	emacs? ( >=app-editors/emacs-23.1:* )
	mono? ( >=dev-lang/mono-0.95 )
"
DEPEND="
	${COMMON_DEPEND}
	java? ( >=virtual/jdk-1.5 )
	nls? ( >=sys-devel/gettext-0.17 )
"
RDEPEND="
	${COMMON_DEPEND}
	java? ( >=virtual/jre-1.5 )
	nls? ( >=virtual/libintl-0-r1[${MULTILIB_USEDEP}] )
"

pkg_setup() {
	mono-env_pkg_setup
	java-pkg-opt-2_pkg_setup
}

src_prepare() {
	default

	# bundled, with wrong bytecode
	rm "${S}/java/${P}.jar" || die

	elibtoolize  # for Solaris shared objects
}

multilib_src_configure() {
	local -x GJDOC=javadoc

	local args=(
		$(multilib_native_use_enable java)
		$(multilib_native_use_enable mono csharp mono)
		$(use_enable nls)
		--disable-static
		--disable-valgrind-tests
		--with-lispdir="${EPREFIX}${SITELISP}/${PN}"
		--with-packager-bug-reports="https://bugs.gentoo.org"
		--with-packager-version="r${PR}"
		--with-packager="Gentoo"
	)

	ECONF_SOURCE=${S} econf "${args[@]}"
}

multilib_src_compile() {
	default

	if multilib_is_native_abi; then
		use emacs && elisp-compile "${S}"/src/*.el
		use java && use doc && emake -C java/src/main/java javadoc
	fi
}

multilib_src_test() {
	# only run libidn specific tests and not gnulib tests (bug #539356)
	emake -C tests check
}

multilib_src_install() {
	emake DESTDIR="${D}" install

	if multilib_is_native_abi && use java; then
		java-pkg_newjar java/${P}.jar ${PN}.jar
		rm -r "${ED}"/usr/share/java || die
		use doc && java-pkg_dojavadoc "${S}"/doc/java
	fi
}

multilib_src_install_all() {
	if use emacs; then
		# *.el are installed by the build system
		elisp-install ${PN} "${S}"/src/*.elc
		elisp-site-file-install "${FILESDIR}/50${PN}-gentoo.el"
	else
		rm -r "${ED}/usr/share/emacs" || die
	fi

	einstalldocs

	if use doc ; then
		dodoc -r doc/reference/html/
	fi

	find "${ED}" -name '*.la' -delete || die
}

pkg_postinst() {
	use emacs && elisp-site-regen
}

pkg_postrm() {
	use emacs && elisp-site-regen
}
