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

# Installer script for Hexagon SDK 3.1 based environment
#

GCC_2014=gcc-linaro-4.9-2014.11-x86_64_arm-linux-gnueabihf
GCC_2014_SHORT=gcc-4.9-2014.11
GCC_2014_URL=https://releases.linaro.org/archive/14.11/components/toolchain/binaries/arm-linux-gnueabihf

INSTALLER30_BIN=qualcomm_hexagon_sdk_lnx_3_0_eval.bin
INSTALLER31_BIN=qualcomm_hexagon_sdk_3_1_eval.bin

# This must be run from the local dir
cd `dirname $0`

usage() {
	echo
	echo "Usage: `basename $0` [-h --help] [--APQ8074 --qrlSDK] [--APQ8096] [--no-verify --trim --tgz --arm-gcc] [INSTALL_DIR]"
	echo
	echo "Supported Options:"
	echo "     --help, -h       Show this help"
	echo "     --APQ8074        Installs SDK 3.0 with Hexagon v55 support for aDSP on APQ8074"
	echo "     --APQ8096        Installs SDK 3.1 with Hexagon v60 support for SLPI on APQ8096"
	echo "     --qrlSDK         Install the qrlSDK (only supported for --APQ8074)"
	echo "     --no-verify      Use for scripted installs"
	echo "     --trim           Removed unneeded parts of SDK(s) and strip files"
	echo "     --tgz            Create  gzipped tarball(s) of the installed SDK(s)"
	echo "     --arm-gcc        Install the Linaro 4.9 ARMv7hf cross compiler in SDK(s)"
	echo
	echo "If --arm-gcc is omitted, then the Linaro ARM compiler is removed."
	echo "If --qrlSDK is omitted, then the qrlSDK is removed if the specified target is --APQ8074."
	echo
	echo "INSTALL_DIR is the optional base path for installation. The default is \${HOME}."
	echo
	exit 1
}

trap fail_on_error ERR

function fail_on_error() {
	echo "Error: Script aborted";
	exit 1;
}

OPTS=`getopt -n 'parse-options' -o h --long APQ8074,APQ8096,help,no-verify,trim,tgz,arm-gcc,qrlSDK -- "$@"`

eval set -- "$OPTS"

APQ8074=0
APQ8096=0
VERIFY=1
TRIM=0
DOTGZ=0
KEEPGCC=0
HELP=0
QRLSDK=0

while true; do
  case "$1" in
    -h | --help ) HELP=1; shift ;;
    --APQ8074 )   APQ8074=1; shift ;;
    --APQ8096 )   APQ8096=1; shift ;;
    --no-verify ) VERIFY=0; shift ;;
    --trim )      TRIM=1; shift ;;
    --tgz )       DOTGZ=1; shift ;;
    --arm-gcc )   KEEPGCC=1; shift ;;
    --qrlSDK )    QRLSDK=1; shift ;;
    * ) break ;;
  esac
done

shift
echo "$1"

if [ ${HELP}  = 1 ]; then
	usage
fi

if [ ${APQ8074} = 0 ] && [ ${APQ8096} = 0 ]; then
	echo "Error: Must select one or both of --APQ8074 --APQ8096"
	usage
fi

if [ ${APQ8074} = 0 ] && [ ${QRLSDK} = 1 ]; then
	echo "Error: qrlSDK is only supported for --APQ8074"
	usage
fi

SDK_VER="UNSET"
TARGET="UNSET"

remove_qrlsdk() {
	if [ -d ${HEXAGON_ARM_SYSROOT} ]; then
		echo "Removing previous QRLinux sysroot installation"
		rm -rf ${HEXAGON_ARM_SYSROOT}
	fi
}

