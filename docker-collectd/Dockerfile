# Dockerfile for base collectd install
# Based on https://github.com/signalfx/docker-collectd

FROM ubuntu:20.04
MAINTAINER Denys Fedoryshchenko <collectddocker+nuclearcat@nuclearcat.com>

# Install common softwares
ENV DEBIAN_FRONTEND noninteractive


# Install all apt-get utils and required repos
RUN apt-get update \
    && apt-get upgrade -y \
    # Install add-apt-repository
    && apt-get install -y \
        software-properties-common \
    && apt-get update \
    # Install
    && apt-get install -y \
        collectd \
        curl \
        jq \
        unzip \
        python3-pip \
    # Uninstall helper packages
    && apt-get --purge -y remove \
        software-properties-common \
        unzip \
    # Clean up packages
    && apt-get autoclean \
    && apt-get clean \
    && apt-get autoremove -y \
    # Remove extraneous files
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /usr/share/man/* \
    && rm -rf /usr/share/info/* \
    && rm -rf /var/cache/man/* \
    # Clean up tmp directory
    && rm -rf /tmp/*

# Add in startup script
ADD ["run.sh", "/.docker/"]

# Setup our collectd
ADD ["configs/*", "/tmp/"]

# Set correct permissions on startup script
RUN chmod +x /.docker/run.sh

# Change directory and declare startup command
WORKDIR /.docker/
CMD /.docker/run.sh
