#!/usr/bin/bash
#
# destory-container-backdrop-add-on-dev-fedora
#
# Author: Daniel J. R. May
#
# Stop and remove a container.
#
# For more information (or to report issues) go to
# https://github.com/danieljrmay/backdrop-containers


# Set the default environment file path. This syntax allows this
# default value to be overridden by an environment variable set before
# this script executes.
: "${ENVIRONMENT_FILE:=backdrop-add-on-dev-fedora.env}"

# Echo the environment file used by this script.
echo "ENVIRONMENT_FILE=$ENVIRONMENT_FILE"

# Source the environment file.
# shellcheck source=backdrop-add-on-dev-fedora.env
source "$ENVIRONMENT_FILE"

# Echo the values of the variables used by this script.
echo "CONTAINER=$CONTAINER"

# Echo the commands as this script executes and exit immediately if
# any command fails.
set -ex

# Stop and remove the container.
podman stop "$CONTAINER"
podman rm "$CONTAINER"