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

# Extra packages to add to install to armhf sysroot
EXTRA_PACKAGES=""

# Install package deps
if [ ! -f /usr/bin/qemu-arm-static ] || [ ! -f /usr/bin/fakechroot ]; then
	if [ ! "${EXTRA_PACKAGES}" = "" ]; then
		echo "Please install qemu-user-static and fakechroot"
		echo "sudo apt-get install qemu-user-static fakechroot"
	fi
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

if [ "${HEXAGON_ARM_SYSROOT}" = "" ]; then
	HEXAGON_ARM_SYSROOT=${HEXAGON_SDK_ROOT}/sysroot
fi

read -r -p "${1:-HEXAGON_ARM_SYSROOT [${HEXAGON_ARM_SYSROOT}]} " response
if [ ! "$response" = "" ]; then
	HEXAGON_ARM_SYSROOT=$response
fi

if [ ! -f ${HEXAGON_SDK_ROOT}/tools/qaic/Ubuntu14/qaic ]; then

	echo "Hexagon SDK not installed ${HEXAGON_SDK_ROOT}/tools/qaic/Ubuntu14/qaic"
	if [ -f downloads/qualcomm_hexagon_sdk_2_0_eval.bin ]; then
		echo "Installing HEXAGON_SDK to ${HEXAGON_SDK_ROOT}"
		echo
		echo "***************************************************************************"
		echo "NOTE: "
		echo "You can un-check all 3 add-on options (Android NDK, Eclipse, Hexagon Tools)"
		echo "in the installer screen"
		echo "***************************************************************************"
		echo
		sh ./downloads/qualcomm_hexagon_sdk_2_0_eval.bin -i swing -DUSER_INSTALL_DIR=${HEXAGON_SDK_ROOT}
	else
		echo
		echo "Put the file qualcomm_hexagon_sdk_2_0_eval.bin in the downloads directory"
		echo "and re-run this script."
		echo "If you do not have the file, you can download it from:"
		echo "    https://developer.qualcomm.com/download/hexagon/hexagon-sdk-linux.bin"
		echo
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
		echo "Installing Hexagon Tools 7.2.10 ..."
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

# Fetch Ubuntu 14.04 ARM image for sysroot
if [ ! -f downloads/ubuntu-trusty-14.04-armhf.com-20140603.tar.xz ]; then
	#wget -P downloads http://cdimage.ubuntu.com/ubuntu-core/releases/14.04.3/release/ubuntu-core-14.04-core-armhf.tar.gz
	wget -P downloads http://s3.armhf.com/dist/basefs/ubuntu-trusty-14.04-armhf.com-20140603.tar.xz
fi

# Unpack armhf cross compiler
if [ ! -d ${HEXAGON_SDK_ROOT}/gcc-linaro-arm-linux-gnueabihf-4.8-2013.08_linux ]; then
	echo "Unpacking cross compiler..."
	tar -C ${HEXAGON_SDK_ROOT} -xJf downloads/gcc-linaro-arm-linux-gnueabihf-4.8-2013.08_linux.tar.xz
fi

# Unpack sysroot 
if [ ! -f ${HEXAGON_ARM_SYSROOT}/SYSROOT_UNPACKED ]; then
	mkdir -p ${HEXAGON_ARM_SYSROOT}
	echo "Unpacking sysroot..."
	tar -C ${HEXAGON_ARM_SYSROOT} --exclude="dev/*" -xJf downloads/ubuntu-trusty-14.04-armhf.com-20140603.tar.xz && echo "${HEXAGON_ARM_SYSROOT}" > ${HEXAGON_ARM_SYSROOT}/SYSROOT_UNPACKED
fi