install_qrlsdk() {
	QRLSDK=Flight_3.1.3_qrlSDK
	QRLSDKTGZ=${QRLSDK}.tgz

	# Verify the ${QRLSDKTGZ} file was downloaded from Intrinsyc
	if [ ! -f downloads/${QRLSDKTGZ} ]; then
		echo
		echo "Error: Missing ${QRLSDKTGZ}"
		echo "Please put the ${QRLSDKTGZ} file from the following link into the ./downloads"
		echo "directory and re-run this script:"
		echo "   https://support.intrinsyc.com/attachments/download/1515/${QRLSDKTGZ}"
		exit 1
	fi

	QRLSDKMD5SUM=`md5sum -b downloads/$QRLSDKTGZ | cut -d' ' -f1`

	if [ ! ${QRLSDKMD5SUM} = 11f9b91ea2f3b0540a6d64756728d240 ]; then
		echo "Please make sure you have the latest version of this installer script and"
		echo "re-download the ${QRLSDKTGZ} file from the following link into the ./downloads"
		echo "directory and re-run this script:"
		echo "   http://support.intrinsyc.com/attachments/download/1515/${QRLSDKTGZ}"
		exit 1
	fi

	# Unpack sysroot
	if [ ! -f ${HEXAGON_ARM_SYSROOT}/QRLSDKMD5SUM ] || \
		([ -f ${HEXAGON_ARM_SYSROOT}/QRLSDKMD5SUM ] && 
		 [ ! ${QRLSDKMD5SUM} = `cat ${HEXAGON_ARM_SYSROOT}/QRLSDKMD5SUM` ]); then
		remove_qrlsdk

		mkdir -p ${HEXAGON_ARM_SYSROOT}

		# Clean out old SDK installations
		if [ ! -f downloads/qrlSDK/sysroots/eagle8074/QRLSDKMD5SUM ] || \
			([ -f downloads/qrlSDK/sysroots/eagle8074/QRLSDKMD5SUM ] && 
			[ ! ${QRLSDKMD5SUM} = `cat downloads/qrlSDK/sysroots/eagle8074/QRLSDKMD5SUM` ]); then
			rm -rf downloads/qrlSDK
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

		if [ ! -d downloads/qrlSDK/sysroots/eagle8074/QRLSDKMD5SUM ]; then
			echo "Extracting sysroot from qrlSDK"
			tar -C downloads/qrlSDK -xzf downloads/qrlSDK/qrlSysroots.tgz sysroots/eagle8074
			echo ${QRLSDKMD5SUM} > downloads/qrlSDK/sysroots/eagle8074/QRLSDKMD5SUM
		fi
		mkdir -p ${HEXAGON_ARM_SYSROOT}
		echo "Copying to ${HEXAGON_ARM_SYSROOT}"
		cp -arp downloads/qrlSDK/sysroots/eagle8074/* ${HEXAGON_ARM_SYSROOT}

		# Remove runtime files that are not required for building applications
		rm -rf   ${HEXAGON_ARM_SYSROOT}/usr/include/eglibc-locale-internal-cortexa8hf-vfp-neon-linux-gnueabi
	fi
}

trim_sdk() {
	# Trim unused files from HEXAGON SDK
	rm -rf ${HEXAGON_SDK_ROOT}/build
	rm -rf ${HEXAGON_SDK_ROOT}/docs
	rm -rf ${HEXAGON_SDK_ROOT}/examples
	rm -rf ${HEXAGON_SDK_ROOT}/libs/camera_streaming
	rm -rf ${HEXAGON_SDK_ROOT}/tools/android-ndk-r10d
	rm -rf ${HEXAGON_SDK_ROOT}/tools/hexagon_ide
	rm -rf ${HEXAGON_SDK_ROOT}/tools/Installer_logs
	rm -rf ${HEXAGON_SDK_ROOT}/tools/qaic/Darwin
	rm -rf ${HEXAGON_SDK_ROOT}/tools/qaic/Linux_DoNotShip
	rm -rf ${HEXAGON_SDK_ROOT}/tools/qaic/Ubuntu10
	rm -rf ${HEXAGON_SDK_ROOT}/tools/qaic/Ubuntu12
	rm -rf ${HEXAGON_SDK_ROOT}/tools/qaic/Ubuntu14
	rm -rf ${HEXAGON_SDK_ROOT}/tools/qaic/Makefile
	rm -rf ${HEXAGON_SDK_ROOT}/tools/utils
	rm -rf ${HEXAGON_SDK_ROOT}/tools/elfsigner
	rm -rf ${HEXAGON_SDK_ROOT}/scripts
	rm -rf ${HEXAGON_SDK_ROOT}/test
	rm -rf ${HEXAGON_SDK_ROOT}/libs/fastcv
	rm -rf ${HEXAGON_SDK_ROOT}/libs/common/power_ctl
	rm -rf ${HEXAGON_SDK_ROOT}/libs/common/FFTsfc
	rm -rf ${HEXAGON_SDK_ROOT}/libs/common/FFTsfr
	rm -rf ${HEXAGON_SDK_ROOT}/setup_sdk_env.sh
	rm -rf ${HEXAGON_SDK_ROOT}/readme.txt
	rm -rf ${HEXAGON_SDK_ROOT}/Uninstall_Hexagon_SDK
	rm -rf ${HEXAGON_SDK_ROOT}/Launch\ Hexagon\ IDE
	rm -rf ${HEXAGON_SDK_ROOT}/setup_sdk_env.source
	rm -rf ${HEXAGON_SDK_ROOT}/libs/common/atomic/glue
	rm -rf ${HEXAGON_SDK_ROOT}/libs/common/atomic/Makefile
	rm -rf ${HEXAGON_SDK_ROOT}/libs/common/atomic/*.min
	rm -rf ${HEXAGON_SDK_ROOT}/libs/common/rpcmem/glue
	rm -rf ${HEXAGON_SDK_ROOT}/libs/common/rpcmem/Makefile
	rm -rf ${HEXAGON_SDK_ROOT}/libs/common/rpcmem/*.min

	find ${HEXAGON_SDK_ROOT} -name "android*" | xargs rm -rf

	if [ ${TARGET} = "APQ8074" ]; then
		# We only need ADSPv55MP for APQ8074 aDSP
		rm -rf ${HEXAGON_SDK_ROOT}/libs/common/qurt/ADSPv4MP
		rm -rf ${HEXAGON_SDK_ROOT}/libs/common/qurt/ADSPv56MP
		rm -rf ${HEXAGON_SDK_ROOT}/libs/common/qurt/ADSPv5MP
		rm -rf ${HEXAGON_SDK_ROOT}/libs/common/qurt/ADSPv60MP
		rm -rf ${HEXAGON_SDK_ROOT}/libs/common/qurt/ADSPv62MP
		rm -f ${HEXAGON_SDK_ROOT}/libs/common/qurt/qurt_libs.min
		find ${HEXAGON_SDK_ROOT} -name "*_toolv74" | xargs rm -rf
		find ${HEXAGON_SDK_ROOT} -name "*_toolv74_*" | xargs rm -rf
		find ${HEXAGON_SDK_ROOT} -name "*_toolv72_v60*" | xargs rm -rf
	elif [ ${TARGET} = "APQ8096" ]; then
		# We only need ADSPv60* for APQ8096 SLPI
		rm -rf ${HEXAGON_SDK_ROOT}/libs/common/qurt/ADSPv62MP
		rm -rf ${HEXAGON_SDK_ROOT}/libs/common/qurt/ADSPv62MPCPP
		rm -f ${HEXAGON_SDK_ROOT}/libs/common/qurt/qurt_libs.min
		find ${HEXAGON_SDK_ROOT} -name "*_toolv74*" | xargs rm -rf
		find ${HEXAGON_SDK_ROOT} -name "*_toolv72*" | xargs rm -rf
	fi

	rm -rf ${ARM_CROSS_GCC_ROOT}/share/info
	rm -rf ${ARM_CROSS_GCC_ROOT}/share/man
	rm -rf ${ARM_CROSS_GCC_ROOT}/share/doc
}

process_options() {
	# Reduce the size of the installed SDK to only the files needed for build
	if [ "${TRIM}" = "1" ]; then
		get_arm_compiler
		trim
	fi

	if [ ${KEEPGCC} = 0 ]; then
		if [ ! -d ${ARM_CROSS_GCC_ROOT} ]; then
			rm -rf ${ARM_CROSS_GCC_ROOT}
		fi
	else
		get_arm_compiler
	fi

	if [ ${DOTGZ} = 1 ]; then
		tar -C ${HEXAGON_SDK_ROOT}/../../../ -czf Hexagon_SDK_${SDK_VER}.tgz ./Qualcomm
	fi
}

install_sdk() {
	echo "Using the following for installation:"
	echo HEXAGON_SDK_ROOT=${HEXAGON_SDK_ROOT}
	echo HEXAGON_TOOLS_ROOT=${HEXAGON_TOOLS_ROOT}

	if [ ! -f ${HEXAGON_SDK_ROOT}/tools/qaic/Linux/qaic ]; then

		echo "Hexagon SDK not previously installed"
		if [ ${SDK_VER} = "3.0" ]; then
			BINFILE=${INSTALLER30_BIN}
			INSTALL_FLAGS="-DDOWNLOAD_ECLIPSE=false -DDOWNLOAD_ANDROID=false -DDOWNLOAD_TOOLS=true -DUSER_INSTALL_DIR=${HEXAGON_SDK_ROOT} -i silent"
		elif [ ${SDK_VER} = "3.1" ]; then
			BINFILE=${INSTALLER31_BIN}
			INSTALL_FLAGS="-DDOWNLOAD_ECLIPSE=false -DUSER_INSTALL_DIR=${HEXAGON_SDK_ROOT} -i silent"
		fi

		if [ -f downloads/${BINFILE} ]; then
			echo
			echo "Installing HEXAGON_SDK to ${HEXAGON_SDK_ROOT}"
			echo "This will take a long time."
			sh ./downloads/${BINFILE} ${INSTALL_FLAGS}
		else
			echo
			echo "Put the file ${BINFILE} in the downloads directory"
			echo "and re-run this script."
			echo "If you do not have the file, you can download it from:"
			echo "    https://developer.qualcomm.com/download/hexagon/${BINFILE}"
			echo
		fi
	fi

	# Set up the Hexagon SDK
	if [ ! -f ${HEXAGON_SDK_ROOT}/tools/qaic/Linux/qaic ] && [ -f ${HEXAGON_SDK_ROOT}/tools/qaic/Makefile ]; then
		echo "Running 'make' in ${HEXAGON_SDK_ROOT}/tools/qaic..."
		pushd .
		cd ${HEXAGON_SDK_ROOT}/tools/qaic/
		make
		popd
	fi

	echo "Verifying required tools were installed..."
	# Verify required tools were installed
	if [ ! -f ${HEXAGON_SDK_ROOT}/tools/qaic/Linux/qaic ] || [ ! -f ${HEXAGON_SDK_ROOT}/tools/debug/mini-dm/Linux_Debug/mini-dm ]; then
		echo "Failed to setup Hexagon SDK"
		exit 1
	fi

	if [ ${SDK_VER} = "3.1" ]; then
		TOOLS_VER=8.0.08
	elif [ ${SDK_VER} = "3.0" ]; then
		TOOLS_VER=7.2.12
	fi
	if [[ ${HEXAGON_TOOLS_ROOT} = */${TOOLS_VER}/Tools ]] ; then
		if [ ! -f ${HEXAGON_TOOLS_ROOT}/bin/hexagon-clang ]; then
			echo
			echo "The Hexagon Tools ${TOOLS_VER} version was not installed."
			echo "Re-install Hexagon SDK ${SDK_VER}"
			echo
			exit 1
		fi
	else
		echo "***************************************************************************"
		echo "WARNING: Unsupported version of Hexagon Tools is being used ${HEXAGON_TOOLS_ROOT} ${SDK_VER}"
		echo "***************************************************************************"
	fi
}

