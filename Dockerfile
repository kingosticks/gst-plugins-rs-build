FROM debian:bullseye-slim

RUN dpkg --add-architecture armhf

RUN apt-get update \
        && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        clang \
        curl ca-certificates \
        debhelper \
        git \
        pkg-config \
        gcc-arm-linux-gnueabihf \
        libgstreamer-plugins-base1.0-dev:armhf \
        && rm -rf /var/lib/apt/lists/*

ENV RPI_TOOLS_DIR=/rpi-tools
RUN git clone --depth=1 https://github.com/raspberrypi/tools $RPI_TOOLS_DIR && rm -rf $RPI_TOOLS_DIR/.git

RUN ln -s /gst-plugins-rs/target /target

COPY VERSION /
