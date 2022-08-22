#!/usr/bin/bash
#
# create-image-backdrop-add-on-dev-fedora
#
# Author: Daniel J. R. May
#
# This script creates a container image of backdrop suitable for
# add-on development on top of the latest fedora base image.
#
# For more information (or to report issues) go to
# https://github.com/danieljrmay/backdrop-containers

# Exit immediately if any command fails.
set -e

# Set the default environment file path. This syntax allows this
# default value to be overridden by an environment variable set before
# this script executes.
: "${ENVIRONMENT_FILE:=backdrop-add-on-dev-fedora.env}"

# Echo the variables used by this script, starting with the
# environment file.
echo -e "Variables used by $(basename "$0"):\n"
echo "ENVIRONMENT_FILE=$ENVIRONMENT_FILE"

# Source the environment file.
# shellcheck source=backdrop-add-on-dev-fedora.env
source "$ENVIRONMENT_FILE"

# Echo the values of the variables used by this script.
echo "BASE_IMAGE=$BASE_IMAGE"
echo "IMAGE_NAME=$IMAGE_NAME"
echo "WORKING_CONTAINER=$WORKING_CONTAINER"
echo "CONTRIB_MODULES=${CONTRIB_MODULES[*]}"
echo

# Echo the commands as this script executes and exit immediately if
# any command fails.
set -ex

# Get the latest fedora image, which serves as a base for our image.
buildah pull "$BASE_IMAGE"

# Create a new container based on the latest version of fedora which
# we will then customise.
buildah from --name "$WORKING_CONTAINER" "$BASE_IMAGE"

# Update the container and install all the packages we need.
buildah run "$WORKING_CONTAINER" -- dnf --assumeyes update
buildah run "$WORKING_CONTAINER" -- dnf --assumeyes install dnf-plugins-core
buildah run "$WORKING_CONTAINER" -- dnf --assumeyes copr enable danieljrmay/backdrop
buildah run "$WORKING_CONTAINER" -- dnf --assumeyes install \
	backdrop \
	backdrop-systemd \
	composer \
	git \
	mariadb-server \
	wget \
	zip
buildah run "$WORKING_CONTAINER" -- dnf --assumeyes clean all

# Create module/theme custom and contrib directories
buildah run "$WORKING_CONTAINER" -- mkdir -p \
	/usr/share/backdrop/modules/contrib \
	/usr/share/backdrop/modules/custom \
	/usr/share/backdrop/themes/contrib \
	/usr/share/backdrop/themes/custom

# Install bee.
buildah run "$WORKING_CONTAINER" -- git clone https://github.com/backdrop-contrib/bee.git /opt/bee
buildah run "$WORKING_CONTAINER" -- ln -s /opt/bee/bee.php /usr/local/bin/bee

# Download contrib modules.
buildah run "$WORKING_CONTAINER" -- bee --root=/usr/share/backdrop download "${CONTRIB_MODULES[@]}"

# Enable the systemd services which we want to run when container is started.
buildah run "$WORKING_CONTAINER" -- systemctl enable httpd.service
buildah run "$WORKING_CONTAINER" -- systemctl enable mariadb.service
buildah run "$WORKING_CONTAINER" -- systemctl enable php-fpm.service
buildah run "$WORKING_CONTAINER" -- systemctl enable backdrop-configure-mariadb.service
buildah run "$WORKING_CONTAINER" -- systemctl enable backdrop-configure-httpd.service
buildah run "$WORKING_CONTAINER" -- systemctl enable backdrop-install.service

# Expose port 80, the default HTTP port.
buildah config --port 80 "$WORKING_CONTAINER"

# Configure systemd init command as the command to get the container started.
buildah config --cmd "/usr/sbin/init" "$WORKING_CONTAINER"

# Save the container as an image.
buildah commit "$WORKING_CONTAINER" "$IMAGE_NAME"

# Delete the working container.
buildah rm "$WORKING_CONTAINER"
