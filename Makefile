all: mpv

DEPS= \
	pkg-config \
	mpv \
		libass \
			freetype \
			harfbuzz \
			fribidi \
		ffmpeg

.PHONY: lock
lock:
	@go run cmd/lock/lock.go $(DEPS) > downloads.lock

downloads/.timestamp: downloads.lock
	@rm -f downloads/*.tar.*
	@go run cmd/download/download.go downloads.lock downloads
	@touch downloads/.timestamp

.PHONY: downloads
downloads: downloads/.timestamp

sources/.timestamp: downloads/.timestamp
	@for ARCHIVE in downloads/*.tar.* ; do \
		NAME=$${ARCHIVE%-*.*.*} ; \
		NAME=$$(basename $$NAME) ; \
		echo $$NAME ; \
		mkdir -p sources/$$NAME ; \
		tar -xvf $$ARCHIVE --strip-components 1 -C sources/$$NAME 2> /dev/null ; \
	done
	@touch sources/.timestamp

.PHONY: sources
sources: sources/.timestamp

build/macos/x64:
	@mkdir -p build/macos/x64

build/macos/x64/bin: build/macos/x64
	@mkdir -p build/macos/x64/bin

build/macos/x64/bin/ninja: build/macos/x64/bin
	@rm -f build/macos/x64/bin/ninja
	ln -s $(shell which ninja) $(PWD)/build/macos/x64/bin/ninja
	@touch build/macos/x64/bin/ninja

.PHONY: ninja
ninja: build/macos/x64/bin/ninja

build/macos/x64/bin/meson: build/macos/x64/bin/ninja
	@rm -f build/macos/x64/bin/meson
	ln -s $(shell which meson) $(PWD)/build/macos/x64/bin/meson
	@touch build/macos/x64/bin/meson

.PHONY: meson
meson: build/macos/x64/bin/meson

build/macos/x64/bin/pkg-config: sources/.timestamp build/macos/x64
	$(eval PREFIX := $(PWD)/build/macos/x64)
	export \
		PKG_CONFIG_PATH=$(PWD)/build/macos/x64/lib/pkgconfig \
		PATH=$(PWD)/build/macos/x64/bin:/bin:/usr/bin \
			&& cd sources/pkg-config \
				&& ./configure \
					--prefix="$(PREFIX)" \
					--with-internal-glib \
				&& make \
				&& make install

.PHONY: pkg-config
pkg-config: build/macos/x64/bin/pkg-config

build/macos/x64/lib/libfreetype.dylib: \
	sources/.timestamp \
	build/macos/x64/bin/meson

	$(eval PREFIX := $(PWD)/build/macos/x64)
	export \
		PKG_CONFIG_PATH=$(PWD)/build/macos/x64/lib/pkgconfig \
		PATH=$(PWD)/build/macos/x64/bin:/bin:/usr/bin \
		&& cd sources/freetype \
			&& meson setup build \
				--prefix="$(PREFIX)" \
				-Dbrotli=disabled \
				-Dbzip2=disabled \
				-Dharfbuzz=disabled \
				-Dmmap=disabled \
				-Dpng=disabled \
				-Dtests=disabled \
				-Dzlib=disabled \
			&& meson compile -C build \
			&& meson install -C build

.PHONY: freetype
freetype: build/macos/x64/lib/libfreetype.dylib

build/macos/x64/lib/libfribidi.dylib: \
	sources/.timestamp \
	build/macos/x64

	$(eval PREFIX := $(PWD)/build/macos/x64)
	export \
		PKG_CONFIG_PATH=$(PWD)/build/macos/x64/lib/pkgconfig \
		PATH=$(PWD)/build/macos/x64/bin:/bin:/usr/bin \
		&& cd sources/fribidi \
			&& meson setup build \
				--prefix="$(PREFIX)" \
			&& meson compile -C build \
			&& meson install -C build

.PHONY: fribidi
fribidi: build/macos/x64/lib/libfribidi.dylib

build/macos/x64/lib/libharfbuzz.dylib: \
	sources/.timestamp \
	build/macos/x64/bin/meson

	$(eval PREFIX := $(PWD)/build/macos/x64)
	export \
		PKG_CONFIG_PATH=$(PWD)/build/macos/x64/lib/pkgconfig \
		PATH=$(PWD)/build/macos/x64/bin:/bin:/usr/bin \
		&& cd sources/harfbuzz \
			&& meson setup build \
				--prefix="$(PREFIX)" \
				-Dglib=disabled \
				-Dgobject=disabled \
				-Dcairo=disabled \
				-Dchafa=disabled \
				-Dicu=disabled \
				-Dgraphite=disabled \
				-Dgraphite2=disabled \
				-Dfreetype=disabled \
				-Dgdi=disabled \
				-Ddirectwrite=disabled \
				-Dcoretext=disabled \
				-Dtests=disabled \
				-Dintrospection=disabled \
				-Ddocs=disabled \
			&& meson compile -C build \
			&& meson install -C build

.PHONY: harfbuzz
harfbuzz: build/macos/x64/lib/libharfbuzz.dylib

build/macos/x64/lib/libass.dylib: \
	sources/.timestamp \
	build/macos/x64/bin/pkg-config \
	build/macos/x64/lib/libfreetype.dylib \
	build/macos/x64/lib/libfribidi.dylib \
	build/macos/x64/lib/libharfbuzz.dylib

	$(eval PREFIX := $(PWD)/build/macos/x64)
	export \
		PKG_CONFIG_PATH=$(PWD)/build/macos/x64/lib/pkgconfig \
		PATH=$(PWD)/build/macos/x64/bin:/bin:/usr/bin \
		&& cd sources/libass \
			&& ./configure \
				--prefix="$(PREFIX)" \
				--disable-static \
				--disable-dependency-tracking \
				--with-pic \
				--disable-fontconfig \
				--disable-require-system-font-provider \
				--disable-directwrite \
			&& make \
			&& make install

.PHONY: libass
libass: build/macos/x64/lib/libass.dylib

build/macos/x64/lib/libavcodec.dylib: \
	sources/.timestamp \
	build/macos/x64/bin/pkg-config

	$(eval PREFIX := $(PWD)/build/macos/x64)
	export \
		PKG_CONFIG_PATH=$(PWD)/build/macos/x64/lib/pkgconfig \
		PATH=$(PWD)/build/macos/x64/bin:/bin:/usr/bin \
		&& cd sources/ffmpeg \
			&& ./configure \
				--prefix="$(PREFIX)" \
				--disable-lzma \
				--disable-securetransport \
				--disable-sdl2 \
				--disable-debug \
				--disable-programs \
				--disable-doc \
				--enable-pic \
				--enable-shared \
				--disable-x86asm \
			&& make \
			&& make install

.PHONY: ffmpeg
ffmpeg: build/macos/x64/lib/libavcodec.dylib

build/macos/x64/lib/libmpv.dylib: \
	sources/.timestamp \
	build/macos/x64/bin/meson \
	build/macos/x64/bin/pkg-config \
	build/macos/x64/lib/libass.dylib \
	build/macos/x64/lib/libavcodec.dylib

	$(eval PREFIX := $(PWD)/build/macos/x64)
	export \
		PKG_CONFIG_PATH=$(PWD)/build/macos/x64/lib/pkgconfig \
		PATH=$(PWD)/build/macos/x64/bin:/bin:/usr/bin \
		&& cd sources/mpv \
			&& meson setup build \
				--prefix="$(PREFIX)" \
				`# booleans` \
				-Dgpl=true             `# GPL (version 2 or later) build` \
				-Dcplayer=false        `# mpv CLI player` \
				-Dlibmpv=true          `# libmpv library` \
				-Dbuild-date=true      `# whether to include binary compile time` \
				-Dtests=false          `# unit tests (development only)` \
				-Dta-leak-report=false `# enable ta leak report by default (development only)` \
				\
				`# misc features` \
				-Dcdda=disabled                    `# cdda support (libcdio)` \
				-Dcplugins=auto                    `# C plugins` \
				-Ddvbin=disabled                   `# DVB input module` \
				-Ddvdnav=disabled                  `# dvdnav support` \
				-Diconv=disabled                   `# iconv` \
				-Djavascript=disabled              `# Javascript (MuJS backend)` \
				-Dlcms2=disabled                   `# LCMS2 support` \
				-Dlibarchive=disabled              `# libarchive wrapper for reading zip files and more` \
				-Dlibavdevice=disabled             `# libavdevice` \
				-Dlibbluray=disabled               `# Bluray support` \
				-Dlua=disabled                     `# Lua` \
				-Dpthread-debug=disabled           `# pthread runtime debugging wrappers` \
				-Drubberband=disabled              `# librubberband support` \
				-Dsdl2=disabled                    `# SDL2` \
				-Dsdl2-gamepad=disabled            `# SDL2 gamepad input` \
				-Dstdatomic=disabled               `# C11 stdatomic.h` \
				-Duchardet=disabled                `# uchardet support` \
				-Duwp=disabled                     `# Universal Windows Platform` \
				-Dvapoursynth=disabled             `# VapourSynth filter bridge` \
				-Dvector=disabled                  `# GCC vector instructions` \
				-Dwin32-internal-pthreads=disabled `#internal pthread wrapper for win32 (Vista+)` \
				-Dzimg=disabled                    `# libzimg support (high quality software scaler)` \
				-Dzlib=disabled                    `# zlib` \
				\
				`# audio output features` \
				-Dalsa=disabled       `# ALSA audio output` \
				-Daudiounit=disabled  `# AudioUnit output for iOS` \
				-Dcoreaudio=enabled   `# CoreAudio audio output` \
				-Djack=disabled       `# JACK audio output` \
				-Dopenal=disabled     `# OpenAL audio output` \
				-Dopensles=disabled   `# OpenSL ES audio output` \
				-Doss-audio=disabled  `# OSSv4 audio output` \
				-Dpipewire=disabled   `# PipeWire audio output` \
				-Dpulse=disabled      `# PulseAudio audio output` \
				-Dsdl2-audio=disabled `# SDL2 audio output` \
				-Dsndio=disabled      `# sndio audio output` \
				-Dwasapi=disabled     `# WASAPI audio output` \
				\
				`# video output features` \
				-Dcaca=disabled            `# CACA` \
				-Dcocoa=enabled            `# Cocoa` \
				-Dd3d11=disabled           `# Direct3D 11 video output` \
				-Ddirect3d=disabled        `# Direct3D support` \
				-Ddrm=disabled             `# DRM` \
				-Degl=disabled             `# EGL 1.4` \
				-Degl-android=disabled     `# Android EGL support` \
				-Degl-angle=disabled       `# OpenGL ANGLE headers` \
				-Degl-angle-lib=disabled   `# OpenGL Win32 ANGLE library` \
				-Degl-angle-win32=disabled `# OpenGL Win32 ANGLE Backend` \
				-Degl-drm=disabled         `# OpenGL DRM EGL Backend` \
				-Degl-wayland=disabled     `# OpenGL Wayland Backend` \
				-Degl-x11=disabled         `# OpenGL X11 EGL Backend` \
				-Dgbm=disabled             `# GBM` \
				-Dgl=enabled               `# OpenGL context support` \
				-Dgl-cocoa=enabled         `# gl-cocoa` \
				-Dgl-dxinterop=disabled    `# OpenGL/DirectX Interop Backend` \
				-Dgl-win32=disabled        `# OpenGL Win32 Backend` \
				-Dgl-x11=disabled          `# OpenGL X11/GLX (deprecated/legacy)` \
				-Djpeg=disabled            `# JPEG support` \
				-Dlibplacebo=disabled      `# libplacebo support` \
				-Drpi=disabled             `# Raspberry Pi support` \
				-Dsdl2-video=disabled      `# SDL2 video output` \
				-Dshaderc=disabled         `# libshaderc SPIR-V compiler` \
				-Dsixel=disabled           `# Sixel` \
				-Dspirv-cross=disabled     `# SPIRV-Cross SPIR-V shader converter` \
				-Dplain-gl=enabled         `# OpenGL without platform-specific code (e.g. for libmpv)` \
				-Dvdpau=disabled           `# VDPAU acceleration` \
				-Dvdpau-gl-x11=disabled    `# VDPAU with OpenGl/X11` \
				-Dvaapi=disabled           `# VAAPI acceleration` \
				-Dvaapi-drm=disabled       `# VAAPI (DRM/EGL support)` \
				-Dvaapi-wayland=disabled   `# VAAPI (Wayland support)` \
				-Dvaapi-x11=disabled       `# VAAPI (X11 support)` \
				-Dvaapi-x-egl=disabled     `# VAAPI EGL on X11` \
				-Dvulkan=disabled          `# Vulkan context support` \
				-Dwayland=disabled         `# Wayland` \
				-Dx11=disabled             `# X11` \
				-Dxv=disabled              `# Xv video output` \
				\
				`# hwaccel features` \
				-Dandroid-media-ndk=disabled `# Android Media APIs` \
				-Dcuda-hwaccel=disabled      `# CUDA acceleration` \
				-Dcuda-interop=disabled      `# CUDA with graphics interop` \
				-Dd3d-hwaccel=disabled       `# D3D11VA hwaccel` \
				-Dd3d9-hwaccel=disabled      `# DXVA2 hwaccel` \
				-Dgl-dxinterop-d3d9=disabled `# OpenGL/DirectX Interop Backend DXVA2 interop` \
				-Dios-gl=disabled            `# iOS OpenGL ES hardware decoding interop support` \
				-Drpi-mmal=disabled          `# Raspberry Pi MMAL hwaccel` \
				-Dvideotoolbox-gl=enabled   `# Videotoolbox with OpenG` \
				\
				`# macOS features` \
				-Dmacos-10-11-features=enabled   `# macOS 10.11 SDK Features` \
				-Dmacos-10-12-2-features=enabled `# macOS 10.12.2 SDK Features` \
				-Dmacos-10-14-features=enabled   `# macOS 10.14 SDK Features` \
				-Dmacos-cocoa-cb=disabled        `# macOS libmpv backend` \
				-Dmacos-media-player=disabled    `# macOS Media Player support` \
				-Dmacos-touchbar=disabled        `# macOS Touch Bar support` \
				-Dswift-build=disabled           `# macOS Swift build tools` \
				-Dswift-flags=                   `# Optional Swift compiler flags` \
				\
				`# manpages` \
				-Dhtml-build=disabled    `# html manual generation` \
				-Dmanpage-build=disabled `# manpage generation` \
				-Dpdf-build=disabled     `# pdf manual generation` \
			&& meson compile -C build mpv:shared_library \
			&& meson install -C build

.PHONY: mpv
mpv: build/macos/x64/lib/libmpv.dylib

.PHONY: clean
clean:
	rm -rf sources/* sources/.timestamp
	rm -rf build

.PHONY: clear
clear: clean
	rm -rf downloads/* downloads/.timestamp
