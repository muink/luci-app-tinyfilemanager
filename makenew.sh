#!/bin/bash
# dependent: curl tar 
#
# LuCI Tiny File Manager
# Author: muink
# Github: https://github.com/muink/luci-app-tinyfilemanager
#

# PKGInfo
REPOURL='https://github.com/prasathmani/tinyfilemanager'
PKGNAME='tinyfilemanager'
VERSION='2.5.0'
#
PKG_DIR=$PKGNAME-$VERSION
#
INDEXPHP="tinyfilemanager.php"
#CFGSAMPl="config-sample.php"
LANGFILE="translation.json"


PROJDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # <--
WORKDIR="$PROJDIR/htdocs/$PKGNAME" # <--
mkdir -p "$WORKDIR" 2>/dev/null
cd $WORKDIR



# Clear Old version
rm -rf *

# Download Repository
curl -L ${REPOURL}/archive/refs/tags/${VERSION}.tar.gz | tar -xvz -C "$WORKDIR"

# Preprocessing
FM_HIGHLIGHTJS_STYLE=$(sed -En "s|^\\\$highlightjs_style = *'([^']*)';|\1|p" "$PKG_DIR/$INDEXPHP")
sed -i "s|<?php echo FM_HIGHLIGHTJS_STYLE ?>|\$FM_HIGHLIGHTJS_STYLE|g" "$PKG_DIR/$INDEXPHP"

# Download CDN Used
refurl=($(sed -En "s,^.+=\"(http(s)?://.+\.(css|js))\".+,\1, p" "$PKG_DIR/$INDEXPHP" | sort -u ))
ref=
url=
out=
type=

for _i in $(seq 0 1 $[ ${#refurl[@]} -1 ]); do
    eval "url=${refurl[$_i]}"
    out=${url##*/}
    type=${url##*.}

    curl -Lo $out $url
    mkdir -p $type 2>/dev/null
    mv --backup $out $type/
done

ref=$(for _p in $(find * -type f ! -path "$PKG_DIR/*"); do \
        sed -E "s/(,|;)/\1\n/g" $_p | grep -E "\burl\([^\)]+\)" | grep -Ev "\burl\(\"data:image" >/dev/null; \
        [ "$?" == "0" ] && echo $_p; \
    done)

for _i in $ref; do
    suburl=($(sed -E "s/(,|;)/\1\n/g" $_i | grep -E "\burl\([^\)]+\)" | grep -Ev "\burl\(\"data:image" | sed -En "s|^[^']+'([^']+)'.+|\1| p"))
    hosturl=$(for _ in "${refurl[@]}"; do echo "$_" | grep "${_i##*/}"; done)

    for _j in $(seq 0 1 $[ ${#suburl[@]} -1 ]); do
        url="${suburl[$_j]}"
        out=${url%%\?*}
        type=${hosturl##*.}

        mkdir -p "$type/${out%/*}" 2>/dev/null
        curl -Lo ${out##*/} "${hosturl%/*}/$url"
        mv -f ${out##*/} "$type/$out"
    done
done

# Post-processing
sed -i "s|\$FM_HIGHLIGHTJS_STYLE|<?php echo FM_HIGHLIGHTJS_STYLE ?>|g" "$PKG_DIR/$INDEXPHP"
#mv "$WORKDIR/js/bootstrap.min.js~" "$WORKDIR/js/bootstrap.slim.min.js"
#sed -i "/jquery.slim.min.js/,/}/ {s|bootstrap.min.js|bootstrap.slim.min.js|}" "$PKG_DIR/$INDEXPHP"
sed -Ei "/<link rel=\"(preconnect|dns-prefetch)\"/d" "$PKG_DIR/$INDEXPHP"

# Fix
sed -Ei "/^\/\/ Auth/,/^}/{/\/\/ Logging In/,/\/\/ Form/{s|(fm_redirect\()FM_ROOT_URL \. |\1|g}}" "$PKG_DIR/$INDEXPHP"

# Migrating to Local Reference
sed -Ei "s,^(.+=\")(http(s)?://.+/)([^/]+\.(css|js))(\".+),\1\5/\4\6," "$PKG_DIR/$INDEXPHP"

# Clean up and Done
mv -f "$PKG_DIR/$INDEXPHP" ./index.php
#mv -f "$PKG_DIR/$CFGSAMPl" .
mv -f "$PKG_DIR/$LANGFILE" .
rm -rf "$PKG_DIR"

# Package
sed -Ei "/^VERSION=/{s|(VERSION:=)[^\}]*|\1$VERSION|}" "$PROJDIR/root/usr/libexec/tinyfilemanager-update"
sed -Ei "s|(VERSION=).*|\1'$VERSION'|" "$PROJDIR/root/etc/init.d/tinyfilemanager"
sed -Ei "s|(pkgversion =).*|\1 '$VERSION';|" "$PROJDIR/htdocs/luci-static/resources/view/tinyfilemanager/config.js"
sed -Ei "s|(PKG_VERSION:=)[^-]+|\1$VERSION|" "$PROJDIR/Makefile"
tar -czvf index.tgz * --owner=0 --group=0 --remove-files