get_arm_compiler() {
	# Fetch ARMv7hf cross compiler
	if [ ! -f downloads/${GCC_2014}.tar.xz ]; then
		wget -P downloads ${GCC_2014_URL}/${GCC_2014}.tar.xz
	fi

	# Unpack armhf cross compiler
	if [ ! -d ${ARM_CROSS_GCC_ROOT} ]; then
		echo "Unpacking cross compiler..."
		mkdir -p ${HOME}/Qualcomm/ARM_Tools
		tar -C ${HOME}/Qualcomm/ARM_Tools -xJf downloads/${GCC_2014}.tar.xz
		mv ${HOME}/Qualcomm/ARM_Tools/${GCC_2014} ${ARM_CROSS_GCC_ROOT}
	fi
}

elf_strip () {
	find $1 -type f -executable -print > tmp_elf_strip_list
	for f in `cat tmp_elf_strip_list`; do
		info=`file --brief $f`
		if [ "`echo \"$info\" | head -c 3`" == "ELF" ]; then
			if [ ! "`echo \"$info\" | tail -c 10`" == " stripped" ]; then
				echo "$info" | grep -q DSP6 && ${HEXAGON_TOOLS_ROOT}/bin/hexagon-strip --strip-unneeded $f
				echo "$info" | grep -q ARM && ${ARM_CROSS_GCC_ROOT}/bin/arm-linux-gnueabihf-strip --strip-unneeded $f
				echo "$info" | grep -q x86-64 && strip --strip-unneeded $f
			fi
		fi
	done
	rm -f tmp_elf_strip_list
}

