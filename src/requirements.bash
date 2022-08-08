#!/usr/bin/bash
#
# install-requirements.bash
#
# Author: Daniel J. R. May
# Date: 28 July 2022
#
# Install the programs used by the backdrop-containers scripts.
#
# See https://github.com/danieljrmay/backdrop-containers for more
# information.

# Echo the commands as this script executes and exit immediately if
# any command fails.
set -ex

sudo dnf install buildah podman

