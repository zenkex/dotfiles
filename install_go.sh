#!/bin/bash

# ==========================================
# Function: Display Help Message
# ==========================================
show_help() {
    cat <<EOF
Usage: $(basename "$0") <Go-Version>
       $(basename "$0") -h | --help

Description:
    Automated script to install or upgrade Go (Golang) on Linux.
    It downloads the specified version from golang.google.cn,
    extracts it to /usr/local, and configures environment variables.

Arguments:
    <Go-Version>    The version number to install (e.g., 1.22.1)

    -h, --help      Show this help message and exit

Examples:

    sudo ./install_go.sh 1.22.1
    sudo ./install_go.sh 1.21.5

Note:
    This script requires sudo privileges to write to /usr/local and /etc/profile.

EOF
}

# ==========================================
# Main Logic
# ==========================================

# 1. Check for Help flag or Empty argument
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    show_help
    exit 0
fi

if [ -z "$1" ]; then
    echo "Error: Missing version number."
    echo "Try '$(basename "$0") --help' for more information."
    exit 1
fi

# Define Go version from the first argument
GO_VERSION="$1"
GO_ARCHIVE="go$GO_VERSION.linux-amd64.tar.gz"

# Check if script is run as root (Optional but recommended)

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (sudo)"
    exit 1
fi

# Check if /usr/local/go exists
if [ -d "/usr/local/go" ]; then
    echo "Existing Go installation detected."
    # Use full path for safety if go is not in path yet
    if command -v go &>/dev/null; then
        CURRENT_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
    else
        CURRENT_VERSION="unknown"
    fi

    if [ "$CURRENT_VERSION" == "$GO_VERSION" ]; then
        echo "Go $GO_VERSION is already installed. No action needed."
        exit 0
    else

        echo "Current version: $CURRENT_VERSION"
        echo "Removing existing Go installation..."
        rm -rf /usr/local/go

    fi
fi

echo "Installing Go version $GO_VERSION..."

# Download and extract Go

# Added -q for quiet wget output, remove if you want to see progress bar
if wget -q --show-progress https://golang.google.cn/dl/$GO_ARCHIVE; then
    tar -C /usr/local -xzf $GO_ARCHIVE
    rm $GO_ARCHIVE
else

    echo "Failed to download Go version $GO_VERSION. Please check if the version is correct and available."
    exit 1
fi

# ==========================================
# Environment Variables Configuration
# IMPROVED: Prevent duplicate entries
# ==========================================
PROFILE_FILE="/etc/profile"

echo "Configuring environment variables..."

# Helper function to append only if not exists

add_env_var() {
    local key="$1"
    local value="$2"
    if ! grep -q "$value" "$PROFILE_FILE"; then
        echo "$value" >>"$PROFILE_FILE"
        echo "Added $key to $PROFILE_FILE"
    else
        echo "$key configuration already exists in $PROFILE_FILE"
    fi
}

add_env_var "GOROOT" "export GOROOT=/usr/local/go"
add_env_var "GOPATH" "export GOPATH=\$HOME/.gopath"
# Check PATH slightly differently to avoid strict string matching issues

if ! grep -q "export PATH=.*\$GOROOT/bin" "$PROFILE_FILE"; then

    echo "export PATH=\$PATH:\$GOROOT/bin:\$GOPATH/bin" >>"$PROFILE_FILE"
    echo "Added Go bin to PATH"
fi

# Source the profile (Note: This only affects the current script execution, not the user's shell)
source /etc/profile

# Display Go version
# Using full path to ensure we check the newly installed binary
if /usr/local/go/bin/go version; then
    echo "Go $GO_VERSION has been successfully installed."

    # Configure Proxy
    /usr/local/go/bin/go env -w GOPROXY=https://goproxy.cn,direct
    /usr/local/go/bin/go env -w GO111MODULE=on

    echo "----------------------------------------------------"
    echo "IMPORTANT: To apply changes to your current shell,"
    echo "please run the following command manually:"
    echo "source /etc/profile"
    echo "----------------------------------------------------"
else

    echo "Go installation seems to have failed."
    exit 1
fi
