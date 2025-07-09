#!/bin/bash

# Set JAVA_HOME to Java 8
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk
export PATH=$JAVA_HOME/bin:$PATH

# Set Android SDK root (adjust if necessary)
export ANDROID_SDK_ROOT=/opt/android-sdk
export PATH=$ANDROID_SDK_ROOT/emulator:$ANDROID_SDK_ROOT/tools:$ANDROID_SDK_ROOT/tools/bin:$PATH

# Force emulator to use X11 backend (for Wayland systems)
export QT_QPA_PLATFORM=xcb

# List available AVDs
echo "Listing available AVDs:"
emulator -list-avds

# Run the AVD (replace 'my_avd' with your AVD name)
echo "Running AVD..."
emulator -avd my_avd -gpu host
