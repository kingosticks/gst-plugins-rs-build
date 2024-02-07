FROM debian:bullseye-slim

LABEL org.opencontainers.image.source https://github.com/mopidy/gst-plugins-rs-build

RUN dpkg --add-architecture armhf
RUN dpkg --add-architecture arm64

RUN apt-get update \
        && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        clang \
        curl ca-certificates \
        debhelper \
        git \
        pkg-config \
        # amd64
        gcc \
        libgstreamer-plugins-base1.0-dev \
        # RPi 0 and 1 (armv6)
        gcc-arm-linux-gnueabihf \
        libgstreamer-plugins-base1.0-dev:armhf \
        # RPi 3, 4 and 5 (64-bit ARM)
        gcc-aarch64-linux-gnu \
        libgstreamer-plugins-base1.0-dev:arm64 \
        && rm -rf /var/lib/apt/lists/*

ENV RPI_TOOLS_DIR=/rpi-tools
RUN git clone --depth=1 https://github.com/raspberrypi/tools $RPI_TOOLS_DIR && rm -rf $RPI_TOOLS_DIR/.git

ARG RPI_STUFF=$RPI_TOOLS_DIR/arm-bcm2708/arm-linux-gnueabihf
ENV RPI_BIN=$RPI_STUFF/bin
ENV RPI_SYSROOT=$RPI_STUFF/arm-linux-gnueabihf/sysroot

COPY VERSION /
