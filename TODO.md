# backdrop-containers to-do list

* [ ] Work out a better way of checking if a site has been installed
      that creating
      `/var/lib/backdrop/private_files/backdrop-install.lock`. What if
      the user installed via the Web GUI first time around? What is
      the canonical file to look for?
* [ ] Change `src` to `containers`? How about an `images` directory
      too?
* [ ] Change mariadb production to be non-systemd. Move all systemd
      tasks into backdrop production container.
