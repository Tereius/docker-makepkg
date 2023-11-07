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

installPkgFromUrl() {

    if [ ! -z "$1" ] ; then
        url=$1
        tmp_dir=$( mktemp -d -t buildhelper.XXXXXXXXX )
        pushd "$tmp_dir"
        echo "---------------- Downloading $url to $tmp_dir"
        wget -q --content-disposition "$url" -P ./

        find "$(cd $tmp_dir; pwd)" -name '*' -type f -print0 |
            while IFS= read -r -d '' downloaded_file; do
                echo "---------------- Extracting $downloaded_file"
                extract "$downloaded_file"
            done

        find "$(cd $tmp_dir; pwd)" -name 'PKGBUILD' -type f -print0 |
            while IFS= read -r -d '' pkgbuild_file; do
                chown -R buildhelper:buildhelper ./
                echo "---------------- Building PKGBUILD file: $pkgbuild_file"
                pushd "$(dirname $pkgbuild_file)"
                su buildhelper -c "makepkg -m -f -c -C -s -i --noconfirm --skipinteg &> build.log || { cat build.log; }"
                popd
            done

        popd
        rm -rf "$tmp_dir"
    else
         echo "Expecting one parameter pointing to a url"
     fi
}

if [ -z "$1" ]; then
    echo "Expecting at least one URL pointing to a PKGBUILD file or a zip/tar archive containing a PKGBUILD file."
    exit 1
else

    packman_conf="/etc/pacman.conf"
    out_dir="/out/arch-repo/x86_64"
    if [ -z "$ARCH_REPO_NAME" ]; then
        ARCH_REPO_NAME=unknown
    fi
    out_file="$out_dir/$ARCH_REPO_NAME.db.tar.gz"

    if ! grep -q "#BEACON" $packman_conf; then
        echo "[$ARCH_REPO_NAME]" >> /etc/pacman.conf
        echo "SigLevel = Optional TrustAll" >> /etc/pacman.conf
        echo "Server = file://${out_dir}" >> /etc/pacman.conf
        echo "#BEACON" >> /etc/pacman.conf
    fi

    if [ ! -f "$out_file" ]; then
        install -o buildhelper -g buildhelper -d "${out_dir}"
        su buildhelper -c "repo-add --nocolor "${out_file}""
    fi

    pacman -Syu --noconfirm

    installPkgFromUrl "https://aur.archlinux.org/cgit/aur.git/snapshot/aurutils.tar.gz"

    while :
    do
        for url in "$@"; do
            if grep -q "https://" <<< "$url" || grep -q "http://" <<< "$url"; then
                tmp_dir=$( mktemp -d -t buildhelper.XXXXXXXXX )
                pushd "$tmp_dir"
                wget -q --content-disposition "$url" -P ./
                find "$(cd $tmp_dir; pwd)" -name '*' -type f -print0 |
                    while IFS= read -r -d '' downloaded_file; do
                        echo "---------------- Extracting $downloaded_file"
                        extract "$downloaded_file"
                    done
                find "$(cd $tmp_dir; pwd)" -name 'PKGBUILD' -type f -print0 |
                    while IFS= read -r -d '' pkgbuild_file; do
                        chown -R buildhelper:buildhelper ./
                        echo "---------------- Building PKGBUILD file: $pkgbuild_file"
                        pushd "$(dirname $pkgbuild_file)"
                        su buildhelper -c "aur build -d $ARCH_REPO_NAME --noconfirm -C -s --margs --skipinteg,-m"
                        popd
                    done
                popd
                rm -rf "$tmp_dir"
            else
                echo "---------------- Building AUR package: $url"
                su buildhelper -c "aur sync -d $ARCH_REPO_NAME --noconfirm --optdepends --noview $url"
            fi
        done

        echo "---------------- Finished - waiting for next run in $CONTINUOUS_INTERVAL_SEC seconds"
        sleep $CONTINUOUS_INTERVAL_SEC
    done
fi
