#!/usr/bin/bash
#
# backdrop-install
#
# Author: Daniel J. R. May
#
# This script installs backdrop using environment variables for
# configuration. This script should be called only once per backdrop
# site instance.
#
# For more information (or to report issues) go to
# https://github.com/danieljrmay/backdrop-rpm

# Exit immediately on error.
set -e

# Readonly variables used by this script.
declare -r identifier='backdrop-install'
declare -r lock_path='/var/lib/backdrop/private_files/backdrop-install.lock'

# Check that this script has not already run, by checking for a lock
# file.
if [ -f "$lock_path" ]; then
	systemd-cat --identifier=$identifier --priority=warning \
		echo "Lock file $lock_path already exists, exiting."
	exit 1
fi

# Exit if backdrop installation is to be skipped.
if [ "$SKIP_BACKDROP_INSTALLATION" = true ]; then
	systemd-cat --identifier=$identifier --priority=notice \
		echo "Backdrop installation has been skipped."
	exit
fi

# Install backdrop via the command line.
/usr/bin/php /usr/share/backdrop/core/scripts/install.sh \
	--root=/usr/share/backdrop \
	--account-mail="$BACKDROP_ACCOUNT_MAIL" \
	--account-name="$BACKDROP_ACCOUNT_NAME" \
	--account-pass="$BACKDROP_ACCOUNT_PASSWORD" \
	--clean-url="$BACKDROP_CLEAN_URL" \
	--db-url="mysql://$BACKDROP_DATABASE_USER:$BACKDROP_DATABASE_PASSWORD@$BACKDROP_DATABASE_HOST/$BACKDROP_DATABASE_NAME" \
	--langcode="$BACKDROP_LANGCODE" \
	--site-mail="$BACKDROP_SITE_MAIL" \
	--site-name="$BACKDROP_SITE_NAME"

# Create a lock file to prevent re-running this script.
if touch $lock_path; then
	systemd-cat \
		--identifier=$identifier \
		echo "Created $lock_path to prevent the re-running of this script."
else
	systemd-cat \
		--identifier=$identifier \
		--priority=error \
		echo "Failed to create $lock_path so exiting."
	exit 1
fi
