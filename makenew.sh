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
VERSION="$1"; VERSION="${VERSION:=2.4.7}"
#
PKG_DIR=$PKGNAME-$VERSION
#
INDEXPHP="tinyfilemanager.php"
CFGSAMPl="config-sample.php"
LANGFILE="translation.json"

# Constants
FM_HIGHLIGHTJS_STYLE='vs' # tinyfilemanager.php#L51; tinyfilemanager.php#L417


PROJDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # <--
WORKDIR="$PROJDIR/htdocs/$PKGNAME" # <--
mkdir -p "$WORKDIR" 2>/dev/null
cd $WORKDIR



# Clear Old version
rm -rf *

# Download Repository
curl -L ${REPOURL}/archive/refs/tags/${VERSION}.tar.gz | tar -xvz -C "$WORKDIR"

# Preprocessing
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
mv "$WORKDIR/js/bootstrap.min.js~" "$WORKDIR/js/bootstrap.slim.min.js"
sed -i "/jquery.slim.min.js/,/}/ {s|bootstrap.min.js|bootstrap.slim.min.js|}" "$PKG_DIR/$INDEXPHP"

# Migrating to Local Reference
sed -Ei "s,^(.+=\")(http(s)?://.+/)([^/]+\.(css|js))(\".+),\1\5/\4\6," "$PKG_DIR/$INDEXPHP"

# Clean up and Done
mv -f "$PKG_DIR/$INDEXPHP" ./index.php
mv -f "$PKG_DIR/$CFGSAMPl" .
mv -f "$PKG_DIR/$LANGFILE" .
rm -rf "$PKG_DIR"
