#!/bin/bash

# Check if a version number is provided
if [ $# -eq 0 ]; then
    echo "Please provide a Go version number (e.g., 1.22.1)"
    exit 1
fi

# Define Go version from the first argument
GO_VERSION="$1"
GO_ARCHIVE="go$GO_VERSION.linux-amd64.tar.gz"

# Check if /usr/local/go exists
if [ -d "/usr/local/go" ]; then
    echo "Existing Go installation detected."
    CURRENT_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
    if [ "$CURRENT_VERSION" == "$GO_VERSION" ]; then
        echo "Go $GO_VERSION is already installed. No action needed."
        exit 0
    else
        echo "Current version: $CURRENT_VERSION"
        echo "Removing existing Go installation..."
        sudo rm -rf /usr/local/go
    fi
fi

echo "Installing Go version $GO_VERSION..."

# Download and extract Go
if wget https://golang.google.cn/dl/$GO_ARCHIVE; then
    sudo tar -C /usr/local -xzf $GO_ARCHIVE
    rm $GO_ARCHIVE
else
    echo "Failed to download Go version $GO_VERSION. Please check if the version is correct and available."
    exit 1
fi

# Configure Go environment variables
# Uncomment these lines if you want to modify /etc/profile
echo "export GOROOT=/usr/local/go" | sudo tee -a /etc/profile
echo "export GOPATH=\$HOME/.gopath" | sudo tee -a /etc/profile
echo "export PATH=\$PATH:\$GOROOT/bin:\$GOPATH/bin" | sudo tee -a /etc/profile

# Source the profile to apply changes
source /etc/profile

# Display Go version
if go version; then
    echo "Go $GO_VERSION has been successfully installed."
else
    echo "Go installation seems to have failed. Please check the error messages above."
    exit 1
fi

go env -w GOPROXY=https://goproxy.cn,direct
go env -w GO111MODULE=on
