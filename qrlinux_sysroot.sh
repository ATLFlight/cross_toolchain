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
	pwd
	ls
	echo "Please put the ${QRLSDKTGZ} file from the following link into the downloads"
	echo "directory and re-run this script:"
	echo "   http://support.intrinsyc.com/attachments/download/1011/${QRLSDKTGZ}"
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

	HEXAGON_ARM_SYSROOT=${HOME}/Qualcomm/qrlinux_v4_sysroot
fi

if [[ ${HEXAGON_ARM_SYSROOT} = */Qualcomm/qrlinux_v4_sysroot ]]; then
	echo "Installing QRLinux sysroot"
else
	echo "Invalid install path for HEXAGON_ARM_SYSROOT"
	echo "Path must end in .../Qualcomm/qrlinux_v4_sysroot"
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
		mkdir -p downloads/qrlSDK
		pushd downloads/qrlSDK
		tar xzf ../${QRLSDKTGZ}
		popd
	fi
	if [ ! -f downloads/qrlSDK/qrlSysroots.tgz ]; then
		echo "QRLinux SDK unpack failed"
		exit 1
	fi

	echo "Extracting sysroot from qrlSDK"
	if [ ! -d downloads/qrlSDK/sysroots/eagle8074/linaro-rootfs ]; then
		tar -C downloads/qrlSDK -xzf downloads/qrlSDK/qrlSysroots.tgz sysroots/eagle8074
	fi
	mkdir -p ${HEXAGON_ARM_SYSROOT}
	echo "copying to ${HEXAGON_ARM_SYSROOT}"
	cp -arp downloads/qrlSDK/sysroots/eagle8074/* ${HEXAGON_ARM_SYSROOT}
	mkdir -p ${HEXAGON_ARM_SYSROOT}/var/opt
	echo "${HEXAGON_ARM_SYSROOT}" > ${HEXAGON_ARM_SYSROOT}/var/opt/SYSROOT_UNPACKED
fi

# Reduce the size of the installed sysroot to only the files needed for build
# Note: THIS IS STILL EXPERIMENTAL

# Remove runtime files that are not required for building applications
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/usr/share/sounds
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/usr/share/consolefonts
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/usr/share/file
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/usr/share/oprofile
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/usr/share/zoneinfo
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/usr/share/perl5
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/usr/share/mime
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/usr/share/X11
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/usr/share/terminfo
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/usr/share/i18n
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/usr/share/locale
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/usr/share/man
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/usr/share/doc
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/usr/share/perl
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/usr/share/vim
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/usr/share
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/usr/bin/
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/usr/sbin/
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/lib/udev
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/usr/lib/gcc
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/var
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/bin
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/sbin
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/dev
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/home
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/md5sum.txt
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/etc
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/boot
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/media
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/opt
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/mnt
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/root
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/run
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/sys
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/srv
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/tmp
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/usr/local
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/usr/games
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/usr/src
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/lib/modules
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/lib/firmware
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/lib/systemd
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/lib/terminfo
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/lib/arm-linux-gnueabihf/security
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/lib/arm-linux-gnueabihf/plymouth
rm -rf   ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/lost+found
rm -rf   ${HEXAGON_ARM_SYSROOT}/etc
rm -rf   ${HEXAGON_ARM_SYSROOT}/bin
rm -rf   ${HEXAGON_ARM_SYSROOT}/sbin
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/bin
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/sbin
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/src
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/share
rm -rf   ${HEXAGON_ARM_SYSROOT}/lib/modules
rm -rf   ${HEXAGON_ARM_SYSROOT}/lib/firmware
rm -rf   ${HEXAGON_ARM_SYSROOT}/lib/ssl
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/include/linux
rm -rf   ${HEXAGON_ARM_SYSROOT}/pkgdata
rm -rf   ${HEXAGON_ARM_SYSROOT}/sysroot-providers
rm -rf   ${HEXAGON_ARM_SYSROOT}/filesystem_config.txt

# The Ubuntu libc is used for SDK based development
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/include/eglibc-locale-internal-cortexa8hf-vfp-neon-linux-gnueabi
rm -rf   ${HEXAGON_ARM_SYSROOT}/lib

# Use the Ubuntu versions of perl, python2.7 and ssl
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/python2.7
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/libpython2.7.so*
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/libperl.so*
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/perl
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/libssl.*
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/pkgconfig/libssl.pc
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/ssl

# Remove other duplicate libs
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/libm.*
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/libm_pic.*
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/libpthread*
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/libsqlite3*
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/libanl.*
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/libanl_pic.*
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/libBrokenLocale*
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/libcidn.so
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/libcrypt.*
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/libcrypt_pic.*
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/libc.*
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/libc_nonshared.a
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/libc_pic.*
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/libdb-5.3.so
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/libdl.*
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/libdl_pic.*
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/libnsl.*
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/libnsl_pic.*
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/libnss_compat.*
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/libnss_compat_pic.*
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/libnss_dns.*
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/libnss_dns_pic.*
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/libnss_files.*
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/libnss_files_pic.*
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/libnss_hesiod.*
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/libnss_hesiod_pic.*
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/libnss_nisplus.*
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/libnss_nisplus_pic.*
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/libnss_nis.*
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/libnss_nis_pic.*
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/libresolv.*
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/libresolv_pic.*
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/librt.*
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/librt_pic.*
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/libthread_db.*
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/libthread_db_pic.*
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/libutil.*
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/libutil_pic.*
rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/lib/*crt*.o

# merge the files
rsync --recursive -l --ignore-existing -v ${HEXAGON_ARM_SYSROOT}/usr/lib ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/usr
rsync --recursive -l --ignore-existing -v ${HEXAGON_ARM_SYSROOT}/usr/include ${HEXAGON_ARM_SYSROOT}/linaro-rootfs/usr

rm -rf ${HEXAGON_ARM_SYSROOT}/usr
rm -rf ${HEXAGON_ARM_SYSROOT}/var

echo Done
echo "--------------------------------------------------------------------"
echo "armv7hf sysroot is at:	${HEXAGON_ARM_SYSROOT}/linaro-rootfs"
echo
echo "Make sure to set the following environment variables:"
echo "   export HEXAGON_ARM_SYSROOT=${HEXAGON_ARM_SYSROOT}/linaro-rootfs"
echo
