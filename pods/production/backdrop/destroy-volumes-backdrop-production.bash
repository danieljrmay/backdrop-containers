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
: "${ENVIRONMENT_FILE:=backdrop-production.env}"

# Echo the variables used by this script starting with the environment file.
echo -e "Variables used by $(basename "$0"):\n"
echo "ENVIRONMENT_FILE=$ENVIRONMENT_FILE"

# Source the environment file.
# shellcheck source=backdrop-production.env
source "$ENVIRONMENT_FILE"

# Echo the values of the variables used by this script.
echo "MARIADB_DATA_VOLUME=$MARIADB_DATA_VOLUME"
echo "BACKDROP_CONFIG_VOLUME=$BACKDROP_CONFIG_VOLUME"
echo "BACKDROP_PRIVATE_FILES_VOLUME=$BACKDROP_PRIVATE_FILES_VOLUME"
echo "BACKDROP_PUBLIC_FILES_VOLUME=$BACKDROP_PUBLIC_FILES_VOLUME"
echo

# Remove a volume if it exists.
function destroy_existing_volume {
	if podman volume exists "$1"; then
		podman volume rm "$1"
	fi
}

# Echo the commands as this script executes.
set -x

# Destroy existing volumes.
destroy_existing_volume "$MARIADB_DATA_VOLUME"
destroy_existing_volume "$BACKDROP_CONFIG_VOLUME"
destroy_existing_volume "$BACKDROP_PRIVATE_FILES_VOLUME"
destroy_existing_volume "$BACKDROP_PUBLIC_FILES_VOLUME"
