# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/baseimage-alpine:edge

ARG UNRAR_VERSION=6.2.10
ARG BUILD_DATE
ARG VERSION
ARG TRANSMISSION_VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="aptalca"

RUN \
  echo "**** install build packages ****" && \
  apk add --no-cache --virtual=build-dependencies \
    build-base && \
  echo "**** install packages ****" && \
  apk add --no-cache \
    findutils \
    p7zip \
    python3 && \
  echo "**** install unrar from source ****" && \
  mkdir /tmp/unrar && \
  curl -o \
    /tmp/unrar.tar.gz -L \
    "https://www.rarlab.com/rar/unrarsrc-${UNRAR_VERSION}.tar.gz" && \  
  tar xf \
    /tmp/unrar.tar.gz -C \
    /tmp/unrar --strip-components=1 && \
  cd /tmp/unrar && \
  make && \
  install -v -m755 unrar /usr/local/bin && \
  echo "**** install transmission ****" && \
  if [ -z ${TRANSMISSION_VERSION+x} ]; then \
    TRANSMISSION_VERSION=$(curl -sL "http://dl-cdn.alpinelinux.org/alpine/edge/community/x86_64/APKINDEX.tar.gz" | tar -xz -C /tmp \
    && awk '/^P:transmission$/,/V:/' /tmp/APKINDEX | sed -n 2p | sed 's/^V://'); \
  fi && \
  apk add --no-cache \
    transmission-cli==${TRANSMISSION_VERSION} \
    transmission-daemon==${TRANSMISSION_VERSION} \
    transmission-extra==${TRANSMISSION_VERSION} \
    transmission-remote==${TRANSMISSION_VERSION} && \
  echo "**** cleanup ****" && \
  apk del --purge \
    build-dependencies && \
  rm -rf \
    /tmp/* \
    $HOME/.cache

# Add Flood web UI
WORKDIR /usr/share/transmission/web/

RUN rm -rf * && \
    wget https://github.com/johman10/flood-for-transmission/releases/download/latest/flood-for-transmission.zip && \
    unzip flood-for-transmission.zip && \
    mv flood-for-transmission/* ./ && \
    rm -r flood-for-transmission && \
    rm -r flood-for-transmission.zip

ENV TRANSMISSION_WEB_HOME=/usr/share/transmission/web

# install filebot dependencies
RUN echo '@testing http://dl-4.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories && \
    apk update && \
    apk add --no-cache \
        ca-certificates \
        coreutils \
        tzdata \
        java-cacerts \
        java-jna \
        libzen@testing \
        libmediainfo@testing \
        openjdk11-jre-headless \
        nss \
        unzip \
        vim

WORKDIR /usr/local/bin

# install filebot
COPY FileBot_5.1.1-portable-jdk8.tar.xz filebot.tar.xz
RUN ls -lah
RUN tar xvf filebot.tar.xz
RUN chmod +x filebot.sh
RUN mv filebot.sh filebot
RUN filebot -script fn:sysinfo

# copy local files
COPY root/ /

# make scripts executable and add cron job
RUN chmod +rx /defaults/transmission-postprocess.sh

# add transmission garbage collection
RUN chmod +rx /defaults/transmission-garbagecollect.sh
RUN echo "0 3 * * * /defaults/transmission-garbagecollect.sh >> /config/logs/transmissiongc.log 2>&1" >> /etc/crontabs/root

RUN mkdir -p /config
RUN mkdir -p /config/logs

# ports and volumes
EXPOSE 9091 51413/tcp 51413/udp
VOLUME /config
