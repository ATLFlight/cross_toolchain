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

# Installer script for Ubuntu 14.04 ARMv7hf sysroot

# Extra packages to add to install to armhf sysroot
EXTRA_PACKAGES="libncurses5-dev"

# Install package deps
if [ ! -f /usr/bin/fakechroot ] || [ ! -f /usr/bin/qemu-arm-static ]; then
	if [ ! "${EXTRA_PACKAGES}" = "" ]; then
		echo "Please install fakechroot and qemu-system-arm"
		echo "sudo apt-get install fakechroot fakeroot qemu-user-static"
		exit 1
	fi
fi


if [ "${HEXAGON_ARM_SYSROOT}" = "" ]; then
	# If HEXAGON_SDK_ROOT is set, deduce what HOME should be
	echo ${HEXAGON_SDK_ROOT}
	if [[ ${HEXAGON_SDK_ROOT} = */Qualcomm/Hexagon_SDK/3.0 ]]; then
		HOME=`echo ${HEXAGON_SDK_ROOT} | sed -e "s#/Qualcomm/Hexagon_SDK/.*##"`
	else
		echo "HEXAGON_SDK_ROOT not valid"
		exit 1
	fi

	HEXAGON_ARM_SYSROOT=${HOME}/Qualcomm/ubuntu_14.04_armv7_sysroot
fi

read -r -p "${1:-HEXAGON_ARM_SYSROOT [${HEXAGON_ARM_SYSROOT}]} " response
if [ ! "$response" = "" ]; then
	HEXAGON_ARM_SYSROOT=$response
fi

# Unpack sysroot 
if [ ! -f ${HEXAGON_ARM_SYSROOT}/SYSROOT_UNPACKED ]; then
	mkdir -p ${HEXAGON_ARM_SYSROOT}
	echo "Unpacking sysroot..."
	tar -C ${HEXAGON_ARM_SYSROOT} --strip-components=1 --exclude="dev/*" -xzf downloads/linaro-trusty-developer-20140922-682.tar.gz && echo "${HEXAGON_ARM_SYSROOT}" > ${HEXAGON_ARM_SYSROOT}/SYSROOT_UNPACKED
fi

# fakechroot is used to install additional packages without using sudo
# It requires a little extra magic to make it work with misc-binfmt and qemu
if [ ! "${EXTRA_PACKAGES}" = "" ]; then

	# Linaro Trusty image contains qemu-arm-static so no need to copy over

	pushd .
	cd downloads
	# Get ARM libc to use with qemu-arm-static
	if [ ! -f libc6_2.19-0ubuntu6_armhf.deb ]; then 
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
		export QEMU_LD_PREFIX=${HEXAGON_ARM_SYSROOT}
		if [ ! -f ${HEXAGON_ARM_SYSROOT}/UPDATED ]; then
			fakechroot chroot ${HEXAGON_ARM_SYSROOT} apt-get update && touch ${HEXAGON_ARM_SYSROOT}/UPDATED
		fi

		# fakeroot is broken on Ubuntu 12.04
		if [ "`lsb_release -r | grep 12.04`" = "" ]; then
			fakechroot fakeroot chroot ${HEXAGON_ARM_SYSROOT} apt-get install -y ${EXTRA_PACKAGES} && touch ${HEXAGON_ARM_SYSROOT}/SYSROOT_CONFIGURED
		else
			sudo chroot ${HEXAGON_ARM_SYSROOT} apt-get install -y ${EXTRA_PACKAGES} && touch ${HEXAGON_ARM_SYSROOT}/SYSROOT_CONFIGURED
		fi
	fi
fi

echo Done
echo "--------------------------------------------------------------------"
echo "armv7hf sysroot is at:        ${HEXAGON_ARM_SYSROOT}"
echo
echo "Make sure to set the following environment variables:"
echo "   export HEXAGON_ARM_SYSROOT=${HEXAGON_ARM_SYSROOT}"
echo
