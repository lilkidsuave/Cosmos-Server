# syntax=docker/dockerfile:1

FROM debian:11

# Expose necessary ports and volumes
EXPOSE 443 80 5353/udp
VOLUME /config

# Set working directory
WORKDIR /app

# Install necessary packages, download and install Go, install Node.js
RUN apt-get update \
    && apt-get install -y \
        ca-certificates \
        openssl \
        fdisk \
        mergerfs \
        snapraid \
        avahi-daemon \
        avahi-utils \
        wget \
        nodejs \
    && wget https://golang.org/dl/go1.21.8.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go1.21.8.linux-amd64.tar.gz \
    && rm go1.21.8.linux-amd64.tar.gz \
    && wget -O- https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get remove -y wget \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* \
    && wget https://github.com/slackhq/nebula/releases/download/v1.8.2/nebula-linux-amd64.tar.gz \
    && tar -xzvf nebula-linux-amd64.tar.gz \
    && rm nebula-linux-amd64.tar.gz

# Set default environment variables including PATH
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/go/bin:/app/bin:/usr/local:${PATH}"

# Copy Go modules and download them, copy npm dependencies and install them
COPY go.mod go.sum ./
RUN go mod download \
    && npm install

# Copy application code
COPY . .

# Build UI, run additional build script or commands
RUN npm run client-build \
    && chmod +x build.sh \
    && ./build.sh

# Clean up unnecessary files
RUN rm -rf /usr/local/go \
           /tmp/* \
           /var/tmp/*

# Set working directory for runtime
WORKDIR /app/build

# Start Avahi daemon and run the application
CMD service avahi-daemon start && ./cosmos
