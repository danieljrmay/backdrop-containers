# backdrop-add-on-dev-fedora container

The contains the files to create and manage an image and container
suitable for [Backdrop CMS](https://backdropcms.org/home "Learn more
about Backdrop CMS.") add-on development.

Image has the following features:

* Built on top of the latest Fedora base image.
* Installs Backdrop via an RPM, see
  [backdrop-rpm](https://github.com/danieljrmay/backdrop-rpm "GitHub
  project page.") for more details.
* Installs [bee](https://github.com/backdrop-contrib/bee "GitHub
  project page.") — the Backdrop CMS command line utility.
* Installs the following development modules: `coder_review`
    `devel` `devel_debug`_`log devel_generate_text_settings`
    `devel_subthemer` `security_review`.
* Automatically creates and configures a MariaDB database for backdrop
    on “first boot” of the container.
* Automatically performs a command-line installation of a backdrop
  site on “first boot” of the container.
* Mounts your hosts custom modules development directory in the
  container.
* Mounts your hosts custom themes development directory in the
  container.

## Usage

Create a customised version of the environment file
`backdrop-add-on-dev-fedora.env` either by modifying the existing file
in-place, or creating a copy.

```sh
# Create a backup of the environment file, so we can mess things up
# with impunity.
cp backdrop-add-on-dev-fedora.env backdrop-add-on-dev-fedora.env.original

# Edit (and save) our environment file to our tastes.
nano backdrop-add-on-dev-fedora.env

# Create the image. This might take a couple of minutes, but only
# needs to be done once, unless you change the image configuration in
# which case it will need to be re-created.
bash create-image-backdrop-add-on-dev-fedora.bash

# Create the container. The container is ready in a couple of seconds,
# however, you might need to wait a minute for your instance of backdrop
# to fully install.
bash create-container-backdrop-add-on-dev-fedora.bash

# Explore your container via a Bash shell.
bash explore-container-backdrop-add-on-dev-fedora.bash
```

You should be able to access and log in to your new backdrop site via
a brower on your host machine by navigating to
<http://localhost:40080>. The default administrator username is
`admin` with password `admin_pwd`.

Once you have finished with your container you can delete it with
`bash destroy-container-backdrop-add-on-dev-fedora.bash`.

You can delete your image with `bash
destroy-image-backdrop-add-on-dev-fedora.bash`, which you will need to
do if you want to customise the image before recreating it.

If you want to maintain a number of different environment files you
can pass them into all the scripts in this directory with commands of
the form:

```sh
ENVIRONMENT_FILE=my-file.env bash create-image-backdrop-add-on-dev-fedora.bash
```
