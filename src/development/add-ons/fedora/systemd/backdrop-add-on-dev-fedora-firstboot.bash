#!/usr/bin/bash
#
# backdrop-add-on-dev-fedora-firstboot
#
# Author: Daniel J. R. May
#
# This script creates an httpd configuration and mariadb database
# suitable for backdrop add-on development. This script should be
# called only once by the backdrop-add-on-dev-fedora-firstboot systemd
# service. It creates a lock file to prevent repeated executions.
#
# For more information (or to report issues) go to
# https://github.com/danieljrmay/backdrop-containers

# Exit immediately on error.
set -e

# Readonly variables used by this script.
declare -r identifier=backdrop-add-on-dev-fedora-firstboot
declare -r lock_path=/var/lock/backdrop-add-on-dev-fedora-firstboot.lock
declare -r httpd_conf_path=/etc/httpd/conf.d/backdrop-add-on-dev-fedora.conf

# Check that this script has not already run, by checking for a lock
# file.
if [ -f "$lock_path" ]; then
	systemd-cat --identifier=$identifier --priority=warning \
		echo "Lock file $lock_path already exists, exiting."
	exit 1
fi

# Create the Apache HTTPD server configuration file.
cat >$httpd_conf_path <<EOF
# Apache HTTP server configuration for the the
# backdrop-add-on-dev-fedora container image.
#
# For more information (or to report issues) go to
# https://github.com/danieljrmay/backdrop-containers

DocumentRoot "/usr/share/backdrop"

<Directory "/usr/share/backdrop">
    Require all granted
    AllowOverride All
</Directory>

# Listen on the container hosts mapped port (as well as port 80) so
# that backdrop is able to access itself via HTTP. This is required
# for things like the Testing module to work.
Listen $PORT
EOF

if [ -f $httpd_conf_path ]; then
	systemd-cat \
		--identifier=$identifier \
		echo "Created $httpd_conf_path with additional port $PORT."
else
	systemd-cat \
		--identifier=$identifier \
		--priority=error \
		echo "Failed to create $httpd_conf_path so exiting."
	exit 3
fi

# Create and configure a database for backdrop.
sql=$(
	cat <<EOF
CREATE DATABASE ${BACKDROP_DATABASE_NAME};
GRANT ALL ON ${BACKDROP_DATABASE_NAME}.* TO '${BACKDROP_DATABASE_USER}'@'localhost' IDENTIFIED BY '${BACKDROP_DATABASE_PASSWORD}';
FLUSH   PRIVILEGES;
EOF
)

if mysql --user=root --execute "$sql"; then
	systemd-cat \
		--identifier=$identifier \
		echo "Created and configured database $BACKDROP_DATABASE_NAME for $BACKDROP_DATABASE_USER@localhost."
else
	systemd-cat \
		--identifier=$identifier \
		--priority=error \
		echo "Failed to create the database $BACKDROP_DATABASE_NAME so exiting."
	exit 3
fi

# Add trusted hosts to the settings.php file.
settings_appendages=$(
	cat <<EOF

/**
 * Added by the backdrop-install systemd service.
 */ 
\$settings['trusted_host_patterns'] = array(
    '^localhost:$PORT\$', 
    '^localhost\$',
);
\$database_charset = 'utf8mb4';
EOF
)

if (echo "$settings_appendages" >>/etc/backdrop/settings.php); then
	systemd-cat \
		--identifier=$identifier \
		echo "Updated the settings.php file."
else
	systemd-cat \
		--identifier=$identifier \
		--priority=error \
		echo "Failed to update the settings.php file."
	exit 1
fi

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
