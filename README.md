# cross_toolchain

This project will install the Hexagon SDK 3.0, ARMv7hf cross compiler, and an ARMv7hf sysroot
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

You can re-run installv3.sh as many times as you like and it will only install missing pieces and then display the environment variables to set.
These can be copied and pasted into the shell for convienience.

## Sysroot Installation

There are 2 sysroot options. The recommended is QRLinux because it provides access to all the proprietary libraries to access camera, etc on Snapdragon Flight.

If you do not have an Intrinsyc account, you can use stock Ubuntu Trusty (14.04) sysroot to build PX4 , but will not have access to the camera headers and libs.

Additional packages can be added to either sysroot by adding them to the EXTRA_PACKAGES list in the sysroot installer script.

### QRLinux sysroot

The QRLinux sysroot contains all the additional libraries to use the camera, etc on Snapdragon Flight that are are only available in the QRLinux image.

Login to the Intrinsyc support page and download: http://support.intrinsyc.com/attachments/download/483/Flight_qrlSDK.zip

copy/move the file to the ./download directory
```
cp ~/Downloads/Flight_qrlSDK.zip ./downloads
./qrlinux_sysroot.sh --clean
```

This will install:

ARMv7hf QRLinux sysroot [HEXAGON_ARM_SYSROOT]: ${HOME}/Qualcomm/qrlinux_v1.0_sysroot

### Stock Ubuntu Trusty (14.04) sysroot

Create the Ubuntu Trusty (14.04) sysroot
```
export HEXAGON_SDK_ROOT=${HOME}/Qualcomm/Hexagon_SDK/3.0
./trusty_sysroot.sh
```

This will install:

ARMv7hf Ubuntu Trusty (14.04) sysroot [HEXAGON_ARM_SYSROOT]: ${HOME}/Qualcomm/ubuntu_14.04_armv7_sysroot

