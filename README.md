# cross_toolchain

This project will install the Hexagon SDK 3.0, ARMv7hf cross compiler, ARMv7hf cross compiler, and ARMv7hf Ubuntu Trusty (14.04) sysroot
for Snapdragon Flight application development.

## SDK Installation

Clone and build this project:
```
git clone https://github.com/ATLFlight/cross_toolchain.git
cd cross_toolchain
./installv3.sh
```

This will install:

Hexagon SDK [HEXAGON_SDK_ROOT]: ${HOME}/Qualcomm/Hexagon_SDK/3.0

Hexagon Tools [HEXAGON_TOOLS_ROOT]: ${HOME}/Qualcomm/HEXAGON_Tools/7.2.12/Tools

ARMv7hf cross compiler: ${HEXAGON_SDK_ROOT}/gcc-linaro-4.9-2014.11-x86_64_arm-linux-gnueabihf_linux

ARMv7hf Ubuntu Trusty (14.04) sysroot [HEXAGON_ARM_SYSROOT]: ${HOME}/Qualcomm/sysroot

You can re-run installv3.sh as many times as you like and it will only install missing pieces and then display the environment variables to set.
These can be copied and pasted into the shell for convienience.

## Sysroot Installation

Create the Ubuntu Trusty (14.04) sysroot
```
export HEXAGON_SDK_ROOT=${HOME}/Qualcomm/Hexagon_SDK/3.0
./trusty_sysroot.sh
```
