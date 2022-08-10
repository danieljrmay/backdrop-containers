#!/usr/bin/bash
#
# mariadb-production-fedora-firstboot
#
# Author: Daniel J. R. May
#
# This script hardens the mariadb installation to make it suitable for
# production and creates the backdrop database.
#
# For more information (or to report issues) go to
# https://github.com/danieljrmay/backdrop-containers

# Declare readonly variables used by this script.
declare -r identifier='mariadb-production-fedora-firstboot'
declare -r lock_path='/var/lock/mariadb-production-fedora-firstboot.lock'

# Ensure this script has not already run, by checking for a lock file.
if [ -f "$lock_path" ]; then
	systemd-cat --identifier=$identifier --priority=warning \
		echo "Lock file $lock_path already exists, exiting."
	exit 1
fi

# Secure mariadb and create the backdrop database.
#
# This script run commands similar to the mariadb-secure-installation
# script. However it also changes the password of the default
# 'mysql'@'localhost' account which is blank by default.
sql=$(
	cat <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MARIADB_ROOT_PASSWORD}';
ALTER USER 'mysql'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';
DELETE FROM mysql.global_priv WHERE User='';
DELETE FROM mysql.global_priv WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
CREATE DATABASE ${BACKDROP_DATABASE_NAME};
GRANT ALL ON ${BACKDROP_DATABASE_NAME}.* TO '${BACKDROP_DATABASE_USER}'@'localhost' IDENTIFIED BY '${BACKDROP_DATABASE_PASSWORD}';
FLUSH PRIVILEGES;
EOF
)

if mysql --user=root --execute "$sql"; then
	systemd-cat \
		--identifier=$identifier \
		echo "Secured mariadb and created the backdrop database."
else
	systemd-cat \
		--identifier=$identifier \
		--priority=error \
		echo "Failed to secure mariadb and create the backdrop database."
	exit 2
fi

# Create a lock file so this script does not run again.
if touch $lock_path; then
	systemd-cat \
		--identifier=$identifier \
		echo "Created $lock_path to prevent the re-running of this script."
else
	systemd-cat \
		--identifier=$identifier \
		--priority=error \
		echo "Failed to create $lock_path so exiting with an error."
	exit 3
fi
