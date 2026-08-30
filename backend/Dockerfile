# There is no maintained official Pharo base image — the pharo/vm and
# pharo/image repositories on Docker Hub stopped at Pharo 7 in 2018. So the
# image is built the way Pharo itself tells you to install: a plain Debian base
# plus the zeroconf script, which fetches a matching VM and a clean image.
FROM debian:bookworm-slim

# Two groups here. `curl` and `unzip` are what the zeroconf installer itself
# shells out to — it downloads a zip and unpacks it, and debian-slim ships
# neither. The rest are runtime libraries the Pharo VM links against; the X11 and
# cairo ones are needed even headless, because the VM is linked against them
# whether or not it ever opens a window.
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        unzip \
        libcairo2 \
        libfreetype6 \
        libgit2-1.5 \
        libgl1 \
        libssl3 \
        libuuid1 \
        libx11-6 \
        zlib1g \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/inventory

# 130 is Pharo 13.0. Override at build time to move versions:
#   docker build --build-arg PHARO_VERSION=140 .
ARG PHARO_VERSION=130
RUN curl -fsSL "https://get.pharo.org/64/${PHARO_VERSION}+vm" | bash

# Source first, data second: the source changes more often, so this ordering
# keeps the expensive Metacello layer cached when only the dataset moves.
COPY src ./src
COPY data ./data

# Load the project and save the image. From here the build artifact *is* the
# image — it already holds compiled code, so startup is a memory-map rather than
# a classpath scan. `load: 'core'` skips both test packages, the way a production
# Gradle build excludes src/test.
RUN ./pharo Pharo.image eval --save \
    "Metacello new \
        baseline: 'InventoryService'; \
        repository: 'tonel:///opt/inventory/src'; \
        load: 'core'"

ENV INVENTORY_DATA_PATH=/opt/inventory/data/inventory.json
EXPOSE 8080

# --no-quit keeps the image alive after the expression returns, so the Teapot
# listener thread stays up. Without it the process exits immediately.
CMD ["./pharo", "Pharo.image", "eval", "--no-quit", "InventoryServer new start"]
