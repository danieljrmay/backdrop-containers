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

# Exit immediately if any command fails.
set -e

# Set the default environment file path. This syntax allows this
# default value to be overridden by an environment variable set before
# this script executes.
: "${ENVIRONMENT_FILE:=backdrop-add-on-dev-fedora.env}"

# Echo the variables used by this script starting with the environment file.
echo -e "Variables used by $(basename "$0"):\n"
echo "ENVIRONMENT_FILE=$ENVIRONMENT_FILE"

# Source the environment file.
# shellcheck source=backdrop-add-on-dev-fedora.env
source "$ENVIRONMENT_FILE"

# Echo the values of the variables used by this script.
echo "HIDE_PASSWORDS=$HIDE_PASSWORDS"
echo "OPEN_BROWSER=$OPEN_BROWSER"
echo "IMAGE=$IMAGE"
echo "CONTAINER=$CONTAINER"
echo "CONTAINER_HOSTNAME=$CONTAINER_HOSTNAME"
echo "HOST_CUSTOM_MODULES_DIR=$HOST_CUSTOM_MODULES_DIR"
echo "HOST_CUSTOM_THEMES_DIR=$HOST_CUSTOM_THEMES_DIR"
echo "PORT=$PORT"
echo "MARIADB_SECRET_NAME=$MARIADB_SECRET_NAME"
echo "HTTPD_SECRET_NAME=$HTTPD_SECRET_NAME"
echo "INSTALL_SECRET_NAME=$INSTALL_SECRET_NAME"
echo "SECURE_MARIADB=$SECURE_MARIADB"
if [ "$HIDE_PASSWORDS" = false ]; then
	echo "MARIADB_ROOT_AT_LOCALHOST_PASSWORD=$MARIADB_ROOT_AT_LOCALHOST_PASSWORD"
	echo "MARIADB_MYSQL_AT_LOCALHOST_PASSWORD=$MARIADB_MYSQL_AT_LOCALHOST_PASSWORD"
fi
echo "CREATE_BACKDROP_DATABASE=$CREATE_BACKDROP_DATABASE"
echo "BACKDROP_DATABASE_NAME=$BACKDROP_DATABASE_NAME"
echo "BACKDROP_DATABASE_USER=$BACKDROP_DATABASE_USER"
if [ "$HIDE_PASSWORDS" = false ]; then
	echo "BACKDROP_DATABASE_PASSWORD=$BACKDROP_DATABASE_PASSWORD"
fi
echo "CREATE_HTTPD_CONF=$CREATE_HTTPD_CONF"
echo "HTTPD_CONF_PATH=$HTTPD_CONF_PATH"
echo "HTTPD_CONF_TYPE=$HTTPD_CONF_TYPE"
echo "DOCUMENT_ROOT=$DOCUMENT_ROOT"
echo "MODIFY_SETTINGS_FILE=$MODIFY_SETTINGS_FILE"
echo "SETTINGS_FILE_PATH=$SETTINGS_FILE_PATH"
echo "SKIP_BACKDROP_INSTALLATION=$SKIP_BACKDROP_INSTALLATION"
echo "BACKDROP_DATABASE_HOST=$BACKDROP_DATABASE_HOST"
echo "BACKDROP_DATABASE_PREFIX=$BACKDROP_DATABASE_PREFIX"
echo "BACKDROP_ACCOUNT_NAME=$BACKDROP_ACCOUNT_NAME"
echo "BACKDROP_ACCOUNT_PASSWORD=$BACKDROP_ACCOUNT_PASSWORD"
echo "BACKDROP_ACCOUNT_MAIL=$BACKDROP_ACCOUNT_MAIL"
echo "BACKDROP_CLEAN_URL=$BACKDROP_CLEAN_URL"
echo "BACKDROP_LANGCODE=$BACKDROP_LANGCODE"
echo "BACKDROP_SITE_MAIL=$BACKDROP_SITE_MAIL"
echo "BACKDROP_SITE_NAME=$BACKDROP_SITE_NAME"
echo

