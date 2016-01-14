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
all: COMPILER_INSTALLED SYSROOT_CONFIGURED

fetch: gcc-linaro-arm-linux-gnueabihf-4.8-2013.08_linux.tar.xz ubuntu-core-14.04-core-armhf.tar.gz

.PHONY check_env:
	@[ ! "${HEXAGON_SDK_ROOT}" = "" ] || (echo "Must set HEXAGON_SDK_ROOT" && false)
	
gcc-linaro-arm-linux-gnueabihf-4.8-2013.08_linux.tar.xz:
	@wget https://launchpad.net/linaro-toolchain-binaries/trunk/2013.08/+download/gcc-linaro-arm-linux-gnueabihf-4.8-2013.08_linux.tar.xz
	
ubuntu-core-14.04-core-armhf.tar.gz:
	@wget http://cdimage.ubuntu.com/ubuntu-core/releases/14.04.3/release/ubuntu-core-14.04-core-armhf.tar.gz

/usr/bin/qemu-arm-static:
	echo "Install of qemu-user-static requires sudo"
	sudo apt-get install -y qemu-user-static

COMPILER_INSTALLED: check_env gcc-linaro-arm-linux-gnueabihf-4.8-2013.08_linux.tar.xz
	tar -C ${HEXAGON_SDK_ROOT} -xJf gcc-linaro-arm-linux-gnueabihf-4.8-2013.08_linux.tar.xz
	touch $@

SYSROOT_UNPACKED: check_env ubuntu-core-14.04-core-armhf.tar.gz
	@mkdir -p ${HEXAGON_SDK_ROOT}/sysroot
	@tar -C ${HEXAGON_SDK_ROOT}/sysroot --exclude="dev/*" -xzf ubuntu-core-14.04-core-armhf.tar.gz
	touch $@
	
${HEXAGON_SDK_ROOT}/sysroot/setup.sh: check_env SYSROOT_UNPACKED
	@cp setup.sh $@

${HEXAGON_SDK_ROOT}/sysroot/usr/bin/qemu-arm-static: check_env SYSROOT_UNPACKED
	@cp /usr/bin/qemu-arm-static $@

SYSROOT_CONFIGURED: check_env ${HEXAGON_SDK_ROOT}/sysroot/usr/bin/qemu-arm-static ${HEXAGON_SDK_ROOT}/sysroot/setup.sh
	sudo mount -o bind /dev ${HEXAGON_SDK_ROOT}/sysroot/dev
	sudo mount -t sysfs /sys ${HEXAGON_SDK_ROOT}/sysroot/sys
	sudo mount -t proc /proc ${HEXAGON_SDK_ROOT}/sysroot/proc
	sudo cp /proc/mounts ${HEXAGON_SDK_ROOT}/sysroot/etc/mtab
	sudo chroot ${HEXAGON_SDK_ROOT}/sysroot /setup.sh
	sudo umount ${HEXAGON_SDK_ROOT}/sysroot/sys
	sudo umount ${HEXAGON_SDK_ROOT}/sysroot/proc
	sudo umount ${HEXAGON_SDK_ROOT}/sysroot/dev
	touch $@
