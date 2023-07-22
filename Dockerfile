FROM ubuntu

MAINTAINER Ryan Kurte <ryankurte@gmail.com>
LABEL Description="Qemu based emulation for raspberry pi using loopback images"
ENV DOCKER 1

# Update package repository
RUN apt-get update

# Install required packages
RUN apt-get install -y --allow-unauthenticated \
    qemu \
    qemu-user-static \
    binfmt-support \
    parted \
    vim \
    sudo \
    fdisk \
    git \
    wget \
    zip \
    python3-pip \
    dcfldd

# Clean up after apt
RUN apt-get clean
RUN rm -rf /var/lib/apt

# Setup working directory
RUN mkdir -p /usr/rpi
WORKDIR /usr/rpi

RUN mkdir -p /home/pi

COPY scripts/* /usr/rpi/

# Setup non-root user with sudo permissions
RUN adduser --disabled-password --gecos '' docker && adduser docker sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER docker

