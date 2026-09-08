FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive
ARG FLUTTER_VERSION=3.35.1

ENV FLUTTER_HOME=/opt/flutter
ENV PATH=${FLUTTER_HOME}/bin:${FLUTTER_HOME}/bin/cache/dart-sdk/bin:${PATH}

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    clang \
    cmake \
    curl \
    default-jdk \
    libcurl4-openssl-dev \
    file \
    git \
    libgtk-3-dev \
    libgstreamer-plugins-base1.0-dev \
    libgstreamer1.0-dev \
    libmpv-dev \
    libunwind-dev \
    make \
    ninja-build \
    pkg-config \
    unzip \
    xz-utils \
    zip \
    && rm -rf /var/lib/apt/lists/*

# Flutter's archive preserves its source-control ownership. Mark both the SDK
# and bind-mounted workspace as trusted for Git in the container.
RUN curl --fail --location --retry 3 \
      "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
      --output /tmp/flutter.tar.xz \
    && tar -xJf /tmp/flutter.tar.xz --directory /opt \
    && rm /tmp/flutter.tar.xz \
    && git config --system --add safe.directory /opt/flutter \
    && git config --system --add safe.directory /workspaces/jackbox-launcher \
    && flutter config --no-analytics --enable-linux-desktop \
    && flutter precache --linux \
    && flutter doctor -v

WORKDIR /workspaces/jackbox-launcher