archive_strip () {
	find $1 -name "*.a" -print > tmp_archive_strip_list
	for f in `cat tmp_archive_strip_list`; do

		# adsp_info.a contains other archive files and messes up readelf -h
		if `echo $f | grep -v -q /adsp_info.a`; then
			info=`readelf -h $f | grep Machine | uniq`

			# hexagon-strip doesn't handle archives
			#echo "$info" | grep DSP6 && ${HEXAGON_TOOLS_ROOT}/bin/hexagon-strip --strip-unneeded $f
			
			echo "$info" | grep -q ARM && ${ARM_CROSS_GCC_ROOT}/bin/arm-linux-gnueabihf-strip --strip-unneeded $f
			echo "$info" | grep -q X86-64 && strip --strip-unneeded $f
		fi
	done
	rm -f tmp_archive_strip_list
}

trim_tools() {
	# Trim unused files from HEXAGON Tools
	rm -rf ${HEXAGON_TOOLS_ROOT}/../Documents
	rm -rf ${HEXAGON_TOOLS_ROOT}/../Examples
	rm -rf ${HEXAGON_TOOLS_ROOT}/../Uninstall_Qualcomm\ Hexagon\ LLVM_Tools
	rm -rf ${HEXAGON_TOOLS_ROOT}/java
	rm -f  ${HEXAGON_TOOLS_ROOT}/lib/liblldb.so*
	rm -f  ${HEXAGON_TOOLS_ROOT}/lib/liblldb.so.3.5.0
	rm -f  ${HEXAGON_TOOLS_ROOT}/lib/libpython2.7.so*
	rm -rf ${HEXAGON_TOOLS_ROOT}/lib/python2.7
	if [ ${SDK_VER} = "3.0" ]; then
		rm -rf ${HEXAGON_TOOLS_ROOT}/target/hexagon/lib/v60v1
		rm -rf ${HEXAGON_TOOLS_ROOT}/target/hexagon/lib/v56
		rm -rf ${HEXAGON_TOOLS_ROOT}/target/hexagon/lib/v5

		# DO NOT REMOVE v60 (it is the default) in SDK 3.0
		#rm -rf ${HEXAGON_TOOLS_ROOT}/target/hexagon/lib/v60
	fi
	if [ ${SDK_VER} = "3.1" ]; then
		rm -rf ${HEXAGON_TOOLS_ROOT}/target/hexagon/lib/v61
		rm -rf ${HEXAGON_TOOLS_ROOT}/target/hexagon/lib/v61v1
		rm -rf ${HEXAGON_TOOLS_ROOT}/target/hexagon/lib/v62
	fi
}

