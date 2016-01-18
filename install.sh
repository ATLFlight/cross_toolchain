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

trap fail_on_error ERR

function fail_on_errors() {
   echo "Error: Script aborted";
   exit 1;
}

if [ ! -f /usr/bin/qemu-arm-static ]; then
	echo "Install of qemu-user-static requires sudo"
	sudo apt-get install -y qemu-user-static
fi

if [ ! -f /usr/bin/fakechroot ]; then
	echo "Install of qemu-user-static requires sudo"
	sudo apt-get install -y fakechroot
fi

if [ "${HEXAGON_TOOLS_ROOT}" = "" ]; then
	HEXAGON_TOOLS_ROOT=${HOME}/Qualcomm/HEXAGON_Tools/7.2.10/Tools
fi

if [ "${HEXAGON_SDK_ROOT}" = "" ]; then
	HEXAGON_SDK_ROOT=${HOME}/Qualcomm/Hexagon_SDK/2.0
fi

read -r -p "${1:-HEXAGON_SDK_ROOT [${HEXAGON_SDK_ROOT}]} " response
if [ ! "$response" = "" ]; then
	HEXAGON_SDK_ROOT=$response
fi

read -r -p "${1:-HEXAGON_TOOLS_ROOT [${HEXAGON_TOOLS_ROOT}]} " response
if [ ! "$response" = "" ]; then
	HEXAGON_TOOLS_ROOT=$response
fi

if [ ! -f ${HEXAGON_SDK_ROOT}/tools/qaic/Ubuntu14/qaic ]; then

	echo "Hexagon SDK not installed ${HEXAGON_SDK_ROOT}/tools/qaic/Ubuntu14/qaic"
	if [ -f downloads/qualcomm_hexagon_sdk_2_0_eval.bin ]; then
		echo "Installing HEXAGON_SDK to ${HEXAGON_SDK_ROOT}"
		echo "You can un-check all 3 add-on options (Android NDK, Eclipse, Hexagon Tools)"
		sh ./downloads/qualcomm_hexagon_sdk_2_0_eval.bin -i swing -DUSER_INSTALL_DIR=${HEXAGON_SDK_ROOT}
	else
		echo "Put the file qualcomm_hexagon_sdk_2_0_eval.bin in the downloads directory"
	fi
fi

# Verify required tools were installed
if [ ! -f ${HEXAGON_SDK_ROOT}/tools/qaic/Ubuntu14/qaic ] || [ ! -f ${HEXAGON_SDK_ROOT}/tools/mini-dm/Linux_Debug/mini-dm ]; then
	echo "Failed to install Hexagon SDK"
	exit 1
fi

# Set up the Hexagon SDK
if [ ! -f ${HEXAGON_SDK_ROOT}/tools/qaic/Linux/qaic ]; then
	pushd .
	cd ${HEXAGON_SDK_ROOT}/tools/qaic/
	make
	popd
fi

# Verify setup is complete
if [ ! -f ${HEXAGON_SDK_ROOT}/tools/qaic/Linux/qaic ]; then
	echo "Failed to set up Hexagon SDK"
	exit 1
fi

if [ ! -f ${HEXAGON_TOOLS_ROOT}/bin/hexagon-clang ]; then

	if [ -f downloads/Hexagon.LNX.7.2\ Installer-07210.1.tar ]; then
		tar -C downloads -xf downloads/Hexagon.LNX.7.2\ Installer-07210.1.tar
	else
		echo "Put the file Hexagon.LNX.7.2\ Installer-07210.1.tar in the downloads directory"
		echo "and re-run this script"
		exit 1
	fi

	if [ -f downloads/Hexagon.LLVM_linux_installer_7.2.10.bin ]; then
		sh downloads/Hexagon.LLVM_linux_installer_7.2.10.bin -i silent
	else
		echo "Failed to untar downloads/Hexagon.LNX.7.2\ Installer-07210.1.tar"
		echo "Missing downloads/Hexagon.LLVM_linux_installer_7.2.10.bin"
		exit 1
	fi

fi

