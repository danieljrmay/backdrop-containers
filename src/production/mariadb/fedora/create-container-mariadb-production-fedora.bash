#!/usr/bin/bash
#
# create-container-mariadb-production-fedora
#
# Author: Daniel J. R. May
#
# This script creates a mariadb container suitable for backdrop
# production containers.
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
# shellcheck source=mariadb-production-fedora.env
source "$ENVIRONMENT_FILE"

# Echo the values of the variables used by this script.
echo "HIDE_PASSWORDS=$HIDE_PASSWORDS"
echo "IMAGE=$IMAGE"
echo "CONTAINER=$CONTAINER"
echo "DATA_VOLUME=$DATA_VOLUME"
echo "SECRET_NAME=$SECRET_NAME"
echo "CONTAINER_HOSTNAME=$CONTAINER_HOSTNAME"
if [ "$HIDE_PASSWORDS" = false ]; then
	echo "MARIADB_ROOT_PASSWORD=$MARIADB_ROOT_PASSWORD"
	echo "MYSQL_PASSWORD=$MYSQL_PASSWORD"
fi
echo "BACKDROP_DATABASE_NAME=$BACKDROP_DATABASE_NAME"
echo "BACKDROP_DATABASE_USER=$BACKDROP_DATABASE_USER"
if [ "$HIDE_PASSWORDS" = false ]; then
	echo "BACKDROP_DATABASE_PASSWORD=$BACKDROP_DATABASE_PASSWORD"
fi
echo

# Create the secret variable.
secret=$(
	cat <<EOF
MARIADB_ROOT_PASSWORD=$MARIADB_ROOT_PASSWORD
MYSQL_PASSWORD=$MYSQL_PASSWORD
BACKDROP_DATABASE_NAME=$BACKDROP_DATABASE_NAME
BACKDROP_DATABASE_USER=$BACKDROP_DATABASE_USER
BACKDROP_DATABASE_PASSWORD=$BACKDROP_DATABASE_PASSWORD
EOF
)

# Echo the commands as this script executes.
set -x

# Check base image exists.
podman image exists "$IMAGE"

# Create the data volume if it does not exist.
if ! podman volume exists "$DATA_VOLUME"; then
	podman volume create "$DATA_VOLUME"
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
	--secret source="$SECRET_NAME",type=mount,mode=400,target=mariadb-production-fedora \
	--volume "$DATA_VOLUME":/var/lib/mysql \
	--hostname "$CONTAINER_HOSTNAME" \
	--detach \
	"$IMAGE"
