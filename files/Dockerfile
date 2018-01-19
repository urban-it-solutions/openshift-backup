FROM golang:1.9.1-alpine3.6	
MAINTAINER Vadim Zharov

RUN echo http://nl.alpinelinux.org/alpine/v3.4/community >> /etc/apk/repositories
RUN apk add --no-cache git nfs-utils openssh fuse
RUN git clone https://github.com/restic/restic \
  && cd restic \
  && go run build.go \
  && cp restic /usr/local/bin/
RUN apk del git

RUN mkdir /mnt/restic

ENV RESTIC_REPOSITORY=/mnt/restic
ENV PROJECT_NAME="default"
ENV RESTIC_TAG="default"
ENV RESTIC_KEEP=3
ENV RESTIC_EXCLUDE=""
ENV RESTIC_DESTINATION="nfs"
ENV AWS_ACCESS_KEY_ID=""
ENV AWS_SECRET_ACCESS_KEY=""
ENV RESTIC_S3_HOST=localhost
ENV RESTIC_S3_PORT="9000"

# /data is the dir where you have to put the data to be backed up
VOLUME /data

COPY entry.sh /entry.sh

USER root

WORKDIR "/"

ENTRYPOINT ["/entry.sh"]

