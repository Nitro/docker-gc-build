#!/bin/bash

set -e

DRY_RUN=' '

[ ! -f `which gpg` ] && {
    echo 2>&1 "You need to install gnupg: brew install gnupg"
    exit 2
}

[ ! -f `which deb-s3` ] && {
    echo 2>&1 "You need to install deb-s3: gem install deb-s3"
    exit 2
}

COMMIT=`git rev-parse --short HEAD`
VERSION="2:`cat version.txt`~${COMMIT}"
TAG="gonitro/docker-gc-build:${COMMIT}"
AWS_REGION=us-west-2
BUCKET=nitro-apt-repo
NITRO_GPG_KEY=C5075270

$DRY_RUN docker build \
    -t ${TAG} \
    --build-arg VERSION=${VERSION} \
    --build-arg AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
    --build-arg AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
    -f ./Dockerfile .

$DRY_RUN docker run -v /tmp/:/tmp ${TAG} /bin/bash -c 'cp /docker-gc*.deb /tmp'

package=`ls /tmp/*.deb`
echo Debian Package generated into ${package}

$DRY_RUN deb-s3 upload \
    --access-key-id=${AWS_ACCESS_KEY_ID} \
    --secret-access-key=${AWS_SECRET_ACCESS_KEY} \
    --s3-region=${AWS_REGION} \
    --bucket=${BUCKET} \
    --sign=${NITRO_GPG_KEY} ${package} || exit 1
echo Successfully uploaded package into ${BUCKET}

exit 0
