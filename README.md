# docker-gc-build

This project help us to build using [Docker][1] container a new [docker-gc][2] debian package release
signed.

## Requirements

- [deb-s3](/krobertson/deb-s3) to upload your debian package artifact into the target s3-bucket
- [gnupg](https://formulae.brew.sh/formula/gnupg) to sign the package

## Usage

Build debian package into an isloated docker container and sign it with
passphrase:

```sh
./release.sh -h
```

Just executing a [Dry-run](https://en.wikipedia.org/wiki/Dry_run_(testing)):

```sh
./release.sh -s
```

List repos packages
```
deb-s3 list --bucket=$BUCKET
aws s3 ls --recursive s3://$BUCKET
```

## License

This project is released under MIT license.

Copyright (c) 2018 Nitro Software

[1]: https://www.docker.com/resources/what-container
[2]: https://github.com/spotify/docker-gc
