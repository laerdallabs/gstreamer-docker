ARG DEBIAN_VERSION=bullseye
FROM debian:${DEBIAN_VERSION} AS build-deps

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    # Remove imagemagick due to https://security-tracker.debian.org/tracker/CVE-2019-10131
    && apt-get purge -y imagemagick imagemagick-6-common

ENV PATH="${PATH}:/root/.cargo/bin"

RUN sed -i 's/^deb .*main$/& contrib non-free/g' /etc/apt/sources.list \
    && apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
      build-essential \
      ca-certificates \
      python3 \
      python3-pip \
      python3-dev \
      gcc \
      clang-16 \
      cmake \
      git \
      gitlint \
      curl \
      unzip \
      flex \
      bison \
      freeglut3-dev \
      gettext \
      nasm \
      glib-networking-common \
      gobject-introspection \
      liba52-0.7.4-dev \
      libavc1394-dev \
      libavcodec-dev \
      libavfilter-dev \
      libavformat-dev \
      libavutil-dev \
      libbz2-dev \
      libcaca-dev \
      libcap2-dev \
      libcdio-dev \
      libcdparanoia-dev \
      libcurl4-gnutls-dev \
      libdav1d-dev \
      libdrm-dev \
      libdv4-dev \
      libdvdread-dev \
      libdw-dev \
      libfaac-dev \
      libfaad-dev \
      libflac-dev \
      libgbm-dev \
      libgcrypt20-dev \
      libgirepository1.0-dev \
      libglib2.0-dev \
      libgmp-dev \
      libgnutls28-dev \
      libgraphene-1.0-dev \
      libgsl-dev \
      libgslcblas0 \
      libgtk-3-dev \
      libgudev-1.0-dev \
      libiec61883-dev \
      libjpeg-dev \
      libjson-glib-dev \
      liblcms2-dev \
      libmjpegtools-dev \
      libmodplug-dev \
      libmp3lame-dev \
      libmpcdec-dev \
      libmpeg2-4-dev \
      libmpg123-dev \
      libneon27-dev \
      libonnx-dev \
      libopenal-dev \
      libopenaptx-dev \
      libopencv-core-dev \
      libopenexr-dev \
      libopenjp2-7-dev \
      libopus-dev \
      liborc-0.4-dev \
      libpango-1.0-0 \
      libpango1.0-dev \
      libpng-dev \
      libraw1394-dev \
      libsodium-dev \
      libsoundtouch-dev \
      libsoup2.4-dev \
      libspandsp-dev \
      libsrt-gnutls-dev \
      libsrtp2-dev \
      libssl-dev \
      libtheora-dev \
      libudev-dev \
      libunwind-dev \
      libv4l-dev \
      libvisual-0.4-dev \
      libvisual-0.4-dev \
      libvo-aacenc-dev \
      libvo-amrwbenc-dev \
      libvorbis-dev \
      libvorbisidec-dev \
      libvpx-dev \
      libwavpack-dev \
      libwayland-dev \
      libwebp-dev \
      libwebrtc-audio-processing-dev \
      libwildmidi-dev \
      libwpewebkit-1.0-dev \
      libx11-xcb-dev \
      libx264-dev \
      libx265-dev \
      libxv-dev \
      libzbar-dev \
      libzxingcore-dev \
      nettle-dev \
      python3-cairo-dev \
      qtbase5-dev \
      bash-completion \
      gobject-introspection \
      iso-codes \
      json-glib-tools \
      mjpegtools \
      python-gi-dev \
      python3-gi-cairo \
      speex \
      twolame \
      valgrind \
      wayland-protocols \
    \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && python3 -m pip install meson ninja tomli gitlint \
    && update-alternatives --install /usr/bin/clang clang /usr/bin/clang-16 100 \
    && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable \
    && cargo install cargo-c tomllib toml2json

FROM build-deps AS gstreamer

ARG GSTREAMER_REPO=https://gitlab.freedesktop.org/gstreamer/gstreamer.git
ARG GSTREAMER_REF=main
RUN git clone --depth=1 --branch ${GSTREAMER_REF} ${GSTREAMER_REPO} /src/gstreamer \
    && cd /src/gstreamer \
    && meson setup \
      --buildtype debugoptimized \
      --prefix=/usr \
      -Dges=disabled \
      -Dtests=disabled \
      -Dexamples=disabled \
      -Dgst-examples=disabled \
      -Ddoc=disabled \
      -Dgtk_doc=disabled \
      -Dgpl=enabled \
      -Drs=enabled \
      build \
  && meson compile -C build \
  && meson install -C build --tags devel,bin-devel --destdir /opt/gstreamer-devel/ \
  && meson install -C build --tags runtime,python-runtime,typelib --destdir /opt/gstreamer-runtime/ \
  && meson install -C build --tags bin --destdir /opt/gstreamer-bin/

FROM build-deps AS main

COPY --from=gstreamer /src/gstreamer /src/gstreamer/
COPY --from=gstreamer /opt/gstreamer-devel /
COPY --from=gstreamer /opt/gstreamer-runtime /
COPY --from=gstreamer /opt/gstreamer-bin /
