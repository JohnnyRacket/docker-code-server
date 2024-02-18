FROM ghcr.io/linuxserver/baseimage-ubuntu:jammy

# set version label
ARG CODE_RELEASE=4.21.1

# environment settings
ARG DEBIAN_FRONTEND="noninteractive"
ENV HOME="/config"

RUN \
  echo "**** install runtime dependencies ****" && \
  apt-get update && \
  apt-get install -y \
    git \
    jq \
    libatomic1 \
    nano \
    net-tools \
    netcat \
    sudo \
    unzip

# Install Rust
ENV RUSTUP_HOME=/home/coder/bin/rustup
ENV CARGO_HOME=/home/coder/bin/cargo
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH=$PATH:/home/coder/bin/cargo/bin  
ENV PATH=$PATH:/home/coder/bin/rustup/bin  

# Install nvm
ENV NVM_DIR /usr/local/nvm
ENV NODE_VERSION v20.11.1
RUN mkdir -p /usr/local/nvm && apt-get update && echo "y" | apt-get install curl
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
RUN /bin/bash -c "source $NVM_DIR/nvm.sh && nvm install $NODE_VERSION && nvm use --delete-prefix $NODE_VERSION"
ENV NODE_PATH $NVM_DIR/versions/node/$NODE_VERSION/bin
ENV PATH $NODE_PATH:$PATH

# Install the Yarn package manager
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | \
tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update && apt-get install -y yarn

# install oh-my-zsh
# Default powerline10k theme, no plugins installed
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.1.5/zsh-in-docker.sh)"

#install bun
RUN curl -fsSL https://bun.sh/install | bash

# Install Go
# copied from https://github.com/cdr/enterprise-images/blob/main/images/golang/Dockerfile.ubuntu
# Install go1.17.1
RUN curl -L "https://dl.google.com/go/go1.22.0.linux-amd64.tar.gz" | tar -C /usr/local -xzvf -

# install docker
RUN curl -fsSL https://get.docker.com | sh

# Setup go env vars
ENV GOROOT /usr/local/go
ENV PATH $PATH:$GOROOT/bin

ENV GOPATH /home/root/go
ENV GOBIN $GOPATH/bin
ENV PATH $PATH:$GOBIN

RUN echo "**** install code-server ****" && \
if [ -z ${CODE_RELEASE+x} ]; then \
  CODE_RELEASE=$(curl -sX GET https://api.github.com/repos/coder/code-server/releases/latest \
    | awk '/tag_name/{print $4;exit}' FS='[""]' | sed 's|^v||'); \
fi && \
mkdir -p /app/code-server && \
curl -o \
  /tmp/code-server.tar.gz -L \
  "https://github.com/coder/code-server/releases/download/v${CODE_RELEASE}/code-server-${CODE_RELEASE}-linux-amd64.tar.gz" && \
tar xf /tmp/code-server.tar.gz -C \
  /app/code-server --strip-components=1 && \
echo "**** clean up ****" && \
apt-get clean && \
rm -rf \
  /config/* \
  /tmp/* \
  /var/lib/apt/lists/* \
  /var/tmp/*

# add local files
COPY /root /

# ports and volumes
EXPOSE 8443
