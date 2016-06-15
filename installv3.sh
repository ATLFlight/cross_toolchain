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

# Installer script for Hexagon SDK 3.0 based environment

# This must be run from the local dir
cd `dirname $0`

TRIM=0
if [ "$1" = "-trim" ]; then
	TRIM=1
	shift
fi

trap fail_on_error ERR

function fail_on_error() {
	echo "Error: Script aborted";
	exit 1;
}

# If HEXAGON_SDK_ROOT is set, deduce what HOME should be
if [ ! "${HEXAGON_SDK_ROOT}" = "" ]; then
	echo "HEXAGON_SDK_ROOT currently set to: ${HEXAGON_SDK_ROOT}"
fi
if [[ ${HEXAGON_SDK_ROOT} = */Qualcomm/Hexagon_SDK/3.0 ]]; then
	HOME=`echo ${HEXAGON_SDK_ROOT} | sed -e "s#/Qualcomm/Hexagon_SDK/.*##"`
fi

read -r -p "${1:-HEXAGON_INSTALL_HOME [${HOME}]} " response
if [ ! "$response" = "" ]; then
	HOME=$response
fi

HEXAGON_SDK_ROOT=${HOME}/Qualcomm/Hexagon_SDK/3.0
HEXAGON_TOOLS_ROOT=${HOME}/Qualcomm/HEXAGON_Tools/7.2.12/Tools

echo "Using the following for installation:"
echo HEXAGON_SDK_ROOT=${HEXAGON_SDK_ROOT}
echo HEXAGON_TOOLS_ROOT=${HEXAGON_TOOLS_ROOT}

if [ ! -f ${HEXAGON_SDK_ROOT}/tools/qaic/Ubuntu14/qaic ]; then

	echo "Hexagon SDK not installed ${HEXAGON_SDK_ROOT}/tools/qaic/Ubuntu14/qaic"
	if [ -f downloads/qualcomm_hexagon_sdk_lnx_3_0_eval.bin ]; then
		echo
		echo "Installing HEXAGON_SDK to ${HEXAGON_SDK_ROOT}"
		echo "This will take a long time."
		sh ./downloads/qualcomm_hexagon_sdk_lnx_3_0_eval.bin -DDOWNLOAD_ECLIPSE=false -DDOWNLOAD_ANDROID=false -DDOWNLOAD_TOOLS=true -DUSER_INSTALL_DIR=${HEXAGON_SDK_ROOT} -i silent
	else
		echo
		echo "Put the file qualcomm_hexagon_sdk_lnx_3_0_eval.bin in the downloads directory"
		echo "and re-run this script."
		echo "If you do not have the file, you can download it from:"
		echo "    https://developer.qualcomm.com/download/hexagon/hexagon-sdk-v3-linux.bin"
		echo
	fi
fi

echo "Verifying required tools were installed..."
# Verify required tools were installed
if [ ! -f ${HEXAGON_SDK_ROOT}/tools/qaic/Ubuntu14/qaic ] || [ ! -f ${HEXAGON_SDK_ROOT}/tools/debug/mini-dm/Linux_Debug/mini-dm ]; then
	echo "Failed to install Hexagon SDK"
	exit 1
fi

echo "Running 'make' in ${HEXAGON_SDK_ROOT}/tools/qaic..."
# Set up the Hexagon SDK
if [ ! -f ${HEXAGON_SDK_ROOT}/tools/qaic/Linux/qaic ]; then
	pushd .
	cd ${HEXAGON_SDK_ROOT}/tools/qaic/
	make
	popd
fi

echo "Verifying setup is complete..."
# Verify setup is complete
if [ ! -f ${HEXAGON_SDK_ROOT}/tools/qaic/Linux/qaic ]; then
	echo "Failed to set up Hexagon SDK"
	exit 1
fi

if [[ ${HEXAGON_TOOLS_ROOT} = */7.2.12/Tools ]] ; then
	if [ ! -f ${HEXAGON_TOOLS_ROOT}/bin/hexagon-clang ]; then
		echo
		echo "The Hexagon Tools 7.2.12 version was not installed."
		echo "Re-install the Hexagon SDK and select the Hexagon Tools install option"
		echo "sh ./downloads/https://developer.qualcomm.com/download/hexagon/hexagon-sdk-v3-linux.bin -i swing"
		echo
		exit 1
	fi
else
	echo "***************************************************************************"
	echo "WARNING: Unsupported version of Hexagon Tools is being used"
	echo "***************************************************************************"
fi

# Fetch ARMv7hf cross compiler
if [ ! -f downloads/gcc-linaro-4.9-2014.11-x86_64_arm-linux-gnueabihf.tar.xz ]; then
	wget -P downloads https://releases.linaro.org/14.11/components/toolchain/binaries/arm-linux-gnueabihf/gcc-linaro-4.9-2014.11-x86_64_arm-linux-gnueabihf.tar.xz
fi

