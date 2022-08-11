#!/usr/bin/bash
#
# backdrop-production-fedora-firstboot
#
# Author: Daniel J. R. May
#
# This script creates an httpd configuration and updates backdrop's
# settings.php file.
#
# For more information (or to report issues) go to
# https://github.com/danieljrmay/backdrop-containers

declare -r identifier='backdrop-production-fedora-firstboot'
declare -r lock_path='/var/lock/backdrop-production-fedora-firstboot.lock'
declare -r httpd_conf_path='/etc/httpd/conf.d/backdrop-production-fedora.conf'

# Check that this script has not already run by checking for a lock
# file.
if [ -f "$lock_path" ]; then
	systemd-cat --identifier=$identifier --priority=warning \
		echo "Lock file $lock_path already exists, exiting."
	exit 1
fi

# Create the Apache HTTPD server configuration file.
cat >$httpd_conf_path <<EOF
# Apache HTTP server configuration for the the
# backdrop-production-fedora container image.
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

# Create the lock file to prevent this script from running again.
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
