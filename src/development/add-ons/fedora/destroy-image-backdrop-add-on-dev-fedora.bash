#!/usr/bin/bash
#
# destroy-image-backdrop-add-on-dev-fedora
#
# Author: Daniel J. R. May
#
# This script deletes the container image.
#
# For more information (or to report issues) go to
# https://github.com/danieljrmay/backdrop-containers

# Exit immediately if any command fails.
set -e

# Set the default environment file path. This syntax allows this
# default value to be overridden by an environment variable set before
# this script executes.
: "${ENVIRONMENT_FILE:=backdrop-add-on-dev-fedora.env}"

# Echo the environment file used by this script.
echo -e "Variables used by $(basename "$0"):\n"
echo "ENVIRONMENT_FILE=$ENVIRONMENT_FILE"

# Source the environment file.
# shellcheck source=backdrop-add-on-dev-fedora.env
source "$ENVIRONMENT_FILE"

# Echo the values of the variables used by this script.
echo "IMAGE_NAME=$IMAGE_NAME"

# Echo the commands as this script executes and exit immediately if
# any command fails.
set -ex

# Remove the container image.
buildah rmi "$IMAGE_NAME"
