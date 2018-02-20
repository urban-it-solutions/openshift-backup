FROM golang:1.9.1-alpine3.6	
MAINTAINER Vadim Zharov

RUN echo http://nl.alpinelinux.org/alpine/v3.4/community >> /etc/apk/repositories
RUN apk add --no-cache git nfs-utils openssh fuse curl wget
RUN git clone https://github.com/restic/restic \
  && cd restic \
  && go run build.go \
  && cp restic /usr/local/bin/

RUN wget https://github.com/openshift/origin/releases/download/v3.7.1/openshift-origin-client-tools-v3.7.1-ab0f056-linux-64bit.tar.gz

RUN tar -xvf openshift-origin-client-tools-v3.7.1-ab0f056-linux-64bit.tar.gz && mv openshift-origin-client-tools-v3.7.1-ab0f056-linux-64bit/oc /usr/local/bin/

RUN wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://raw.githubusercontent.com/sgerrand/alpine-pkg-glibc/master/sgerrand.rsa.pub
RUN wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.26-r0/glibc-2.26-r0.apk
RUN apk add glibc-2.26-r0.apk

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
ENV TOKEN=""
ENV RESTIC_SNAPSHOT="latest"


# /data is the dir where you have to put the data to be backed up
VOLUME /data

COPY entry.sh /entry.sh
COPY restic-openshift-api.cfg /restic-openshift-api.cfg
COPY restic-openshift-oapi.cfg /restic-openshift-oapi.cfg

WORKDIR "/"

ENTRYPOINT ["/entry.sh"]
