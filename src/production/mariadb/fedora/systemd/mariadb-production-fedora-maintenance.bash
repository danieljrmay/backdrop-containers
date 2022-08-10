#!/usr/bin/bash
#
# mariadb-production-fedora-maintenance
#
# Author: Daniel J. R. May
#
# This script performs routine maintenance on the mariadb database.
#
# For more information (or to report issues) go to
# https://github.com/danieljrmay/backdrop-containers

readonly identifier=maraidb-production-fedora-maintenance

# Check.
systemd-cat --identifier=$identifier echo "Checking all database tables."
mariadb-check --all-databases --check --user=root --host=localhost --password="${MARIADB_ROOT_PASSWORD}"

# Optimize.
systemd-cat --identifier=$identifier echo "Optimizing all database tables."
mariadb-check --all-databases --optimize --user=root --host=localhost --password="${MARIADB_ROOT_PASSWORD}"