# fakechroot is used to install additional packages without using sudo
# It requires a little extra magic to make it work with misc-binfmt and qemu
if [ ! "${EXTRA_PACKAGES}" = "" ]; then
	# Copy qemu-arm-static to sysroot to install more packages
	cp /usr/bin/qemu-arm-static ${HEXAGON_ARM_SYSROOT}/usr/bin/qemu-arm-static

	pushd .
	cd downloads
	# Get ARM libc to use with qemu-arm-static
	if [ ! -f fakechroot_2.17.2-1_all.deb ]; then 
		wget http://launchpadlibrarian.net/172662762/libc6_2.19-0ubuntu6_armhf.deb
	fi

	# Get armhf libs to enable fakechroot to work under qemu
	if [ ! -f libfakeroot_1.20-3ubuntu2_armhf.deb ]; then 
		wget http://launchpadlibrarian.net/170520929/libfakeroot_1.20-3ubuntu2_armhf.deb
	fi
	if [ ! -f libfakechroot_2.17.1-2_armhf.deb ]; then 
		wget http://launchpadlibrarian.net/159987636/libfakechroot_2.17.1-2_armhf.deb
	fi
	popd 

	# The environment variable QEMU_LD_PREFIX must be set to point to the directory containing the armhf libc
	mkdir -p qemu-binfmt-arm
	if [ ! -f qemu-binfmt-arm/lib/ld-linux-armhf.so.3 ]; then
		dpkg -x downloads/libc6_2.19-0ubuntu6_armhf.deb qemu-binfmt-arm
	fi

	# Install armhf libs in sysroot to enable fakechroot to work under qemu
	if [ ! -f ${HEXAGON_ARM_SYSROOT}/usr/lib/arm-linux-gnueabihf/libfakeroot-sysv.so ]; then
		dpkg-deb --fsys-tarfile downloads/libfakeroot_1.20-3ubuntu2_armhf.deb | \
			tar -C ${HEXAGON_ARM_SYSROOT}/usr/lib/arm-linux-gnueabihf \
				--strip-components=5 -xf - ./usr/lib/arm-linux-gnueabihf/libfakeroot/libfakeroot-sysv.so
	fi
	if [ ! -f ${HEXAGON_ARM_SYSROOT}/usr/lib/arm-linux-gnueabihf/libfakechroot.so ]; then
		dpkg-deb --fsys-tarfile downloads/libfakechroot_2.17.1-2_armhf.deb | \
			tar -C ${HEXAGON_ARM_SYSROOT}/usr/lib/arm-linux-gnueabihf \
				--strip-components=5 -xf - ./usr/lib/arm-linux-gnueabihf/fakechroot/libfakechroot.so
	fi

	# Add extra packages to sysroot
	if [ ! -f ${HEXAGON_ARM_SYSROOT}/SYSROOT_CONFIGURED ]; then
		rm -f ${HEXAGON_ARM_SYSROOT}/etc/resolv.conf
		cp /etc/resolv.conf ${HEXAGON_ARM_SYSROOT}/etc/
		export QEMU_LD_PREFIX=`pwd`/qemu-binfmt-arm
		fakechroot chroot ${HEXAGON_ARM_SYSROOT} apt-get update
		fakechroot chroot ${HEXAGON_ARM_SYSROOT} apt-get install -y ${EXTRA_PACKAGES} && touch ${HEXAGON_ARM_SYSROOT}/SYSROOT_CONFIGURED
	fi
fi

echo Done
echo "--------------------------------------------------------------------"
echo "armhf cross compiler is at: ${HEXAGON_SDK_ROOT}/gcc-linaro-arm-linux-gnueabihf-4.8-2013.08_linux"
echo "armhf sysroot is at:        ${HEXAGON_SDK_ROOT}/sysroot"
echo
echo "Make sure to set the following environment variables:"
echo "   export HEXAGON_SDK_ROOT=${HEXAGON_SDK_ROOT}"
echo "   export HEXAGON_TOOLS_ROOT=${HEXAGON_TOOLS_ROOT}"
echo "   export HEXAGON_ARM_SYSROOT=${HEXAGON_ARM_SYSROOT}"
echo "   export PATH=\${HEXAGON_SDK_ROOT}/gcc-linaro-arm-linux-gnueabihf-4.8-2013.08_linux/bin:\$PATH"
echo
