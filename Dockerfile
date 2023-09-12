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
ARG RPI_TOOLS=$RPI_TOOLS_DIR/arm-bcm2708/arm-linux-gnueabihf/bin/arm-linux-gnueabihf

RUN mkdir -p ~/.cargo/
RUN touch ~/.cargo/config
RUN echo "[target.arm-unknown-linux-gnueabihf]\nobjcopy = { path = \"$RPI_TOOLS-objcopy\" }\nstrip = { path = \"$RPI_TOOLS-strip\" }" > ~/.cargo/config

COPY VERSION /
