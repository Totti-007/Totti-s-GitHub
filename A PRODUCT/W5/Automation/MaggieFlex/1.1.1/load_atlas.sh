#!/bin/sh
cd $(dirname $0)
folderPath=$(pwd)
sourcePath="${folderPath}/Atlas"
echo $sourcePath
targetPath="${HOME}/Library/Atlas"
echo $targetPath

rm -rf "${targetPath}"
cp -rf "${sourcePath}" "${targetPath}"
atlas-metadata -s "MaggieFCT" -p "HFXwgT85F2BNkUGg" -f "${targetPath}/Resources" -d N157
atlas-signer -t "${targetPath}" -p "HFXwgT85F2BNkUGg"

echo "-->>finish task."
