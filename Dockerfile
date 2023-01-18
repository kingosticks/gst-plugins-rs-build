FROM ubuntu:20.04

RUN apt-get update \
        && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        git \
        curl ca-certificates \
        clang \
        debhelper \
        libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
        pkg-config \
        && rm -rf /var/lib/apt/lists/*

RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
    
RUN cargo install cargo-deb

COPY VERSION /
COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
