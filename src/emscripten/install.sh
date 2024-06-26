#!/bin/bash

set -e

rm -rf /var/lib/apt/lists/*

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

apt_get_update() {
    if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update -y
    fi
}

# Checks if packages are installed and installs them if not
check_packages() {
    if ! dpkg -s "$@" >/dev/null 2>&1; then
        apt_get_update
        apt-get -y install --no-install-recommends "$@"
    fi
}

updaterc() {
    if [ "${UPDATE_RC}" = "true" ]; then
        echo "Updating /etc/bash.bashrc and /etc/zsh/zshrc..."

        if [[ "$(cat /etc/bash.bashrc)" != *"$1"* ]]; then
            echo -e "$1" >> /etc/bash.bashrc
        fi

        if [ -f "/etc/zsh/zshrc" ] && [[ "$(cat /etc/zsh.zshrc)" != *"$1"* ]]; then
            echo -e "$1" >> /etc/zsh/zshrc
        fi
    fi
}

export DEBIAN_FRONTEND=noninteractive

architecture="$(uname -m)"

if [ "${architecture}" != "amd64" ] && [ "${architecture}" != "x86_64" ] && [ "${architecture}" != "arm64" ] && [ "${architecture}" != "aarch64" ]; then
    echo "(!) Architecture $architecture unsupported"
    exit 1
fi

check_packages \
    curl \
    ca-certificates \
    zip \
    unzip \
    xz-utils \
    bzip2 \
    sed \
    git-core \
    python3

if [ ! -d "${EMSDK_DIR}" ]; then
    echo "Creating ${EMSDK_DIR} directory"
    mkdir -p "${EMSDK_DIR}"

    echo "Cloning the emsdk"
    git clone "https://github.com/emscripten-core/emsdk.git" ${EMSDK_DIR}

    echo "Installing the ${VERSION} EMSDK"
    ${EMSDK_DIR}/emsdk install ${VERSION}

    echo "Activating the ${VERSION} EMSDK"
    ${EMSDK_DIR}/emsdk activate ${VERSION}

    updaterc "export EMSDK_DIR=${EMSDK_DIR}\nsource ${EMSDK_DIR}/emsdk_env.sh"
    source ${EMSDK_DIR}/emsdk_env.sh
fi

rm -rf /var/lib/apt/lists/*
