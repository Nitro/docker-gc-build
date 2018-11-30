#!/bin/bash

set -e

[ ! -f `which gpg` ] && {
    echo 2>&1 "You need to install gnupg: brew install gnupg"
    exit 2
}

[ ! -f `which deb-s3` ] && {
    echo 2>&1 "You need to install deb-s3: gem install deb-s3"
    exit 2
}

COMMIT=`(cd docker-gc && git rev-parse --short HEAD)`
VERSION="2:`cat ${PWD}/docker-gc/version.txt`~${COMMIT}"
TAG="gonitro/docker-gc-build:${COMMIT}"
AWS_REGION=us-west-2
BUCKET=nitro-apt-repo
NITRO_GPG_KEY=C5075270

printf  "[+] Using GPG %s for package signature\n" ${NITRO_GPG_KEY}

$DRY_RUN docker build \
    -t ${TAG} \
    --build-arg VERSION=${VERSION} \
    --build-arg AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
    --build-arg AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
    -f ./Dockerfile .

$DRY_RUN docker run -v /tmp/:/tmp ${TAG} /bin/bash -c 'cp /docker-gc*.deb /tmp'

package=`ls /tmp/*.deb || :`
printf "[+] Debian Package generated into '%s'\n" ${package}

$DRY_RUN deb-s3 upload \
    --access-key-id=${AWS_ACCESS_KEY_ID} \
    --secret-access-key=${AWS_SECRET_ACCESS_KEY} \
    --s3-region=${AWS_REGION} \
    --bucket=${BUCKET} \
    --sign=${NITRO_GPG_KEY} ${package} || exit 1
printf "[+] Successfully uploaded package into %s\n" ${BUCKET}

exit 0
