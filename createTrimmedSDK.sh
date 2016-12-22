#!/bin/bash

if [ "$1" = "-clean" ]; then
	rm -rf tmpSDK
fi

mkdir -p tmpSDK

# Unpack and trim the Hexagon SDK
./installv3.sh -no-verify -trim `pwd`/tmpSDK

export HEXAGON_SDK_ROOT=`pwd`/tmpSDK/Qualcomm/Hexagon_SDK/3.0
export HEXAGON_TOOLS_ROOT=`pwd`/tmpSDK/Qualcomm/HEXAGON_Tools/7.2.12/Tools

# Unpack and trim the qrlSDK
./qrlinux_sysroot.sh -trim

# Create a tgz of the trimmed install for use in a docker image
cd tmpSDK
tar czf ../trimmedSDK.tgz Qualcomm

