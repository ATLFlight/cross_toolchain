# cross_toolchain

This project will install the Hexagon SDK, Hexagon cross compiler, armhf cross compiler, and armhf sysroot
for Snapdragon Flight application development.

## Installation

Clone and build this project:
```
git clone https://github.com/ATLFlight/cross_toolchain.git
cd cross_toolchain
./install.sh
```

This will install:

Hexagon SDK [HEXAGON_SDK_ROOT]: ${HOME}/Qualcomm/Hexagon_SDK/2.0

Hexagon Tools [HEXAGON_TOOLS_ROOT]: ${HOME}/Qualcomm/HEXAGON_Tools/7.2.10/Tools

armhf cross compiler: ${HEXAGON_SDK_ROOT}/gcc-linaro-arm-linux-gnueabihf-4.8-2013.08_linux

armhf sysroot [HEXAGON_ARM_SYSROOT]: ${HEXAGON_SDK_ROOT}/sysroot

If HEXAGON_TOOLS_ROOT is set to ${HOME}/Qualcomm/HEXAGON_Tools/6.4.06 prior to running install.sh, then that version of Tools
can be installed from the Hexagon SDK installer and Hexagon Tools 7.2.10 will not be installed.
