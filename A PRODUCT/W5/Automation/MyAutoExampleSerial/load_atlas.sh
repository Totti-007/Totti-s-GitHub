#!/bin/sh
echo "\n-----------log------------"
cd $(dirname $0)
folderPath=$(pwd)
sourcePath="${folderPath}/Atlas"
echo "sourcePath:" $sourcePath
targetPath="${HOME}/Library/Atlas"
echo "targetPath:" $targetPath

rm -rf "${targetPath}"
cp -rf "${sourcePath}" "${targetPath}"
atlas-metadata -s "SMT-SENSOR" -p "HFXwgT85F2BNkUGg" -f "${targetPath}/Resources" -d X1628
atlas-signer -t "${targetPath}" -p "HFXwgT85F2BNkUGg"

echo "-->>finish task."
echo "\n-----------------------"