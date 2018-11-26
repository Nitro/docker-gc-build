FROM ubuntu:xenial

LABEL description="Docker image for building docker-gc debian package" \
      maintainer="infra-guild@gonitro.com" \
      repository="https://github.com/Nitro/docker-gc"

ARG VERSION
ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY

ADD . /tmp

WORKDIR /tmp
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt install -y \
    git \
    devscripts \
    debhelper \
    curl \
    build-essential \
    dh-make

RUN DEBEMAIL="Infrastructure Guild <infra-guild@gonitro.com>" dch "Nitro build." \
    --newversion "${VERSION}" \
    --no-auto-nmu

RUN debuild --no-lintian -us -uc -b