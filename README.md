# cross_toolchain

This project will install the Hexagon SDK 3.0, Hexagon cross compiler, gcc 4.9 ARMv7hf cross compiler, and an ARMv7hf sysroot for Snapdragon Flight application development.

## SDK Installation

Clone this project:
```
git clone https://github.com/ATLFlight/cross_toolchain.git
cd cross_toolchain
```

Download the Hexagon SDK v3.0 from [here](https://developer.qualcomm.com/software/hexagon-dsp-sdk/tools) to your ```cross_toolchain/downloads``` location. (You need to create an account if you don't have one).

Download the latest version of the qrlSDK file from [here](https://support.intrinsyc.com/projects/snapdragon-flight/files) to your ```cross_toolchain/downloads``` location. (You need to create an account if you don't have one).

Run the installer
```
./installsdk.sh --APQ8074 --arm-gcc --qrlSDK
```
This will install:

Hexagon SDK [HEXAGON_SDK_ROOT]: ${HOME}/Qualcomm/Hexagon_SDK/3.0
Hexagon Tools [HEXAGON_TOOLS_ROOT]: ${HOME}/Qualcomm/HEXAGON_Tools/7.2.12/Tools
ARMv7hf cross compiler: ${HEXAGON_SDK_ROOT}/gcc-linaro-4.9-2014.11-x86_64_arm-linux-gnueabihf_linux
qrlSDK: ${HOME}/Qualcomm/qrlinux_sysroot/merged-rootfs

You can re-run installsdk.sh as many times as you like and it will only install missing pieces and then display the environment variables to set.

If you omit --arm-gcc or --qrlSDK in subsequent runs, these packages will be removed from the installation. Running subsequent times without --trim or --zip will have no effect.

### Triming the HEXAGON SDK and HEXAGON Tools installation

If you run
```
./installsdk.sh --APQ8074 --trim --arm-gcc --qrlSDK
```

It will remove all non-essential files and directories for building for Snapdragon Flight from the SDK and Tools installation.
This can be useful if you are for instance wanting to create a minimal install if the SDK and Tools for a CI test image.

You can also create a zipfile of the SDK:
```
./installsdk.sh --APQ8074 --trim --zip --arm-gcc --qrlSDK
```