trim() {
	echo "Trimming HEXAGON_SDK_ROOT ..."
	if [ ! "${HEXAGON_SDK_ROOT}" = "" ]; then
		trim_sdk
	fi

	echo "Trimming HEXAGON_TOOLS_ROOT ..."
	if [ ! "${HEXAGON_TOOLS_ROOT}" = "" ]; then
		trim_tools
	fi

	# Strip the binaries, libs and archives
	elf_strip ${HOME}/Qualcomm
	archive_strip ${HOME}/Qualcomm
}

show_env_setup() {
	echo
	echo "--------------------------------------------------------------------"
	echo " ${TARGET} Development"
	echo "--------------------------------------------------------------------"
	if [ ${KEEPGCC} = 1 ]; then
		echo "armhf cross compiler is at: ${ARM_CROSS_GCC_ROOT}/bin"
		echo
	fi
	echo "Make sure to set the following environment variables:"
	echo "   export HEXAGON_SDK_ROOT=${HEXAGON_SDK_ROOT}"
	echo "   export HEXAGON_TOOLS_ROOT=${HEXAGON_TOOLS_ROOT}"
	if [ ${APQ8074} = 1 ]; then
		BASE=`echo ${HEXAGON_SDK_ROOT} | sed -e "s#/Qualcomm/Hexagon_SDK/.*##"`
		HEXAGON_ARM_SYSROOT=${BASE}/Qualcomm/qrlinux_sysroot
		if [ -d ${HEXAGON_ARM_SYSROOT} ]; then
			echo "   export HEXAGON_ARM_SYSROOT=${BASE}/Qualcomm/qrlinux_sysroot"
		else
			echo "Warning: qrlSDK is not installed. Set HEXAGON_ARM_SYSROOT to the location of the sysroot."
		fi
	fi
	if [ ${KEEPGCC} = 1 ]; then
		echo "   export ARM_CROSS_GCC_ROOT=${ARM_CROSS_GCC_ROOT}"
	fi
	echo
}

