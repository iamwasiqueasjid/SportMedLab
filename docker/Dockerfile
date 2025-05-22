FROM dart:stable AS flutter

# Install required packages
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    default-jdk \
    wget \
    && apt-get clean

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git -b stable /flutter

# Set Flutter and Dart paths
ENV PATH="/flutter/bin:/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Install Android command line tools
ENV ANDROID_SDK_ROOT=/opt/android-sdk
RUN mkdir -p $ANDROID_SDK_ROOT/cmdline-tools && \
    cd $ANDROID_SDK_ROOT/cmdline-tools && \
    wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip -O tools.zip && \
    unzip tools.zip -d temp && \
    mkdir latest && \
    mv temp/cmdline-tools/* latest/ && \
    rm -rf temp tools.zip

ENV PATH="${PATH}:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools"

# Install required Android SDK components
RUN yes | sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --licenses && \
    sdkmanager --sdk_root=${ANDROID_SDK_ROOT} \
      "platform-tools" \
      "platforms;android-33" \
      "build-tools;33.0.2"

# Run flutter doctor to finalize setup
RUN flutter doctor

WORKDIR /app

# Copy and resolve dependencies
COPY pubspec.* ./
RUN flutter pub get

COPY . .

# Precache Android SDK
RUN flutter precache --android

CMD ["flutter", "build", "apk", "--debug"]

