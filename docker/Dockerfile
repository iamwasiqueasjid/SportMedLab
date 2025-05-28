# Use a more specific version tag instead of 'stable'
FROM dart:3.2.3 AS flutter

# Combine RUN commands and clean up in the same layer
# Update packages and remove cached files
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    default-jdk \
    wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/cache/apt/*

# Add retry logic and cleanup for Flutter installation
RUN until git clone --depth 1 https://github.com/flutter/flutter.git -b stable /flutter; do \
    echo "Retrying..."; \
    sleep 5; \
    done \
    && flutter precache --no-android --no-ios

# Set Flutter and Dart paths
ENV PATH="/flutter/bin:/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Install Android command line tools
ENV ANDROID_SDK_ROOT=/opt/android-sdk
RUN mkdir -p $ANDROID_SDK_ROOT/cmdline-tools

