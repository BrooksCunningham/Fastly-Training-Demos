FROM ubuntu:20.04
# LABEL maintainer=""

# The below information is collected from:
# https://archive.tetratelabs.io/envoy/envoy-versions.json
ARG ENVOY_VERSION=1.24.0
ARG ENVOY_SHA256="05e1343657086268edaa16a1e8a1429d9c8f6e50a44f492cf629fdc71da2ecdc"

# set DEBIAN_FRONTEND to convey no-TTY during build
ARG DEBIAN_FRONTEND=noninteractive
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        apt-transport-https \
        ca-certificates \
        gnupg \
        wget \
        xz-utils \
    && wget -qO - https://apt.signalsciences.net/release/gpgkey | apt-key add - \
    && wget --quiet -P /tmp "https://github.com/envoyproxy/envoy/releases/download/v${ENVOY_VERSION}/envoy-${ENVOY_VERSION}-linux-x86_64" \
    && echo ${ENVOY_SHA256} "/tmp/envoy-${ENVOY_VERSION}-linux-x86_64" | sha256sum --check \
    && chmod +x "/tmp/envoy-${ENVOY_VERSION}-linux-x86_64" \
    && mv /tmp/envoy-${ENVOY_VERSION}-linux-x86_64 /usr/bin/envoy \
    && echo "deb https://apt.signalsciences.net/release/ubuntu/ focal main" | tee /etc/apt/sources.list.d/sigsci-release.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        sigsci-agent \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/envoy-v${ENVOY_VERSION}*

COPY conf/envoy.yaml /etc/envoy/envoy.yaml
COPY agent.conf /etc/sigsci/agent.conf

COPY run.sh /app/run.sh

ENTRYPOINT ["/app/run.sh"]
