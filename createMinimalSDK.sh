#!/bin/bash

if [ "$1" = "-clean" ]; then
	rm -rf tmpSDK
fi

mkdir -p tmpSDK

# Unpack and trim the Hexagon SDK
./installsdk.sh --APQ8074 --no-verify --trim --arm-gcc `pwd`/tmpSDK

export HEXAGON_SDK_ROOT=`pwd`/tmpSDK/Qualcomm/Hexagon_SDK/3.0
export HEXAGON_TOOLS_ROOT=`pwd`/tmpSDK/Qualcomm/HEXAGON_Tools/7.2.12/Tools

# FIXME - reintegrate qrlSDK
# Unpack and trim the qrlSDK
#./qrlinux_sysroot.sh -trim

# Create a tgz of the minimal install for use in a docker image
#cd tmpSDK
#tar czf ../minimalSDK.tgz Qualcomm

