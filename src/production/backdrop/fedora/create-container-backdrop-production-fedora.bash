#!/usr/bin/bash
#
# create-container-backdrop-production-fedora
#
# Author: Daniel J. R. May
#
# This script creates a container suitable for production based on the
# backdrop-production-fedora image.
#
# For more information (or to report issues) go to
# https://github.com/danieljrmay/backdrop-containers

# Exit immediately if any command fails.
set -e

# Set the default environment file path. This syntax allows this
# default value to be overridden by an environment variable set before
# this script executes.
: "${ENVIRONMENT_FILE:=backdrop-production-fedora.env}"

# Echo the variables used by this script starting with the environment file.
echo -e "Variables used by $(basename "$0"):\n"
echo "ENVIRONMENT_FILE=$ENVIRONMENT_FILE"

# Source the environment file.
# shellcheck source=backdrop-production-fedora.env
source "$ENVIRONMENT_FILE"

# Echo the values of the variables used by this script.
echo "HIDE_PASSWORDS=$HIDE_PASSWORDS"
echo "IMAGE=$IMAGE"
echo "CONTAINER=$CONTAINER"
echo "SECRET_NAME=$SECRET_NAME"
echo "CONTAINER_HOSTNAME=$CONTAINER_HOSTNAME"
echo "HOST_CUSTOM_MODULES_DIR=$HOST_CUSTOM_MODULES_DIR"
echo "HOST_CUSTOM_THEMES_DIR=$HOST_CUSTOM_THEMES_DIR"
echo "PORT=$PORT"
echo "BACKDROP_CONFIG_VOLUME=$BACKDROP_CONFIG_VOLUME"
echo "BACKDROP_PRIVATE_FILES_VOLUME=BACKDROP_PRIVATE_FILES_VOLUME"
echo "BACKDROP_PUBLIC_FILES_VOLUME=$BACKDROP_PUBLIC_FILES_VOLUME"
echo "SKIP_BACKDROP_INSTALLATION=$SKIP_BACKDROP_INSTALLATION"
echo "BACKDROP_DATABASE_NAME=$BACKDROP_DATABASE_NAME"
echo "BACKDROP_DATABASE_USER=$BACKDROP_DATABASE_USER"
if [ "$HIDE_PASSWORDS" = false ]; then
	echo "BACKDROP_DATABASE_PASSWORD=$BACKDROP_DATABASE_PASSWORD"
fi
echo "BACKDROP_DATABASE_HOST=$BACKDROP_DATABASE_HOST"
echo "BACKDROP_DATABASE_PREFIX=$BACKDROP_DATABASE_PREFIX"
echo "BACKDROP_ACCOUNT_NAME=$BACKDROP_ACCOUNT_NAME"
if [ "$HIDE_PASSWORDS" = false ]; then
	echo "BACKDROP_ACCOUNT_PASSWORD=$BACKDROP_ACCOUNT_PASSWORD"
fi
echo "BACKDROP_ACCOUNT_MAIL=$BACKDROP_ACCOUNT_MAIL"
echo "BACKDROP_CLEAN_URL=$BACKDROP_CLEAN_URL"
echo "BACKDROP_LANGCODE=$BACKDROP_LANGCODE"
echo "BACKDROP_SITE_MAIL=$BACKDROP_SITE_MAIL"
echo "BACKDROP_SITE_NAME=$BACKDROP_SITE_NAME"
echo

# Create the secret variable.
secret=$(
	cat <<EOF
PORT=$PORT
SKIP_BACKDROP_INSTALLATION=$SKIP_BACKDROP_INSTALLATION
BACKDROP_DATABASE_NAME=$BACKDROP_DATABASE_NAME
BACKDROP_DATABASE_USER=$BACKDROP_DATABASE_USER
BACKDROP_DATABASE_PASSWORD=$BACKDROP_DATABASE_PASSWORD
BACKDROP_DATABASE_HOST=$BACKDROP_DATABASE_HOST
BACKDROP_DATABASE_PREFIX=$BACKDROP_DATABASE_PREFIX
BACKDROP_ACCOUNT_NAME=$BACKDROP_ACCOUNT_NAME
BACKDROP_ACCOUNT_PASSWORD=$BACKDROP_ACCOUNT_PASSWORD
BACKDROP_ACCOUNT_MAIL=$BACKDROP_ACCOUNT_MAIL
BACKDROP_CLEAN_URL=$BACKDROP_CLEAN_URL
BACKDROP_LANGCODE=$BACKDROP_LANGCODE
BACKDROP_SITE_MAIL=$BACKDROP_SITE_MAIL
BACKDROP_SITE_NAME=$BACKDROP_SITE_NAME
EOF
)

# Echo the commands as this script executes.
set -x

# Check base image exists.
podman image exists "$IMAGE"

# Create volumes if they do not exist.
if ! podman volume exists "$BACKDROP_CONFIG_VOLUME"; then
	podman volume create "$BACKDROP_CONFIG_VOLUME"
fi

if ! podman volume exists "$BACKDROP_PRIVATE_FILES_VOLUME"; then
	podman volume create "$BACKDROP_PRIVATE_FILES_VOLUME"
fi

if ! podman volume exists "$BACKDROP_PUBLIC_FILES_VOLUME"; then
	podman volume create "$BACKDROP_PUBLIC_FILES_VOLUME"
fi

# Remove any pre-existing secret, but do not error if no such secret
# exists.
podman secret rm "$SECRET_NAME" || true

# Temporarily turn off command echoing (so we do not reveal any
# secrets), create the secret and then turn command echoing back on
# again.
set +x
echo "Creating the $SECRET_NAME secret…"
echo "$secret" | podman secret create "$SECRET_NAME" -
set -x

# Create and start the container.
podman run \
	--name "$CONTAINER" \
	--secret source="$SECRET_NAME",type=mount,mode=400,target=backdrop-production-fedora \
	--volume "$BACKDROP_CONFIG_VOLUME":/etc/backdrop \
	--volume "$BACKDROP_PRIVATE_FILES_VOLUME":/var/lib/backdrop/private_files \
	--volume "$BACKDROP_PUBLIC_FILES_VOLUME":/var/lib/backdrop/public_files \
	--hostname "$CONTAINER_HOSTNAME" \
	--publish "$PORT:80" \
	--detach \
	"$IMAGE"

# Turn off command echoing.
set -

echo "Your container should be available at http://localhost:${PORT} in a few seconds."
