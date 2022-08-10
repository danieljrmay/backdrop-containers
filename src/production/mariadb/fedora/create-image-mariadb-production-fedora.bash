#!/usr/bin/bash
#
# create-image-mariadb-production-fedora
#
# Author: Daniel J. R. May
#
# This script creates a container image of mariabe suitable for
# production on top of the latest fedora base image.
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
echo "BASE_IMAGE=$BASE_IMAGE"
echo "IMAGE_NAME=$IMAGE_NAME"
echo "WORKING_CONTAINER=$WORKING_CONTAINER"
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
# TODO change to microdnf
buildah run "$WORKING_CONTAINER" -- dnf --assumeyes update
buildah run "$WORKING_CONTAINER" -- dnf --assumeyes install mariadb-server
buildah run "$WORKING_CONTAINER" -- dnf --assumeyes clean all

# Copy files into working container.
buildah copy "$WORKING_CONTAINER" \
	systemd/mariadb-production-fedora-firstboot.bash \
	/usr/local/bin/mariadb-production-fedora-firstboot
buildah run "$WORKING_CONTAINER" -- chmod a+x /usr/local/bin/mariadb-production-fedora-firstboot
buildah copy "$WORKING_CONTAINER" \
	systemd/mariadb-production-fedora-firstboot.service \
	/etc/systemd/system/mariadb-production-fedora-firstboot.service

buildah copy "$WORKING_CONTAINER" \
	systemd/mariadb-production-fedora-maintenance.bash \
	/usr/local/bin/mariadb-production-fedora-maintenance
buildah run "$WORKING_CONTAINER" -- chmod a+x /usr/local/bin/mariadb-production-fedora-maintenance
buildah copy "$WORKING_CONTAINER" \
	systemd/mariadb-production-fedora-maintenance.service \
	/etc/systemd/system/mariadb-production-fedora-maintenance.service
buildah copy "$WORKING_CONTAINER" \
	systemd/mariadb-production-fedora-maintenance.timer \
	/etc/systemd/system/mariadb-production-fedora-maintenance.timer

# Enable the systemd services which we want to run when container is started.
buildah run "$WORKING_CONTAINER" -- systemctl enable mariadb.service
buildah run "$WORKING_CONTAINER" -- systemctl enable mariadb-production-fedora-firstboot.service
buildah run "$WORKING_CONTAINER" -- systemctl enable mariadb-production-fedora-maintenance.timer

# Configure systemd init command as the command to get the container started.
buildah config --cmd "/usr/sbin/init" "$WORKING_CONTAINER"

# Save the container as an image.
buildah commit "$WORKING_CONTAINER" "$IMAGE_NAME"

# Delete the working container.
buildah rm "$WORKING_CONTAINER"
