#!/bin/bash
############################################################################
#
#   Copyright (c) 2016 Mark Charlebois. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in
#    the documentation and/or other materials provided with the
#    distribution.
# 3. Neither the name ATLFlight nor the names of its contributors may be
#    used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
# OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
# AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
############################################################################

# Installer script for QRLinux ARMv7hf sysroot

QRLSDK=qrlSDK
QRLSDKTGZ=${QRLSDK}.tgz

# Verify the ${QRLSDKTGZ} file was downloaded from Intrinsyc
if [ ! -f downloads/${QRLSDKTGZ} ]; then
	echo
	echo "Please put the ${QRLSDKTGZ} file from the following link into the downloads"
	echo "directory and re-run this script:"
	echo "   http://support.intrinsyc.com/attachments/download/690/${QRLSDKTGZ}"
	exit 1
fi

# It is not possible to add extra packages into the qrlSDK

if [ "${HEXAGON_ARM_SYSROOT}" = "" ]; then
	# If HEXAGON_SDK_ROOT is set, deduce what HOME should be
	echo ${HEXAGON_SDK_ROOT}
	if [[ ${HEXAGON_SDK_ROOT} = */Qualcomm/Hexagon_SDK/3.0 ]]; then
		HOME=`echo ${HEXAGON_SDK_ROOT} | sed -e "s#/Qualcomm/Hexagon_SDK/.*##"`
	else
		echo "HEXAGON_SDK_ROOT not valid"
		exit 1
	fi

	HEXAGON_ARM_SYSROOT=${HOME}/Qualcomm/qrlinux_v3.1.1_sysroot
fi

if [[ ${HEXAGON_ARM_SYSROOT} = */Qualcomm/qrlinux_v3.1.1_sysroot ]]; then
	echo "Installing QRLinux sysroot"
else
	echo "Invalid install path for HEXAGON_ARM_SYSROOT"
	echo "Path must end in .../Qualcomm/qrlinux_v3.1.1_sysroot"
	echo "Try 'unset HEXAGON_ARM_SYSROOT' then re-run this script"
	exit 1
fi

if [ "$1" = "--clean" ]; then
	if [ -d ${HEXAGON_ARM_SYSROOT} ]; then
		echo "Removing previous QRLinux sysroot installation"
		rm -rf ${HEXAGON_ARM_SYSROOT}
	fi
fi

# Unpack sysroot
if [ ! -f ${HEXAGON_ARM_SYSROOT}/var/opt/SYSROOT_UNPACKED ]; then
	mkdir -p ${HEXAGON_ARM_SYSROOT}
	echo "Unpacking sysroot..."
	if [ ! -d downloads/qrlSDK ]; then
		echo "Extracting qrlSDK tar file"
		cd downloads && tar xzf ${QRLSDKTGZ}
		cd ..
	fi
	if [ ! -f downloads/qrlSDK/qrlSysroots.tgz ]; then
		echo "QRLinux SDK unpack failed"
		exit 1
	fi

	echo "Extracting qrlSDK tar file"
	if [ ! -d downloads/qrlSDK/sysroots/eagle8074/linaro-rootfs ]; then
		tar -C downloads/qrlSDK -xzf downloads/qrlSDK/qrlSysroots.tgz sysroots/eagle8074
	fi
	mkdir -p ${HEXAGON_ARM_SYSROOT}
	echo "copying to ${HEXAGON_ARM_SYSROOT}"
	cp -arp downloads/qrlSDK/sysroots/eagle8074/* ${HEXAGON_ARM_SYSROOT}
	mkdir -p ${HEXAGON_ARM_SYSROOT}/var/opt
	cp /usr/bin/qemu-arm-static ${HEXAGON_ARM_SYSROOT}/usr/bin
	echo "${HEXAGON_ARM_SYSROOT}" > ${HEXAGON_ARM_SYSROOT}/var/opt/SYSROOT_UNPACKED
fi


echo Done
echo "--------------------------------------------------------------------"
echo "armv7hf sysroot is at:        ${HEXAGON_ARM_SYSROOT}"
echo
echo "Make sure to set the following environment variables:"
echo "   export HEXAGON_ARM_SYSROOT=${HEXAGON_ARM_SYSROOT}"
echo
