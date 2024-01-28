#!/usr/bin/env bash
# Automatic OTA Script
# Copyright (C) 2023 PixelBlaster-OS

VERSION="6.4"
DEVICE_NAME=$1
ZIP_NAME=$2
ID=$(md5sum $ZIP_NAME | awk '{print $1}')
Date=$(grep "ro.build.date.utc=" out/target/product/$DEVICE_NAME/system/build.prop | cut -d "=" -f 2)
Size=$(wc -c $ZIP_NAME | awk '{print $1}')
git clone https://github.com/PixelBlaster-releases/$DEVICE_NAME
cp $ZIP_NAME $DEVICE_NAME/
cd $DEVICE_NAME
OTA_URL=$(gh release create v$VERSION -n "" -t "PixelBlaster v$VERSION | $DEVICE_NAME" $ZIP_NAME)
OTA_JSON='{\n"response": [\n{\n"datetime": %s,\n"filename": "%s",\n"id": "%s", \n"romtype": "OFFICIAL", \n"size": %s, \n"url": "https://github.com/PixelBlaster-Releases/%s/releases/download/v%s/%s", \n"version": "%s"\n}\n        ]\n}'
printf "$OTA_JSON" "$Date" "$ZIP_NAME" "$ID" "$Size" "$DEVICE_NAME" "$VERSION" "$ZIP_NAME" "$VERSION" >ota.json
git add ota.json
git commit -m "OTA for $DEVICE_NAME"
git push
cd ..
rm -rf $DEVICE_NAME
