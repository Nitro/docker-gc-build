#!/bin/bash

set -o nounset
set -o pipefail

die() {
    echo "$1" >&2
    exit 2
}

usage() {
    cat <<EOF
${0##*/} [options] [arguments]

Arguments:

-b Set the S3 bucket name

Options:

-h Help
-s Dry run (simulate)
-n Does not upload artifact (just build)
EOF
    exit 1
}

do_prereq() {
    declare -a deps=(gpg deb-s3)

    for dep in ${deps[*]}
    do
        [[ ! -f $(command -v "$dep") ]] && {
            die "You need to install: $dep"
        }
    done
}

parse_args() {
    local OPTIND
    while getopts ":b:hsn" opt; do
        case ${opt} in
            b) BUCKET=${OPTARG}
                ;;
            h) usage
                ;;
            s) DRY_RUN="echo "
                ;;
            n) NO_UPLOAD=1
                ;;
            \?) echo "Invalid Option: -${OPTARG}" 1>&2; exit 1
                ;;
        esac
    done
}


do_build() {
    $DRY_RUN docker build \
        -t "${TAG}" \
        --build-arg VERSION="${VERSION}" \
        --build-arg AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
        --build-arg AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" \
        -f ./Dockerfile .

    $DRY_RUN docker run -v /tmp/:/tmp "${TAG}" /bin/bash -c 'cp /docker-gc*.deb /tmp'

    package=$(ls /tmp/*.deb || :)
    printf "[+] Debian Package generated into '%s'\n" "${package}"
}


do_upload() {
    printf  "[+] Using GPG %s for package signature\n" "${NITRO_GPG_KEY}"
    $DRY_RUN deb-s3 upload \
        --access-key-id="${AWS_ACCESS_KEY_ID}" \
        --secret-access-key="${AWS_SECRET_ACCESS_KEY}" \
        --s3-region="${AWS_REGION}" \
        --bucket="${BUCKET}" \
        --sign="${NITRO_GPG_KEY}" "${package}" || exit 1
    printf "[+] Successfully uploaded package into '%s'\n" "${BUCKET}"
}



main() {
    COMMIT=$( (cd docker-gc && git rev-parse --short HEAD) )
    VERSION="2:$(cat "${PWD}"/docker-gc/version.txt)~${COMMIT}"
    TAG="gonitro/docker-gc-build:${COMMIT}"
    AWS_REGION=us-west-2
    BUCKET=${BUCKET:-nitro-apt-repo}
    DRY_RUN=${DRY_RUN:-}
    NO_UPLOAD=${NO_UPLOAD:-}
    KEYSERVER=${KEYSERVER:-pgpkeys.eu}
    NITRO_GPG_KEY=$(gpg \
        --keyserver "${KEYSERVER}" \
        --batch \
        --search-keys \
        --with-colons infra-guild@gonitro.com 2>&1| sed -E -n 's/^pub:.*(........):.*:.*:.*::/\1/p')

    do_prereq

    parse_args "$@"

    do_build

    if [[ -z ${NO_UPLOAD} ]]; then
        do_upload
    fi

    exit 0
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
