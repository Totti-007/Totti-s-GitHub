#!/bin/sh

findme()
{
	dir=$(dirname "$1")
	cd "${dir}"
	pwd
}

cmd=install
mode=Debug
srcroot=$(findme "$0")
sympath="$DIR_SRC/tmp/Symroot"-$(md5 -qs "${srcroot}")
symroot="SYMROOT=${sympath}"
overlay_dir="$DIR_SRC/tmp/MaggieFCT-Core-Overlay"
overlay_atlas="${overlay_dir}/Users/gdlocal/Library/Atlas"

rm -rf "${overlay_dir}"

cd $srcroot
ditto "CoreOverlay" "${overlay_dir}"

echo "Zipping..."

ditto -ck --keepParent $overlay_dir "${overlay_dir}.zip"
openssl sha1 "${overlay_dir}.zip"