# Fetch ARMv7hf cross compiler
if [ ! -f downloads/gcc-linaro-arm-linux-gnueabihf-4.8-2013.08_linux.tar.xz ]; then
	wget -P downloads https://launchpad.net/linaro-toolchain-binaries/trunk/2013.08/+download/gcc-linaro-arm-linux-gnueabihf-4.8-2013.08_linux.tar.xz
fi

# Fetch Ubuntu 14.04 ARM image
if [ ! -f downloads/ubuntu-core-14.04-core-armhf.tar.gz ]; then
	wget -P downloads http://cdimage.ubuntu.com/ubuntu-core/releases/14.04.3/release/ubuntu-core-14.04-core-armhf.tar.gz
fi

if [ ! -d ${HEXAGON_SDK_ROOT}/gcc-linaro-arm-linux-gnueabihf-4.8-2013.08_linux ]; then
	tar -C ${HEXAGON_SDK_ROOT} -xJf downloads/gcc-linaro-arm-linux-gnueabihf-4.8-2013.08_linux.tar.xz
fi

if [ ! -f ${HEXAGON_SDK_ROOT}/sysroot/SYSROOT_UNPACKED ]; then
	mkdir -p ${HEXAGON_SDK_ROOT}/sysroot
	tar -C ${HEXAGON_SDK_ROOT}/sysroot --exclude="dev/*" -xzf downloads/ubuntu-core-14.04-core-armhf.tar.gz
	echo "${HEXAGON_SDK_ROOT}/sysroot" > ${HEXAGON_SDK_ROOT}/sysroot/SYSROOT_UNPACKED
fi


# Copy qemu-arm-static to sysroot to install more packages
cp /usr/bin/qemu-arm-static ${HEXAGON_SDK_ROOT}/sysroot/usr/bin/qemu-arm-static

function unmount_sysroot {
	echo "Unmounting sysroot mounts"
	if mount | grep ${HEXAGON_SDK_ROOT}/sysroot/sys > /dev/null; then
		sudo umount ${HEXAGON_SDK_ROOT}/sysroot/sys
	fi
	if mount | grep ${HEXAGON_SDK_ROOT}/sysroot/proc > /dev/null; then
		sudo umount ${HEXAGON_SDK_ROOT}/sysroot/proc
	fi
	if mount | grep ${HEXAGON_SDK_ROOT}/sysroot/dev > /dev/null; then
		sudo umount ${HEXAGON_SDK_ROOT}/sysroot/dev
	fi
}

function mount_sysroot {
	echo "mounting sysroot mounts"
	sudo mount -o bind /dev ${HEXAGON_SDK_ROOT}/sysroot/dev
	sudo mount -o bind /sys ${HEXAGON_SDK_ROOT}/sysroot/sys
	sudo mount -t proc /proc ${HEXAGON_SDK_ROOT}/sysroot/proc
	sudo cp /proc/mounts ${HEXAGON_SDK_ROOT}/sysroot/etc/mtab
}

# Add needed packages to sysroot
if [ ! -f ${HEXAGON_SDK_ROOT}/sysroot/SYSROOT_CONFIGURED ]; then
	fakechroot fakeroot /usr/sbin/chroot ${HEXAGON_SDK_ROOT}/sysroot /setup.sh

#	unmount_sysroot
#	mount_sysroot
#	echo "Installing required packages"
#	cp setup.sh ${HEXAGON_SDK_ROOT}/sysroot/setup.sh
#	sudo chroot ${HEXAGON_SDK_ROOT}/sysroot /setup.sh
#	unmount_sysroot
	touch ${HEXAGON_SDK_ROOT}/sysroot/SYSROOT_CONFIGURED
fi

echo "Cross compiler is at: ${HEXAGON_SDK_ROOT}/gcc-linaro-arm-linux-gnueabihf-4.8-2013.08_linux"
echo "Sysroot is at:        ${HEXAGON_SDK_ROOT}/sysroot"
echo "Make sure to set the following environment variables:"
echo "   export HEXAGON_SDK_ROOT=${HEXAGON_SDK_ROOT}"
echo "   export HEXAGON_TOOLS_ROOT=${HEXAGON_TOOLS_ROOT}"
echo "   export HEXAGON_ARM_SYSROOT=${HEXAGON_SDK_ROOT}/sysroot"
echo Done