# Create the secret variables.
mariadb_secret=$(
	cat <<EOF
SECURE_MARIADB=$SECURE_MARIADB
MARIADB_ROOT_AT_LOCALHOST_PASSWORD=$MARIADB_ROOT_AT_LOCALHOST_PASSWORD
MARIADB_MYSQL_AT_LOCALHOST_PASSWORD=$MARIADB_MYSQL_AT_LOCALHOST_PASSWORD
CREATE_BACKDROP_DATABASE=$CREATE_BACKDROP_DATABASE
BACKDROP_DATABASE_NAME=$BACKDROP_DATABASE_NAME
BACKDROP_DATABASE_USER=$BACKDROP_DATABASE_USER
BACKDROP_DATABASE_PASSWORD=$BACKDROP_DATABASE_PASSWORD
EOF
)
httpd_secret=$(
	cat <<EOF
CREATE_HTTPD_CONF=$CREATE_HTTPD_CONF
HTTPD_CONF_PATH=$HTTPD_CONF_PATH
HTTPD_CONF_TYPE=$HTTPD_CONF_TYPE
DOCUMENT_ROOT=$DOCUMENT_ROOT
MODIFY_SETTINGS_FILE=$MODIFY_SETTINGS_FILE
SETTINGS_FILE_PATH=$SETTINGS_FILE_PATH
PORT=$PORT
MODIFY_SETTINGS_FILE=$MODIFY_SETTINGS_FILE
SETTINGS_FILE_PATH=$SETTINGS_FILE_PATH
EOF
)
install_secret=$(
	cat <<EOF
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

# Remove any pre-existing secret, but do not error if no such secret
# exists.
podman secret rm "$MARIADB_SECRET_NAME" "$HTTPD_SECRET_NAME" "$INSTALL_SECRET_NAME" || true

# Temporarily turn off command echoing (so we do not reveal any
# secrets), create the secret and then turn command echoing back on
# again.
set +x
echo "Creating the $MARIADB_SECRET_NAME secret…"
echo "$mariadb_secret" | podman secret create "$MARIADB_SECRET_NAME" -
echo "Creating the $HTTPD_SECRET_NAME secret…"
echo "$httpd_secret" | podman secret create "$HTTPD_SECRET_NAME" -
echo "Creating the $INSTALL_SECRET_NAME secret…"
echo "$install_secret" | podman secret create "$INSTALL_SECRET_NAME" -
set -x

# Create and start the container.
podman run \
	--name "$CONTAINER" \
	--secret source="$MARIADB_SECRET_NAME",type=mount,mode=400,target="$MARIADB_SECRET_NAME" \
	--secret source="$HTTPD_SECRET_NAME",type=mount,mode=400,target="$HTTPD_SECRET_NAME" \
	--secret source="$INSTALL_SECRET_NAME",type=mount,mode=400,target="$INSTALL_SECRET_NAME" \
	--volume "$HOST_CUSTOM_MODULES_DIR":/usr/share/backdrop/modules/custom:ro,z \
	--volume "$HOST_CUSTOM_THEMES_DIR":/usr/share/backdrop/themes/custom:ro,z \
	--hostname "$CONTAINER_HOSTNAME" \
	--publish "$PORT:80" \
	--detach \
	"$IMAGE"

# Turn off command echoing.
set +x

# Monitor the container's startup.
echo -n 'Waiting for the container to finish installing backdrop.'
while true; do
	sleep 1s

	if ! podman exec "$CONTAINER" /usr/bin/systemctl is-active httpd.service >/dev/null; then
		echo -n '.'
		continue
	fi

	if podman exec "$CONTAINER" /usr/bin/systemctl is-failed \
		backdrop-configure-mariadb.service \
		backdrop-configure-httpd.service \
		backdrop-install.service >/dev/null; then
		echo -e "\nERROR: backdrop configuration or installation has failed. Please check the container logs."
		exit 1
	fi

	break
done

echo -e "\nYour container should be available at http://localhost:${PORT} now."

if [ "$OPEN_BROWSER" = true ]; then
	echo "Attempting to open http://localhost:${PORT} in your preferred browser."
	xdg-open http://localhost:$PORT
fi
