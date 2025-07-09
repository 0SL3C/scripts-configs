#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Creating a temporary directory..."
# Create a temporary directory and store its path in a variable.
# The 'trap' command ensures that this directory is removed when the script exits,
# for any reason (success or failure).
WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

# Change into the temporary directory.
cd "$WORK_DIR"

echo "Downloading the latest Zen Browser version..."
# Download the .tar.xz file from the official GitHub release page.
# -L follows redirects.
curl -L 'https://github.com/zen-browser/desktop/releases/latest/download/zen.linux-x86_64.tar.xz' -o zen-browser.tar.xz

echo "Extracting files..."
# Extract the contents of the downloaded archive. The 'J' flag is for .xz files.
tar -xJf zen-browser.tar.xz

echo "Installing Zen Browser update..."
# The following commands require root privileges, which is why the script
# must be run with 'sudo'.

# Remove the old installation to ensure a clean update.
echo "Removing old version from /opt/zen-browser..."
rm -rf /opt/zen-browser

# Move the newly extracted folder to /opt/.
# The archive extracts to a folder named 'zen'.
echo "Installing new version to /opt/zen-browser..."
mv zen /opt/zen-browser

echo "Zen Browser has been updated successfully!"
echo "You can now start Zen Browser."
