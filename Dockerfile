FROM ubuntu:20.04

RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        clang \
        debhelper \
        libgstreamer-plugins-base1.0-dev \
        libcsound64-dev \
        libdav1d-dev \
        libpango1.0-dev \
&& rm -rf /var/lib/apt/lists/*
        
RUN cargo install cargo-deb

#ARG GIT_REPO=https://gitlab.freedesktop.org/gstreamer/gst-plugins-rs.git
#ARG GIT_BRANCH=main
#RUN git clone --depth 1 -b $GIT_BRANCH $GIT_REPO \
        && cd gst-plugins-rs \
        && cargo build -p gst-plugin-spotify --release --no-default-features

COPY VERSION /
COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
