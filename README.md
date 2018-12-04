# docker-gc-build

## Requirements

- [deb-s3](/krobertson/deb-s3) to upload your debian package artifact in the s3-bucket
- [gnupg](https://formulae.brew.sh/formula/gnupg) to sign the package

## Usage

Build debian package into an isloated docker container and sign it with
passphrase:

```sh
./release.sh
```

Just executing a [Dry-run](https://en.wikipedia.org/wiki/Dry_run_(testing)):

```sh
DRY_RUN=echo ./release.sh
```