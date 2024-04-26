TERMUX_PKG_HOMEPAGE=https://www.alsa-project.org
TERMUX_PKG_DESCRIPTION="Extra ALSA plugins"
TERMUX_PKG_VERSION=1.0.0
TERMUX_PKG_LICENSE=LGPL-2.1
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_SRCURL=https://github.com/ganyao114/wine-staging/raw/main/alsa-plugin.tar.xz
TERMUX_PKG_SHA256=a9f56b5832ab5d9044597c6f87094b192a3bc678471bd78d768ea00f0b0fa375
TERMUX_PKG_DEPENDS="alsa-lib"
TERMUX_PKG_HOSTBUILD=true

termux_step_host_build() {
	termux_setup_cmake
	cmake -DCMAKE_BUILD_TYPE=Release -S "$TERMUX_PKG_SRCDIR/alsa-plugin" -DCUSTOM_INCLUDE_PATH="$TERMUX_PREFIX/include" -DCROSS_PATH="$TERMUX_PREFIX/lib"
	make -j16
}