#!/bin/bash

# Script to setup OpenJDK 21 (Amazon Corretto 21.0.1.12.1) on Ubuntu 22.04 LTS
# Requested Version: Corretto-21.0.1.12.1
# Confirmed Architecture: x86_64 (amd64 for Debian/Ubuntu packages)

set -e

CORRETTO_VERSION="21.0.1.12.1"
DEB_VERSION="21.0.1.12-1"

echo "Setup: OpenJDK 21.0.1 (Corretto 21.0.1.12.1) for Ubuntu 22.04 LTS (x86_64/amd64)"

# Detect Architecture
ARCH=$(uname -m)
if [ "$ARCH" != "x86_64" ]; then
    echo "Warning: Detected architecture is $ARCH, but script is specialized for x86_64."
fi

# Ubuntu/Debian x86_64 uses 'amd64' for package naming
DEB_FILE="java-21-amazon-corretto-jdk_${DEB_VERSION}_amd64.deb"
DOWNLOAD_URL="https://corretto.aws/downloads/resources/$CORRETTO_VERSION/$DEB_FILE"

echo "Downloading $DEB_FILE from official Corretto resources..."
curl -L -o "/tmp/$DEB_FILE" "$DOWNLOAD_URL"

echo "Updating package lists and installing prerequisites (java-common, coreutils, postgresql-client)..."
sudo apt-get update
# coreutils provides nohup, postgresql-client provides psql
sudo apt-get install -y java-common coreutils postgresql-client

echo "Installing Amazon Corretto 21 using dpkg/apt..."
# Using apt to install local deb handles any missing dependencies, though dpkg is also fine since we installed java-common
sudo apt-get install -y "/tmp/$DEB_FILE" || sudo dpkg -i "/tmp/$DEB_FILE"

# Clean up
rm "/tmp/$DEB_FILE"

# Verification
echo "Verifying installation output..."
java -version

# Set JAVA_HOME globally for all services/users
# Paths on Ubuntu using alternatives
JAVA_PATH=$(readlink -f /usr/bin/java | sed "s:/bin/java::")
echo "Setting JAVA_HOME to $JAVA_PATH in /etc/profile.d/java.sh"

sudo bash -c "cat <<EOF > /etc/profile.d/java.sh
export JAVA_HOME=$JAVA_PATH
export PATH=\$JAVA_HOME/bin:\$PATH
EOF"

sudo chmod +x /etc/profile.d/java.sh

echo "---------------------------------------------------------"
echo "Setup complete for Corretto $CORRETTO_VERSION (Ubuntu 22.04 / amd64)"
echo "Run 'source /etc/profile.d/java.sh' to update current shell."
echo "---------------------------------------------------------"
