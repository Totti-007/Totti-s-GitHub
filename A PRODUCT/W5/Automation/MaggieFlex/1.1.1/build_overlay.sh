#!/bin/sh

CURRENT_DATE=$(
	date +%Y%m%d-%H%M%S
)

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
overlay_dir="$DIR_SRC/tmp/MaggieFCT-Overlay"
overlay_atlas="${overlay_dir}/Users/gdlocal/Library/Atlas"

rm -rf "${overlay_dir}"

RUSH_FILES=(
"SendSync.rush"
"Station.rush"
)

sequence_dir="${srcroot}/Atlas/Sequences"
cd "$sequence_dir"
pwd
for file in "${RUSH_FILES[@]}"
do
    /AppleInternal/Library/Frameworks/Rush.framework/bin/rushc $file
done

for file in "${RUSH_FILES[@]}"
do
    rm "${file}o"
done

cd "${srcroot}/../"

cd $srcroot
ditto "Overlay" "${overlay_dir}"


cd Atlas
ditto "Configs" "${overlay_atlas}/Configs"
ditto "Modules" "${overlay_atlas}/Modules"
ditto "Plugins" "${overlay_atlas}/Plugins"
ditto "Sequences" "${overlay_atlas}/Sequences"
ditto "Resources" "${overlay_atlas}/Resources"
#Cut Resources/IntelligentAutomation out. We don't actually use the Lua or anything it live and it causes
#weird code signing enforcement issues with Atlas.
rm -rf "${overlay_atlas}/Resources/IntelligentAutomation"

atlas-metadata -s "MaggieFCT" -p "HFXwgT85F2BNkUGg" -f "${overlay_atlas}/Resources" -d N157
atlas-signer -t "${overlay_atlas}" -p "HFXwgT85F2BNkUGg"

echo "Zipping..."

ditto -ck --keepParent $overlay_dir "${overlay_dir}.zip"
openssl sha1 "${overlay_dir}.zip"