# Unpack armhf cross compiler
if [ ! -d ${HEXAGON_SDK_ROOT}/gcc-linaro-4.9-2014.11-x86_64_arm-linux-gnueabihf_linux ]; then
	echo "Unpacking cross compiler..."
	tar -C ${HEXAGON_SDK_ROOT} -xJf downloads/gcc-linaro-4.9-2014.11-x86_64_arm-linux-gnueabihf.tar.xz
	# The SDK added a _linux extension
	mv ${HEXAGON_SDK_ROOT}/gcc-linaro-4.9-2014.11-x86_64_arm-linux-gnueabihf ${HEXAGON_SDK_ROOT}/gcc-linaro-4.9-2014.11-x86_64_arm-linux-gnueabihf_linux
fi

if [ ! -f ${HEXAGON_SDK_ROOT}/libs/common/rpcmem/UbuntuARM_Debug/rpcmem.a ]; then
	pushd .
	cd ${HEXAGON_SDK_ROOT}/libs/common/rpcmem
	make V=UbuntuARM_Debug
	make V=UbuntuARM_Release
	popd
fi

# Reduce the size of the installed SDK to only the files needed for build
if [ "${TRIM}" = "1" ]; then
	
	if [ ! "${HEXAGON_SDK_ROOT}" = "" ]; then

		# Trim unused files from HEXAGON SDK
		rm -rf ${HEXAGON_SDK_ROOT}/build
		rm -rf ${HEXAGON_SDK_ROOT}/docs
		rm -rf ${HEXAGON_SDK_ROOT}/examples
		rm -rf ${HEXAGON_SDK_ROOT}/libs/camera_streaming
		find ${HEXAGON_SDK_ROOT} -name "*_toolv74" | xargs rm -rf
		find ${HEXAGON_SDK_ROOT} -name "*_toolv74_*" | xargs rm -rf
		rm -rf ${HEXAGON_SDK_ROOT}/tools/android-ndk-r10d
		rm -rf ${HEXAGON_SDK_ROOT}/tools/hexagon_ide
		rm -rf ${HEXAGON_SDK_ROOT}/tools/Installer_logs
		rm -rf ${HEXAGON_SDK_ROOT}/tools/qaic/Darwin
		rm -rf ${HEXAGON_SDK_ROOT}/tools/qaic/Linux_DoNotShip
		rm -rf ${HEXAGON_SDK_ROOT}/tools/qaic/Ubuntu10
		rm -rf ${HEXAGON_SDK_ROOT}/tools/qaic/Ubuntu12
		rm -rf ${HEXAGON_SDK_ROOT}/tools/utils

		strip ${HEXAGON_SDK_ROOT}/tools/debug/mini-dm/Linux_Debug/mini-dm
		strip ${HEXAGON_SDK_ROOT}/tools/qaic/Ubuntu14/qaic
	fi
	echo "HEXAGON_SDK_ROOT installation trimmed"

	if [ ! "${HEXAGON_TOOLS_ROOT}" = "" ]; then

		# Trim unused files from HEXAGON Tools
		rm -rf ${HEXAGON_TOOLS_ROOT}/../Documents
		rm -rf ${HEXAGON_TOOLS_ROOT}/../Examples
		rm -rf ${HEXAGON_TOOLS_ROOT}/../Uninstall_Qualcomm\ Hexagon\ LLVM_Tools
		rm -rf ${HEXAGON_TOOLS_ROOT}/java
		rm -f  ${HEXAGON_TOOLS_ROOT}/lib/liblldb.so*
		rm -f  ${HEXAGON_TOOLS_ROOT}/lib/liblldb.so.3.5.0
		rm -f  ${HEXAGON_TOOLS_ROOT}/lib/libpython2.7.so*
		rm -rf ${HEXAGON_TOOLS_ROOT}/lib/python2.7
		rm -rf ${HEXAGON_TOOLS_ROOT}/target/hexagon/lib/v60
		rm -rf ${HEXAGON_TOOLS_ROOT}/target/hexagon/lib/v60v1
		rm -rf ${HEXAGON_TOOLS_ROOT}/target/hexagon/lib/v61
		rm -rf ${HEXAGON_TOOLS_ROOT}/target/hexagon/lib/v61v1
		rm -rf ${HEXAGON_TOOLS_ROOT}/target/hexagon/lib/v60
		find ${HEXAGON_TOOLS_ROOT}/bin -type f -executable -exec sh -c 'test "$(file --brief "$1" | head -c 3)" = "ELF"' sh {} \; -print | xargs strip
	fi

	echo "HEXAGON_TOOLS_ROOT installation trimmed"
fi

echo Done
echo "--------------------------------------------------------------------"
echo "armhf cross compiler is at: ${HEXAGON_SDK_ROOT}/gcc-linaro-4.9-2014.11-x86_64_arm-linux-gnueabihf_linux"
echo
echo "Make sure to set the following environment variables:"
echo "   export HEXAGON_SDK_ROOT=${HEXAGON_SDK_ROOT}"
echo "   export HEXAGON_TOOLS_ROOT=${HEXAGON_TOOLS_ROOT}"
echo "   export PATH=\${HEXAGON_SDK_ROOT}/gcc-linaro-4.9-2014.11-x86_64_arm-linux-gnueabihf_linux/bin:\$PATH"
echo
