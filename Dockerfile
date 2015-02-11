# See: https://github.com/sstephenson/rbenv
# See: https://github.com/sstephenson/ruby-build
# See: https://github.com/tcnksm/dockerfile-rbenv/blob/master/Dockerfile

FROM ubuntu:14.04

MAINTAINER Adam Staněk <adam.stanek@v3net.cz>

#
# Update APT and install build essentials
#
# For required packages for building Ruby 2.2.0 see:
# https://github.com/sstephenson/ruby-build/wiki#build-failure-of-fiddle-with-ruby-220
# Required packages by Docker: apt-transport-https ca-certificates lxc iptables
# Required packages by Rugged: cmake pkg-config libssh2-1-dev
#
RUN apt-get update \
    && apt-get install -y \
        apt-transport-https \
        ca-certificates \
        lxc \
        iptables \
        build-essential \
        curl \
        git \
        python-software-properties \
        zlib1g-dev \
        libssl-dev \
        libreadline-dev \
        libyaml-dev \
        libxml2-dev \
        libxslt-dev \
        libffi-dev \
        cmake \
        pkg-config \
        libssh2-1-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Docker from Docker Inc. repositories.
RUN curl -sSL https://get.docker.com/ubuntu/ | sh

# Install rbenv and ruby-build
RUN git clone https://github.com/sstephenson/rbenv.git /root/.rbenv \
 && git clone https://github.com/sstephenson/ruby-build.git /root/.rbenv/plugins/ruby-build \
 && rm -rf /root/.rbenv/.git \
 && rm -rf /root/.rbenv/plugins/ruby-build/.git \
 && echo 'eval "$(/root/.rbenv/bin/rbenv init -)"' > /etc/profile.d/rbenv.sh

# Install Ruby
ENV CONFIGURE_OPTS --disable-install-doc
ENV RBENV_VERSION 2.2.0
RUN /root/.rbenv/bin/rbenv install $RBENV_VERSION

# Install Phoebo using gem
RUN /root/.rbenv/shims/gem install phoebo

# Wrap docker script
# See https://github.com/jpetazzo/dind for original version
ADD ./wrapdocker /usr/local/bin/wrapdocker

# Docker daemon will log into /var/log/docker.log
ENV LOG file

# Default shell (We need to perform "login" to read from /etc/profile)
ENTRYPOINT ["/bin/bash", "--login", "wrapdocker"]
CMD ["/bin/bash"]
