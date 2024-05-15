TERMUX_PKG_HOMEPAGE=https://www.winehq.org/
TERMUX_PKG_DESCRIPTION="A compatibility layer for running Windows programs"
TERMUX_PKG_LICENSE="LGPL-2.1"
TERMUX_PKG_LICENSE_FILE="\
LICENSE
LICENSE.OLD
COPYING.LIB"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=9.4
TERMUX_PKG_SRCURL=https://github.com/ganyao114/wine-staging/raw/main/wine-$TERMUX_PKG_VERSION.tar.xz
TERMUX_PKG_SHA256=ad369db63efcb855293a88f699dccba6ac83b079742229dd64d8972ffef63f59
TERMUX_PKG_DEPENDS="fontconfig, freetype, krb5, libandroid-spawn, libc++, libgmp, libgnutls, libxcb, libxcomposite, libxcursor, libxfixes, libxrender, mesa, opengl, vulkan-loader, libandroid-shmem, alsa-lib"
TERMUX_PKG_ANTI_BUILD_DEPENDS="vulkan-loader"
TERMUX_PKG_BUILD_DEPENDS="libandroid-spawn-static, libandroid-shmem-static, vulkan-loader-generic"
TERMUX_PKG_NO_STATICSPLIT=true
TERMUX_PKG_HOSTBUILD=true
TERMUX_PKG_EXTRA_HOSTBUILD_CONFIGURE_ARGS="
--without-x
--disable-tests
"

TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
enable_wineandroid_drv=no
wine_cv_have_sched_setaffinity=no
--with-wine-tools=$TERMUX_PKG_HOSTBUILD_DIR
--enable-nls
--disable-tests
--with-alsa
--without-capi
--without-coreaudio
--without-cups
--without-dbus
--with-fontconfig
--with-freetype
--without-gettext
--with-gettextpo=no
--without-gphoto
--with-gnutls
--without-gstreamer
--without-inotify
--with-krb5
--with-mingw
--without-netapi
--without-opencl
--with-opengl
--with-osmesa
--without-oss
--without-pcap
--with-pthread
--without-sane
--without-sdl
--without-udev
--without-unwind
--without-usb
--without-v4l2
--with-vulkan
--with-xcomposite
--with-xcursor
--with-xfixes
--without-xinerama
--with-xinput
--with-xinput2
--without-xrandr
--with-xrender
--without-xshape
--with-xshm
--without-xxf86vm
"

# Enable win64 on 64-bit arches.
if [ "$TERMUX_ARCH_BITS" = 64 ]; then
	TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" --enable-win64"
fi

# Enable new WoW64 support on x86_64.
if [ "$TERMUX_ARCH" = "x86_64" ]; then
	TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" --enable-archs=i386,x86_64"
fi

TERMUX_PKG_BLACKLISTED_ARCHES="arm"

_setup_llvm_mingw_toolchain() {
	# LLVM-mingw's version number must not be the same as the NDK's.
	local _llvm_mingw_version=16
	local _version="20230614"
	local _url="https://github.com/mstorsjo/llvm-mingw/releases/download/$_version/llvm-mingw-$_version-ucrt-ubuntu-20.04-x86_64.tar.xz"
	local _path="$TERMUX_PKG_CACHEDIR/$(basename $_url)"
	local _sha256sum=9ae925f9b205a92318010a396170e69f74be179ff549200e8122d3845ca243b8
	termux_download $_url $_path $_sha256sum
	local _extract_path="$TERMUX_PKG_CACHEDIR/llvm-mingw-toolchain-$_llvm_mingw_version"
	if [ ! -d "$_extract_path" ]; then
		mkdir -p "$_extract_path"-tmp
		tar -C "$_extract_path"-tmp --strip-component=1 -xf "$_path"
		mv "$_extract_path"-tmp "$_extract_path"
	fi
	export PATH="$PATH:$_extract_path/bin"
}

termux_step_host_build() {
	# Setup llvm-mingw toolchain
	_setup_llvm_mingw_toolchain

	# Make host wine-tools
	"$TERMUX_PKG_SRCDIR/configure" ${TERMUX_PKG_EXTRA_HOSTBUILD_CONFIGURE_ARGS}
	make -j "$TERMUX_MAKE_PROCESSES" __tooldeps__ nls/all
}

