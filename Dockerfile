# syntax=docker/dockerfile:1

FROM debian:11

EXPOSE 443 80

VOLUME /config

WORKDIR /app

ENV PATH=$PATH:/usr/local/go/bin

RUN apt-get update && apt-get install -y ca-certificates openssl fdisk mergerfs snapraid avahi-daemon avahi-utils dbus && \
    apt-get install -y --no-install-recommends  wget curl && \
    wget https://golang.org/dl/go1.21.8.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.21.8.linux-amd64.tar.gz && \
    rm go1.21.8.linux-amd64.tar.gz && \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    wget https://github.com/slackhq/nebula/releases/download/v1.7.2/nebula-linux-arm64.tar.gz && \
    tar -xzvf nebula-linux-arm64.tar.gz && \
    mv nebula nebula-arm && \
    mv nebula-cert nebula-arm-cert && \
    rm nebula-linux-arm64.tar.gz && \
    wget https://github.com/slackhq/nebula/releases/download/v1.8.2/nebula-linux-amd64.tar.gz && \
    tar -xzvf nebula-linux-amd64.tar.gz && \
    rm nebula-linux-amd64.tar.gz
    
    
# Copy Go modules and download them, copy npm dependencies and install them
COPY go.mod ./
COPY go.sum ./
RUN go mod download

COPY package.json ./
COPY package-lock.json ./
RUN npm install

COPY . .
RUN npm run client-build && \
    chmod +x build.sh && \
    ./build.sh && \
    rm -rf /usr/local/go \
           /tmp/* \
           /var/lib/apt/lists/* \
           /var/tmp/*
           
RUN apt-get remove -y wget curl && \
    apt-get autoremove -y && \
    mkdir -p /var/run/dbus && \
    dbus-uuidgen > /var/lib/dbus/machine-id

CMD service dbus start && \
    service avahi-daemon start && \
    ./cosmos
