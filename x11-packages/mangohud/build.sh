TERMUX_PKG_HOMEPAGE=https://github.com/flightlessmango/MangoHud/
TERMUX_PKG_DESCRIPTION="A Vulkan overlay layer for monitoring FPS, temperatures, CPU/GPU load and more"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="@termux-pacman"
TERMUX_PKG_VERSION="0.7.1"
TERMUX_PKG_SRCURL=https://github.com/flightlessmango/MangoHud/releases/download/v${TERMUX_PKG_VERSION}/MangoHud-v${TERMUX_PKG_VERSION}-1-Source.tar.xz
TERMUX_PKG_SHA256=cfcc907c91b51f1fef4ec3f1cd52e2ff1b5caf207cdcff71869b94cefe39d208
TERMUX_PKG_DEPENDS="dbus, libx11, python-pip, vulkan-loader, glslang, nlohmann-json, libandroid-wordexp"
TERMUX_PKG_BUILD_DEPENDS="nlohmann-json"
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-Ddynamic_string_tokens=false
-Dwith_xnvctrl=disabled
"

termux_step_create_debscripts() {
	echo "#!$TERMUX_PREFIX_CLASSICAL/bin/bash" > postinst
	echo "LD_PRELOAD='' $TERMUX_PREFIX/bin/pip install --upgrade matplotlib numpy" >> postinst
	if [ "$TERMUX_PACKAGE_FORMAT" = "pacman" ]; then
		echo "post_install" > postupg
	fi
}

termux_step_pre_configure() {
  export PATH=$PATH:/home/builder/.termux-build/glslang/host-build/StandAlone
  termux_setup_cmake
  cp -f $TERMUX_PKG_BUILDER_DIR/meson.build $TERMUX_PKG_SRCDIR/meson.build
  cp -f $TERMUX_PKG_BUILDER_DIR/hud_elements.h $TERMUX_PKG_SRCDIR/src/hud_elements.h
  cp -f $TERMUX_PKG_BUILDER_DIR/fps_metrics.h $TERMUX_PKG_SRCDIR/src/fps_metrics.h
  LDFLAGS+=" -landroid-wordexp"
}
