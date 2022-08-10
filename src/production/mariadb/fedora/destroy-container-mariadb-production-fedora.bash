#!/usr/bin/bash
#
# destory-container-mariadb-production-fedora
#
# Author: Daniel J. R. May
#
# Stop and remove a container.
#
# For more information (or to report issues) go to
# https://github.com/danieljrmay/backdrop-containers

# Exit immediately if any command fails.
set -e

# Set the default environment file path. This syntax allows this
# default value to be overridden by an environment variable set before
# this script executes.
: "${ENVIRONMENT_FILE:=mariadb-production-fedora.env}"

# Echo the environment file used by this script.
echo -e "Variables used by $(basename "$0"):\n"
echo "ENVIRONMENT_FILE=$ENVIRONMENT_FILE"

# Source the environment file.
# shellcheck source=mariadb-production-fedora.env
source "$ENVIRONMENT_FILE"

# Echo the values of the variables used by this script.
echo "CONTAINER=$CONTAINER"
echo

# Echo the commands as this script executes.
set -x

# Stop and remove the container.
podman stop "$CONTAINER"
podman rm "$CONTAINER"
