#!/usr/bin/bash
#
# destory-volumes-backdrop-production-fedora
#
# Author: Daniel J. R. May
#
# Destroy the containers volumes.
#
# For more information (or to report issues) go to
# https://github.com/danieljrmay/backdrop-containers

# Exit immediately if any command fails.
set -e

# Set the default environment file path. This syntax allows this
# default value to be overridden by an environment variable set before
# this script executes.
: "${ENVIRONMENT_FILE:=mariadb-production-fedora.env}"

# Echo the variables used by this script starting with the environment file.
echo -e "Variables used by $(basename "$0"):\n"
echo "ENVIRONMENT_FILE=$ENVIRONMENT_FILE"

# Source the environment file.
# shellcheck source=backdrop-production-fedora.env
source "$ENVIRONMENT_FILE"

# Echo the values of the variables used by this script.
echo "DATA_VOLUME=$DATA_VOLUME"
echo

# Echo the commands as this script executes.
set -x

# Check the volume exists before removing it.
if podman volume exists "$BACKDROP_CONFIG_VOLUME"; then
	podman volume rm "$BACKDROP_CONFIG_VOLUME"
fi

if podman volume exists "$BACKDROP_PRIVATE_FILES_VOLUME"; then
	podman volume rm "$BACKDROP_PRIVATE_FILES_VOLUME"
fi

if podman volume exists "$BACKDROP_PUBLIC_FILES_VOLUME"; then
	podman volume rm "$BACKDROP_PUBLIC_FILES_VOLUME"
fi
