# 🐋 docker-makepkg

This Docker image automtically buils Arch packages from any PKGBUILD file or from AUR using aurutils and makepkg.
Further a arch repository is created that can be directly served by a webserver.

You have to build the docker image at first (this has to be done only once):

```
$ docker build . -t docker-makepkg
```

Now run the image as many times as you like. You have to provide at least one URL pointing to a PKGBUILD file or a zip/tar archive containing a PKGBUILD file.

```
$ docker run -v $(pwd):/out docker-makepkg <url>
```

After the build is complete, you find the package(s) (plus dependencies) in your current directory (the package(s) names end with `...-x86_64.pkg.tar.zst`). To install the package(s) on your machine just run:

```
$ pacman -U *-x86_64.pkg.tar.zst
```

## Advanced usage

You can use this container to build/update your own arch repo. Use the following environment variable to put the package(s) inside a repository structure. The repository can be served directly from a webserver.

- ARCH_REPO_NAME
  - The name of your repository (choose freely but avoid whitespaces) (default "unknown")
- CONTINUOUS_INTERVAL_SEC
  - Sleep for x seconds between intervals (default 600)