termux_step_pre_configure() {
	# Setup llvm-mingw toolchain
	_setup_llvm_mingw_toolchain

	# Copy dll patches
  cp -f $TERMUX_PKG_BUILDER_DIR/dlls/xinput/main.c $TERMUX_PKG_SRCDIR/dlls/xinput1_3/main.c
#  sed -i '/^IMPORTS/ s/$/ ws2_32/' $TERMUX_PKG_SRCDIR/dlls/xinput1_1/Makefile.in
#  sed -i '/^IMPORTS/ s/$/ ws2_32/' $TERMUX_PKG_SRCDIR/dlls/xinput1_2/Makefile.in
#  sed -i '/^IMPORTS/ s/$/ ws2_32/' $TERMUX_PKG_SRCDIR/dlls/xinput1_3/Makefile.in
#  sed -i '/^IMPORTS/ s/$/ ws2_32/' $TERMUX_PKG_SRCDIR/dlls/xinput1_4/Makefile.in
#  sed -i '/^IMPORTS/ s/$/ ws2_32/' $TERMUX_PKG_SRCDIR/dlls/xinput9_1_0/Makefile.in

	# Fix overoptimization
	CPPFLAGS="${CPPFLAGS/-Oz/}"
	CFLAGS="${CFLAGS/-Oz/}"
	CXXFLAGS="${CXXFLAGS/-Oz/}"

	# Disable hardening
	CPPFLAGS="${CPPFLAGS/-fstack-protector-strong/}"
	CFLAGS="${CFLAGS/-fstack-protector-strong/}"
	CXXFLAGS="${CXXFLAGS/-fstack-protector-strong/}"
	LDFLAGS="${LDFLAGS/-Wl,-z,relro,-z,now/}"

	LDFLAGS+=" -landroid-spawn"
  LDFLAGS+=" -Wl,--as-needed -landroid-shmem"

	export XPERIMENTAL_WOW64="${EXPERIMENTAL_WOW64:-true}"
}

termux_step_post_configure() {
  makefile_path="$TERMUX_PKG_SRCDIR/../build/Makefile"

  if [ -f "$makefile_path" ]; then
      echo "Load Makefile"
      filedata=$(<"$makefile_path")
      echo "rescue libwsock32.a"
      filedata=$(echo "$filedata" | sed 's/rm -f dlls\/wsock32\/libwsock32.a dlls\/wsock32\/x86_64-windows\/libwsock32.a dlls\/wsock32\/version.res \\/rm -f dlls\/wsock32\/libwsock32.a dlls\/wsock32\/version.res \\/')
      echo "put libwsock32.a to xinput1_1.dll"
      filedata=$(echo "$filedata" | sed 's/dlls\/xinput1_1\/version.res dlls\/hid\/x86_64-windows\/libhid.a \\/dlls\/xinput1_1\/version.res dlls\/hid\/x86_64-windows\/libhid.a dlls\/wsock32\/x86_64-windows\/libwsock32.a \\/')
      echo "put libwsock32.a to xinput1_2.dll"
      filedata=$(echo "$filedata" | sed 's/dlls\/xinput1_2\/version.res dlls\/hid\/x86_64-windows\/libhid.a \\/dlls\/xinput1_2\/version.res dlls\/hid\/x86_64-windows\/libhid.a dlls\/wsock32\/x86_64-windows\/libwsock32.a \\/')
      echo "put libwsock32.a to xinput1_3.dll"
      filedata=$(echo "$filedata" | sed 's/dlls\/xinput1_3\/version.res dlls\/hid\/x86_64-windows\/libhid.a \\/dlls\/xinput1_3\/version.res dlls\/hid\/x86_64-windows\/libhid.a dlls\/wsock32\/x86_64-windows\/libwsock32.a \\/')
      echo "put libwsock32.a to xinput1_4.dll"
      filedata=$(echo "$filedata" | sed 's/dlls\/xinput1_4\/version.res dlls\/hid\/x86_64-windows\/libhid.a \\/dlls\/xinput1_4\/version.res dlls\/hid\/x86_64-windows\/libhid.a dlls\/wsock32\/x86_64-windows\/libwsock32.a \\/')
      echo "put libwsock32.a to xinput9_1_0.dll"
      filedata=$(echo "$filedata" | sed 's/dlls\/advapi32\/x86_64-windows\/libadvapi32\.a dlls\/user32\/x86_64-windows\/libuser32\.a/dlls\/advapi32\/x86_64-windows\/libadvapi32\.a dlls\/user32\/x86_64-windows\/libuser32\.a dlls\/wsock32\/x86_64-windows\/libwsock32.a/')
      echo "Save Makefile"
      echo "$filedata" > "$makefile_path"
      echo "done"
  else
      echo "'$makefile_path' not found"
      exit
  fi
}

termux_step_make_install() {
	make -j $TERMUX_MAKE_PROCESSES install
}
