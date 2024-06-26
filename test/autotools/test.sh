#!/bin/bash

set -e

# Import test library for `check` command
source dev-container-features-test-lib

autoconf --version
autoreconf --version
pkg-config --version
