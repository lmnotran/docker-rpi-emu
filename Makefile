# Helper makefile to demonstrate the use of the rpi-emu docker environment
# This is mostly useful for development and extension as part of an image builder
#
# For an example using this in a project, see Makefile.example

DIST ?= 2021-05-07-raspios-buster-armhf-lite
IMAGE_ARCHIVE ?= $(DIST).zip
IMAGE ?= $(DIST).img

RASPIOS_URL ?= https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2021-05-28/$(IMAGE_ARCHIVE)
CWD=$(shell pwd)
IMAGES_DIR ?= $(CWD)/images

# Docker arguments
# Interactive mode, remove container after running, privileged mode for loopback access
# Mount images to /usr/rpi/images to access image files from container
# Change working directory to /usr/rpi (which is loaded with the helper scripts)

MORE_RUN_ARGS ?= --env CONTAINER_OT_REFERENCE_RELEASE_DIR=$(CONTAINER_OT_REFERENCE_RELEASE_DIR) -v $(CWD)/../:$(CONTAINER_OT_REFERENCE_RELEASE_DIR)
RUN_ARGS=-it --rm --privileged=true -v $(IMAGES_DIR):/usr/rpi/images -w /usr/rpi siliconlabsinc/docker-rpi-emu
MOUNT_DIR=/media/rpi

# Build the docker image
DOCKER_IMAGE_TAG ?= ryankurte/docker-rpi-emu
build:
	@echo "Building base docker image"
	@docker build -t $(DOCKER_IMAGE_TAG) .

# Bootstrap a RPI image into the images directory
bootstrap: $(IMAGES_DIR)/$(IMAGE)

# Fetch the RPI image from the path above
$(IMAGES_DIR)/$(IMAGE):
	@echo "Pulling Raspbian image"
	mkdir -p $(IMAGES_DIR)
	wget -O $(IMAGES_DIR)/$(IMAGE_ARCHIVE) -c $(RASPIOS_URL)
	unzip -d $(IMAGES_DIR)/ $(IMAGES_DIR)/$(IMAGE_ARCHIVE)
	@touch $@

# Expand the image by a specified size
# TODO: implement expand script to detect partition sizes
EXPAND_SIZE ?= 1024
expand: build bootstrap
	dd if=/dev/zero bs=1M count=$(EXPAND_SIZE) >> $(IMAGES_DIR)/$(IMAGE)
	docker run $(RUN_ARGS) /bin/bash -c 'ls -alh /usr/rpi/images/'
	docker run $(RUN_ARGS) /bin/bash -c './expand.sh /usr/rpi/images/$(IMAGE) $(EXPAND_SIZE)'

# Launch the docker image without running any of the utility scripts
run: build bootstrap
	@echo "Launching interactive docker session"
	docker run $(RUN_ARGS) /bin/bash

# Launch the docker image into an emulated session
COMMAND ?= ""
run-emu: build bootstrap
	@echo "Launching interactive emulated session"
	docker run $(MORE_RUN_ARGS) $(RUN_ARGS) /bin/bash -c './run.sh /usr/rpi/images/$(IMAGE) "$(COMMAND)"'


test: build bootstrap
	@echo "Running test command"
	docker run $(RUN_ARGS) /bin/bash -c './run.sh $(IMAGES_DIR)/$(IMAGE) "uname -a"'
