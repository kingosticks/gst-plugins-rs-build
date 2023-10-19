FROM debian:bullseye-slim

LABEL org.opencontainers.image.source https://github.com/mopidy/gst-plugin-spotify-build

RUN dpkg --add-architecture armhf

RUN apt-get update \
        && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        clang \
        curl ca-certificates \
        debhelper \
        git \
        pkg-config \
        # Rpi
        gcc-arm-linux-gnueabihf \
        libgstreamer-plugins-base1.0-dev:armhf \
        && rm -rf /var/lib/apt/lists/*

ENV RPI_TOOLS_DIR=/rpi-tools
RUN git clone --depth=1 https://github.com/raspberrypi/tools $RPI_TOOLS_DIR && rm -rf $RPI_TOOLS_DIR/.git

ARG RPI_STUFF=$RPI_TOOLS_DIR/arm-bcm2708/arm-linux-gnueabihf
ENV RPI_BIN=$RPI_STUFF/bin
ENV RPI_SYSROOT=$RPI_STUFF/arm-linux-gnueabihf/sysroot

ENV CARGO_TARGET_ARM_UNKNOWN_LINUX_GNUEABIHF_RUSTFLAGS="-C linker=$RPI_BIN/arm-linux-gnueabihf-gcc -L$RPI_SYSROOT/lib -L$RPI_SYSROOT/usr/lib"

COPY VERSION /
