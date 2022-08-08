#!/usr/bin/bash
#
# create-container-backdrop-add-on-dev-fedora
#
# Author: Daniel J. R. May
#
# This script creates a container suitable for backdrop add-on
# development based on the backdrop-add-on-dev-fedora image.
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
echo "IMAGE=$IMAGE"
echo "CONTAINER=$CONTAINER"
echo "SECRET_NAME=$SECRET_NAME"
echo "SECRET_FILE=$SECRET_FILE"
echo "CONTAINER_HOSTNAME=$CONTAINER_HOSTNAME"
echo "HOST_CUSTOM_MODULES_DIR=$HOST_CUSTOM_MODULES_DIR"
echo "HOST_CUSTOM_THEMES_DIR=$HOST_CUSTOM_THEMES_DIR"
echo "PORT=$PORT"

# Echo the commands as this script executes and exit immediately if
# any command fails.
set -ex

# Check base image exists.
podman image exists "$IMAGE"

# Remove any pre-existing secret, but do not exit with an error if
# there is no matching pre-existing secret.
podman secret rm "$SECRET_NAME" || true

# Create the secret.
podman secret create "$SECRET_NAME" "$SECRET_FILE"

# Create and start the container.
podman run \
	--name "$CONTAINER" \
	--secret source="$SECRET_NAME",type=mount,mode=400,target=backdrop-add-on-dev-fedora \
	--volume "$HOST_CUSTOM_MODULES_DIR":/var/www/html/modules/custom:ro,z \
	--volume "$HOST_CUSTOM_THEMES_DIR":/var/www/html/themes/custom:ro,z \
        --hostname "$CONTAINER_HOSTNAME" \
	--publish "$PORT:80" \
	--detach \
	"$IMAGE"

# Turn off command echoing.
set -

echo "Your container should be available at http://localhost:${PORT} in a few seconds."
