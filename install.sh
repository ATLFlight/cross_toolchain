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


if [ "${HEXAGON_SDK_ROOT}" = "" || ! -f ${HEXAGON_SDK_ROOT}/tools/qaic/Ubuntu14/qaic ]; then
	echo "Must install Hexagon SDK and set HEXAGON_SDK_ROOT"
	exit 1
fi

# Set up the Hexagon SDK
if [ ! -f ${HEXAGON_SDK_ROOT}/tools/qaic/Linux/qaic ]; then
	pushd .
	cd ${HEXAGON_SDK_ROOT}/tools/qaic/
	make
	popd
fi

mkdir -p install_state
mkdir -p downloads

# Fetch compiler
if [ ! -f downloads/gcc-linaro-arm-linux-gnueabihf-4.8-2013.08_linux.tar.xz ]; then
	wget -P downloads https://launchpad.net/linaro-toolchain-binaries/trunk/2013.08/+download/gcc-linaro-arm-linux-gnueabihf-4.8-2013.08_linux.tar.xz
fi

if [ ! -f downloads/ubuntu-core-14.04-core-armhf.tar.gz ]; then
	wget -P downloads http://cdimage.ubuntu.com/ubuntu-core/releases/14.04.3/release/ubuntu-core-14.04-core-armhf.tar.gz
fi

if [ ! -d ${HEXAGON_SDK_ROOT}/gcc-linaro-arm-linux-gnueabihf-4.8-2013.08_linux ]; then
	tar -C ${HEXAGON_SDK_ROOT} -xJf downloads/gcc-linaro-arm-linux-gnueabihf-4.8-2013.08_linux.tar.xz
fi

if [ ! -f install_state/SYSROOT_UNPACKED || ! -d ${HEXAGON_SDK_ROOT}/sysroot ]; then
	mkdir -p ${HEXAGON_SDK_ROOT}/sysroot
	tar -C ${HEXAGON_SDK_ROOT}/sysroot --exclude="dev/*" -xzf downloads/ubuntu-core-14.04-core-armhf.tar.gz
	echo "${HEXAGON_SDK_ROOT}/sysroot" > install_state/SYSROOT_UNPACKED
fi

# Copy setup script to the sysroot
cp setup.sh ${HEXAGON_SDK_ROOT}/sysroot/setup.sh

if [ ! -f /usr/bin/qemu-arm-static ]; then
	echo "Install of qemu-user-static requires sudo"
	sudo apt-get install -y qemu-user-static
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

if [ ! -f install_state/SYSROOT_CONFIGURED ]; then
	unmount_sysroot
	mount_sysroot
	echo "Installing required packages"
	sudo chroot ${HEXAGON_SDK_ROOT}/sysroot /setup.sh
	unmount_sysroot
	touch install_state/SYSROOT_CONFIGURED
fi

echo "Cross compiler is at: ${HEXAGON_SDK_ROOT}/gcc-linaro-arm-linux-gnueabihf-4.8-2013.08_linux"
echo "Sysroot is at:        ${HEXAGON_SDK_ROOT}/sysroot"
echo "Make sure to set the following environment variables:"
echo "   export HEXAGON_SDK_ROOT=${HEXAGON_SDK_ROOT}"
echo "   export HEXAGON_TOOLS_ROOT=${HEXAGON_TOOLS_ROOT}"
echo "   export HEXAGON_ARM_SYSROOT=${HEXAGON_SDK_ROOT}/sysroot"
echo Done
