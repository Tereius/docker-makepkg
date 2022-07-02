#! /bin/bash

extract() {
     if [ -f $1 ] ; then
         case $1 in
             *.tar.bz2)   tar xjf $1     ;;
             *.tar.gz)    tar xzf $1     ;;
             *.tar)       tar xf $1      ;;
             *.tbz2)      tar xjf $1     ;;
             *.tgz)       tar xzf $1     ;;
             *.zip)       unzip $1       ;;
             *)           echo "'$1' cannot be extracted via extract()" ;;
         esac
     else
         echo "'$1' is not a valid file"
     fi
}

pacman -Syu --noconfirm

if [ -z "$1" ]; then
    echo "Expecting at least one URL pointing to a PKGBUILD file or a zip/tar archive containing a PKGBUILD file."
    exit 1
else

    out_dir=/out
    if [ ! -z "$ARCH_REPO_NAME" ]; then
        mkdir -p /out/arch-repo/x86_64
        arch_dir=/out/arch-repo
        out_dir=$arch_dir/x86_64
    fi

    for url in "$@"
    do
        tmp_dir=$( mktemp -d -t buildhelper.XXXXXXXXX )
        pushd "$tmp_dir"
        echo "---------------- Downloading $url to $tmp_dir"
        wget -q "$url" -P ./
        find "$(cd ..; pwd)" -name '*' -type f -print0 |
            while IFS= read -r -d '' downloaded_file; do
                echo "---------------- Extracting $downloaded_file"
                extract "$downloaded_file"
            done

        find "$(cd ..; pwd)" -name 'PKGBUILD' -type f -print0 |
            while IFS= read -r -d '' pkgbuild_file; do
                chown -R buildhelper:buildhelper ./
                echo "---------------- Building PKGBUILD file: $pkgbuild_file"
                pushd "$(dirname $pkgbuild_file)"
                su buildhelper -c "makepkg -m -f -c -C -s -i --noconfirm --skipinteg"
                cp *.pkg.* $out_dir
                if [ ! -z "$UID" ]; then chown $UID $out_dir/*.pkg.*; fi
                if [ ! -z "$GID" ]; then chown :$GID $out_dir/*.pkg.*; fi
                popd
            done
        popd
        rm -r "$tmp_dir"
    done

    if [ ! -z "$ARCH_REPO_NAME" ]; then
        echo "---------------- Creating/Updating repo with name \"$ARCH_REPO_NAME\""
        repo-add --nocolor --new -R $out_dir/$ARCH_REPO_NAME.db.tar.gz $out_dir/*.pkg.*
        if [ ! -z "$UID" ]; then chown -R $UID $arch_dir; fi
        if [ ! -z "$GID" ]; then chown -R :$GID $arch_dir; fi
    fi
fi
