# docker-makepkg

This Docker image automtically buils Arch packages from any PKGBUILD file using makepkg.

You have to build the docker image at first (this has to be done only once):

```
$ docker build . -t docker-makepkg
```

Now run the image as many times as you like. You have to provide at least one URL pointing to a PKGBUILD file or a zip/tar archive containing a PKGBUILD file.

```
$ docker run -v $(pwd):/out docker-makepkg <url>
```

After the build is complete, you find the package(s) in your current directory (the package(s) names end with `...-x86_64.pkg.tar.zst`). To install the package(s) on your machine just run:

```
$ pacman -U *-x86_64.pkg.tar.zst
```

If you are unsure where to search for packages and the corresponding PKGBUILD file, check out the [Arch AUR repository](https://aur.archlinux.org/packages). There you can search for your favorite software and get a link to the PKGBUILD file (On the "Package Actions" menu on the right copy the link url "Download snapshot" and run the container with this url).