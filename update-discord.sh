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

echo "Downloading the latest Discord version..."
# Download the .tar.gz file from Discord's API endpoint for the Linux version.
# -L follows redirects.
curl -L 'https://discord.com/api/download?platform=linux&format=tar.gz' -o discord.tar.gz

echo "Extracting files..."
# Extract the contents of the downloaded archive.
tar -xzf discord.tar.gz

echo "Installing Discord update..."
# The following commands require root privileges, which is why the script
# must be run with 'sudo'.

# Remove the old installation to ensure a clean update.
echo "Removing old version from /opt/discord..."
rm -rf /opt/discord

# Move the newly extracted 'Discord' folder to /opt/.
echo "Installing new version to /opt/discord..."
mv Discord /opt/discord

echo "Discord has been updated successfully!"
echo "You can now start Discord as usual."
