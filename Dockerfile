# syntax=docker/dockerfile:1

FROM debian:11

# Expose necessary ports and volumes
EXPOSE 443 80 5353/udp
VOLUME /config

# Set working directory
WORKDIR /app

# Install necessary packages
RUN apt-get update && \
    apt-get install -y \
        ca-certificates \
        openssl \
        fdisk \
        curl \
        mergerfs \
        snapraid \
        avahi-daemon \
        avahi-utils \
        wget \
        curl \
    && rm -rf /var/lib/apt/lists/*

# Download and install Go
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/go/bin:/app/bin:${PATH}"
RUN wget https://golang.org/dl/go1.21.8.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.21.8.linux-amd64.tar.gz && \
    rm go1.21.8.linux-amd64.tar.gz

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    apt-get remove -y wget curl && \
    apt-get autoremove -y

# Copy Go modules and download them
COPY go.mod go.sum ./
RUN go mod download

# Copy npm dependencies and install them
COPY package.json package-lock.json ./
RUN npm install
RUN curl -LO https://github.com/slackhq/nebula/releases/download/v1.8.2/nebula-linux-amd64.tar.gz \
    && tar -xzvf nebula-linux-amd64.tar.gz \
    && rm nebula-linux-amd64.tar.gz

# Copy application code
COPY . .

# Build UI
RUN npm run client-build

# Run additional build script or commands
RUN chmod +x build.sh && \
    ./build.sh

# Clean up unnecessary files
RUN rm -rf /usr/local/go \
           /tmp/* \
           /var/tmp/*

# Set working directory for runtime
WORKDIR /app/build

# Start Avahi daemon and run the application
CMD service avahi-daemon start && ./cosmos
