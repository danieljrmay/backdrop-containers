#!/usr/bin/bash
#
# explore-pod-container-backdrop-production
#
# Author: Daniel J. R. May
#
# Launch a bash session in the backdrop container of the pod.
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
echo "BACKDROP_CONTAINER=$BACKDROP_CONTAINER"
echo

# Echo the commands as this script executes and exit immediately if
# any command fails.
set -x

# Execute bash in the container.
podman exec --interactive --tty "$BACKDROP_CONTAINER" /usr/bin/bash
