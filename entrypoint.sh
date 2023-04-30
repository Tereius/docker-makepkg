#! /bin/bash

extract() {
     if [ -f $1 ] ; then
         case $1 in
             *.tar.bz2)   tar xjf $1     ;;
             *.tar.gz)    tar xzf $1     ;;
             *.tar)       tar xf $1      ;;
             *.tbz2)      tar xjf $1     ;;
             *.tgz)       tar xzf $1     ;;
             *.zip)       unzip -q $1    ;;
             *)           echo "'$1' cannot be extracted via extract()" ;;
         esac
     else
         echo "'$1' is not a valid file"
     fi
}

pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd "$@" > /dev/null
}

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

    hash_dir=$( mktemp -d -t hashes.XXXXXXXXX )
    chown -R buildhelper:buildhelper $hash_dir

    while :
    do

        pacman -Syu --noconfirm

        for url in "$@"
        do
            tmp_dir=$( mktemp -d -t buildhelper.XXXXXXXXX )
            pushd "$tmp_dir"
            echo "---------------- Downloading $url to $tmp_dir"
            wget -q --content-disposition "$url" -P ./
            hash=$(sha256sum ./* | sha256sum | awk '{print $1}')
            if [ ! -f "$hash_dir/$hash" ]; then
                find "$(cd $tmp_dir; pwd)" -name '*' -type f -print0 |
                    while IFS= read -r -d '' downloaded_file; do
                        echo "---------------- Extracting $downloaded_file"
                        extract "$downloaded_file"
                    done

                touch "$hash_dir/$hash"
                chown buildhelper:buildhelper "$hash_dir/$hash"

                find "$(cd $tmp_dir; pwd)" -name 'PKGBUILD' -type f -print0 |
                    while IFS= read -r -d '' pkgbuild_file; do
                        chown -R buildhelper:buildhelper ./
                        echo "---------------- Building PKGBUILD file: $pkgbuild_file"
                        pushd "$(dirname $pkgbuild_file)"
                        su buildhelper -c "makepkg -m -f -c -C -s -i --noconfirm --skipinteg &> build.log || rm -f $hash_dir/$hash; cat build.log"

                        if [ -z "$PKG_OVERWRITE" ]; then
                            cp -n *.pkg.* $out_dir 
                        else
                            cp *.pkg.* $out_dir
                        fi
                        if [ ! -z "$UID" ]; then chown $UID $out_dir/*.pkg.*; fi
                        if [ ! -z "$GID" ]; then chown :$GID $out_dir/*.pkg.*; fi
                        popd
                    done
            else
                echo "---------------- Skipping (no changes detected): $url"
            fi

            popd
            rm -rf "$tmp_dir"
        done

        if [ ! -z "$ARCH_REPO_NAME" ]; then
            echo "---------------- Creating/Updating repo with name \"$ARCH_REPO_NAME\""
            repo-add --nocolor -R $out_dir/$ARCH_REPO_NAME.db.tar.gz $out_dir/*.pkg.*
            if [ ! -z "$UID" ]; then chown -R $UID $arch_dir; fi
            if [ ! -z "$GID" ]; then chown -R :$GID $arch_dir; fi
        fi

        if [ -z "$CONTINUOUS" ]; then
            break
        else
            echo "---------------- Finished - waiting for next run in $CONTINUOUS_INTERVAL_SEC seconds"
            sleep $CONTINUOUS_INTERVAL_SEC
        fi
    done

fi