# If HEXAGON_SDK_ROOT is set, deduce what HOME should be
if [ ! "${HEXAGON_SDK_ROOT}" = "" ]; then
	echo "HEXAGON_SDK_ROOT currently set to: ${HEXAGON_SDK_ROOT}"
fi

if [[ ${HEXAGON_SDK_ROOT} = */Qualcomm/Hexagon_SDK/* ]]; then
	HOME=`echo ${HEXAGON_SDK_ROOT} | sed -e "s#/Qualcomm/Hexagon_SDK/.*##"`
fi

if [ ! "$1" = "" ]; then
	HOME=$1
fi

# We can't use read inside docker.
if [ ! -f /.dockerenv ] && [ ${VERIFY} = 1 ]; then
    read -r -p "HEXAGON_INSTALL_HOME [${HOME}] " response
    if [ ! "$response" = "" ]; then
	HOME=$response
    fi
fi

# The HEXAGON_Tools 7.2.12 get installed to ${HOME}/Qualcomm no matter what, so override ${HOME}
export HOME=${HOME}
ARM_CROSS_GCC_ROOT=${HOME}/Qualcomm/ARM_Tools/${GCC_2014_SHORT}

# Install Hexagon SDK 3.0 for APQ8074
if [ ${APQ8074} = 1 ]; then

	HEXAGON_SDK_ROOT=${HOME}/Qualcomm/Hexagon_SDK/3.0
	HEXAGON_TOOLS_ROOT=${HOME}/Qualcomm/HEXAGON_Tools/7.2.12/Tools
	BASE=`echo ${HEXAGON_SDK_ROOT} | sed -e "s#/Qualcomm/Hexagon_SDK/.*##"`
	HEXAGON_ARM_SYSROOT=${BASE}/Qualcomm/qrlinux_sysroot
	SDK_VER=3.0
	TARGET=APQ8074

	install_sdk

	if [ ${QRLSDK} = 1 ]; then
		install_qrlsdk
	else
		remove_qrlsdk
	fi

	process_options
fi

# Install Hexagon SDK 3.1 for APQ8096
if [ ${APQ8096} = 1 ]; then
	HEXAGON_SDK_ROOT=${HOME}/Qualcomm/Hexagon_SDK/3.1
	HEXAGON_TOOLS_ROOT=${HOME}/Qualcomm/Hexagon_SDK/3.1/tools/HEXAGON_Tools/8.0.08/Tools
	SDK_VER=3.1
	TARGET=APQ8096

	install_sdk
	process_options
fi

if [ ${APQ8074} = 1 ]; then
	TARGET=APQ8074
	HEXAGON_SDK_ROOT=${HOME}/Qualcomm/Hexagon_SDK/3.0
	HEXAGON_TOOLS_ROOT=${HOME}/Qualcomm/HEXAGON_Tools/7.2.12/Tools
	show_env_setup APQ8074
fi
if [ ${APQ8096} = 1 ]; then
	HEXAGON_SDK_ROOT=${HOME}/Qualcomm/Hexagon_SDK/3.1
	HEXAGON_TOOLS_ROOT=${HOME}/Qualcomm/Hexagon_SDK/3.1/tools/HEXAGON_Tools/8.0.08/Tools
	TARGET=APQ8096
	show_env_setup
fi

