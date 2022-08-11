#!/usr/bin/bash
#
# create-pod-backdrop-production
#
# Author: Daniel J. R. May
#
# This script creates a backdrop pod suitable for production made up
# of a backdrop container and a mariadb container.
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
echo "HIDE_PASSWORDS=$HIDE_PASSWORDS"
echo "POD=$POD"
echo "MARIADB_IMAGE=$MARIADB_IMAGE"
echo "MARIADB_CONTAINER=$MARIADB_CONTAINER"
echo "MARIADB_DATA_VOLUME=$MARIADB_DATA_VOLUME"
echo "MARIADB_SECRET_NAME=$MARIADB_SECRET_NAME"
echo "MARIADB_CONTAINER_HOSTNAME=$MARIADB_CONTAINER_HOSTNAME"
if [ "$HIDE_PASSWORDS" = false ]; then
	echo "MARIADB_ROOT_PASSWORD=$MARIADB_ROOT_PASSWORD"
	echo "MYSQL_PASSWORD=$MYSQL_PASSWORD"
fi
echo "BACKDROP_IMAGE=$BACKDROP_IMAGE"
echo "BACKDROP_CONTAINER=$BACKDROP_CONTAINER"
echo "BACKDROP_CONFIG_VOLUME=$BACKDROP_CONFIG_VOLUME"
echo "BACKDROP_PRIVATE_FILES_VOLUME=$BACKDROP_PRIVATE_FILES_VOLUME"
echo "BACKDROP_PUBLIC_FILES_VOLUME=$BACKDROP_PUBLIC_FILES_VOLUME"
echo "BACKDROP_SECRET_NAME=$BACKDROP_SECRET_NAME"
echo "BACKDROP_CONTAINER_HOSTNAME=$BACKDROP_CONTAINER_HOSTNAME"
echo "PORT=$PORT"
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

# Create the maraidb secret variable.
mariadb_secret=$(
	cat <<EOF
MARIADB_ROOT_PASSWORD=$MARIADB_ROOT_PASSWORD
MYSQL_PASSWORD=$MYSQL_PASSWORD
BACKDROP_DATABASE_NAME=$BACKDROP_DATABASE_NAME
BACKDROP_DATABASE_USER=$BACKDROP_DATABASE_USER
BACKDROP_DATABASE_PASSWORD=$BACKDROP_DATABASE_PASSWORD
EOF
)

# Create the backdrop secret variable.
backdrop_secret=$(
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

# Echo the commands as this script executes and exit immediately if
# any command fails.
set -x

# Exit if the pod already exists.
podman pod exists "$POD" && exit 1

# Check the images exist.
podman image exists "$MARIADB_IMAGE"
podman image exists "$BACKDROP_IMAGE"

# Create volumes if they do not exist.
if ! podman volume exists "$MARIADB_DATA_VOLUME"; then
	podman volume create "$MARIADB_DATA_VOLUME"
fi

if ! podman volume exists "$BACKDROP_CONFIG_VOLUME"; then
	podman volume create "$BACKDROP_CONFIG_VOLUME"
fi

if ! podman volume exists "$BACKDROP_PRIVATE_FILES_VOLUME"; then
	podman volume create "$BACKDROP_PRIVATE_FILES_VOLUME"
fi

if ! podman volume exists "$BACKDROP_PUBLIC_FILES_VOLUME"; then
	podman volume create "$BACKDROP_PUBLIC_FILES_VOLUME"
fi

# Remove any pre-existing secrets, but do not exit with an error if
# there is no matching pre-existing secret.
podman secret rm "$MARIADB_SECRET_NAME" || true
podman secret rm "$BACKDROP_SECRET_NAME" || true

# Temporarily turn off command echoing (so we do not reveal any
# secrets), create the secrets and then turn command echoing back on
# again.
set +x
echo "Creating the $MARIADB_SECRET_NAME secret…"
echo "$mariadb_secret" | podman secret create "$MARIADB_SECRET_NAME" -
echo "Creating the $BACKDROP_SECRET_NAME secret…"
echo "$backdrop_secret" | podman secret create "$BACKDROP_SECRET_NAME" -
set -x

# Create the pod.
podman pod create \
	--name "$POD" \
	--publish "$PORT:80" \
	--network bridge

# Create and start the mariadb container.
podman run \
	--pod "$POD" \
	--name "$MARIADB_CONTAINER" \
	--secret source="$MARIADB_SECRET_NAME",type=mount,mode=400,target=mariadb-production-fedora \
	--volume "$MARIADB_DATA_VOLUME":/var/lib/mysql \
	--detach \
	"$MARIADB_IMAGE"

#	--hostname "$MARIADB_CONTAINER_HOSTNAME" \

# Temporarily turn off command echoing (to prevent noisy output) while
# we monitor the mariadb container's startup, before turning it on
# again.
set +x
echo -n 'Waiting for the mariadb container to finish starting up.'
while true; do
	sleep 1s

	if podman exec "$MARIADB_CONTAINER" /usr/bin/test -e /var/lock/mariadb-production-fedora-firstboot.lock; then
		echo -e "\n"
		break
	else
		echo -n '.'
	fi

	if podman exec "$MARIADB_CONTAINER" /usr/bin/systemctl is-failed mariadb.service mariadb-production-fedora-firstboot.service >/dev/null; then
		echo -e "\nERROR: mariadb container startup has failed. Please check the container logs."
		exit 1
	fi
done
set -x

# Create and start the backdrop container.
podman run \
	--pod "$POD" \
	--name "$BACKDROP_CONTAINER" \
	--secret source="$BACKDROP_SECRET_NAME",type=mount,mode=400,target=backdrop-production-fedora \
	--volume "$BACKDROP_CONFIG_VOLUME":/etc/backdrop \
	--volume "$BACKDROP_PRIVATE_FILES_VOLUME":/var/lib/backdrop/private_files \
	--volume "$BACKDROP_PUBLIC_FILES_VOLUME":/var/lib/backdrop/public_files \
	--detach \
	"$BACKDROP_IMAGE"

# 	--publish "$PORT:80" \
# 	--hostname "$BACKDROP_CONTAINER_HOSTNAME" \

# Turn off command echoing.
set +x

# Monitor the container's startup.
echo -n 'Waiting for the backdrop container to finish starting up.'
while true; do
	sleep 1s

	if ! podman exec "$BACKDROP_CONTAINER" /usr/bin/systemctl is-active httpd.service >/dev/null; then
		echo -n '.'
		continue
	fi

	if podman exec "$BACKDROP_CONTAINER" /usr/bin/systemctl is-failed backdrop-add-on-dev-fedora-firstboot.service backdrop-install.service >/dev/null; then
		echo -e "\nERROR: backdrop installation has failed. Please check the container logs."
		exit 1
	fi

	break
done

echo -e "\nYour pod should be available at http://localhost:${PORT} now."
