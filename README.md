## ![Test Status](https://img.shields.io/badge/debian%208-passed-green.svg)
## ![Test Status](https://img.shields.io/badge/ubuntu%2014.04-passed-green.svg)

# REM
REM is a Yocto like buildsystem primarily intended for microcontrollers. It is based on ruby rake and therefore offers a highly flexible way of setting up projects for microcontrollers. If you know Yocto it should be easy to also learn the REM buildsystem. It consists of some features of Yocto, like recipe appending, inbuild patching and downloading software packages. Projects can be setup by only defining recipes, which describe how a specific component should be built. You can even setup your project with sources completely hosted by github! Not necessary to copy-paste software packages and libraries!

## Prerequisites
* Appropriate Microcontroller toolchain (arm-none-eabi, avr, sdcc ...)
* ruby (a recent version: >= version 2.2.1)
* rake (a recent version: >= version 10.4.2)
* unzip
* git
* subversion
* simplecov (optional)

# Getting started Debian/Ubuntu
* Minimal requirements
    - Debian (at least 8 "jessie")
    - Ubuntu (at least 14.04 "Trusty Tahr")

## 1. Install rake
```Shell
sudo apt-get install rake
```

## 2. Install other dependencies
```Shell
sudo apt-get install gcc-arm-none-eabi gcc-avr avr-libc git subversion unzip wget make python
```

## 3. Fetch REM buildsystem
```Shell
mkdir rem_build
cd rem_build
git clone https://github.com/franzflasch/REM.git
```

## 4. Prepare test project
```Shell
git clone https://github.com/franzflasch/rem_packages.git
git clone https://github.com/franzflasch/rem_test_project.git
```

## 5. Prepare PATH
```Shell
cd REM
export PATH=`pwd`:$PATH
cd ..
```

## 6. Start build

### Atmel Atmega168
```Shell
rem ARCH=avr MACH=atmega168 PROJECT_FOLDER="rem_packages rem_test_project" -m -j4 package:test_project:image[hex]
```

### STMicroelectronics STM32F3
```Shell
rem ARCH=arm MACH=stm32f3 PROJECT_FOLDER="rem_packages rem_test_project" -m -j4 package:test_project:image[bin]
```

### SILABS C8051FXXX
```Shell
rem ARCH=8051 MACH=C8051FXXX PROJECT_FOLDER="rem_packages rem_test_project_sdcc" -m -j4 package:test_project:image[hex]
```

The image will end up in rem_workdir/#{arch}_#{machine}/deploy
It will be either a binary or hex image, depending on what you've chosen to build.

The arguments "-m -j4" mean to build with max 4 threads simultaneously.

After the successful build you can flash the image with the right tool for your microcontroller.


# Further Build examples:

## Verbose output:
```Shell
rem ARCH=arm MACH=stm32f3 PROJECT_FOLDER="package test_project" -m -j4 package:test_project:image[bin] VERBOSE=1
```

## Load the hex file into an atmega168 microcontroller.
```Shell
avrdude -F -cstk500v2 -P/dev/ttyUSB0 -patmega168p -Uflash:w:workdir/avr_atmega168/deploy/test_project/test_project.hex
```

## List all available packages for this architecture:
```Shell
rem ARCH="avr" MACH="atmega168" PROJECT_FOLDER="package" package:list_packages
```

## Get a list of dependencies for a particular package:
```Shell
rem ARCH="avr" MACH="atmega168" PROJECT_FOLDER="package" package:msglib_test:depends_chain_print
```

## Generating a "remfile"
It is also possible to generate a package specific "remfile", in which all infos about the package and its dependencies are stored. This should increase the speed of the whole build process, as it is not needed to reparse all recipes when starting a new build.
```Shell
rem ARCH="arm" MACH="stm32f3" VERBOSE=1 WORKDIR=../../../../Desktop/rem_workdir PROJECT_FOLDER="package test_project" package:test_project:remfile_generate
```

## Clean remfile
```Shell
rem ARCH="arm" MACH="stm32f3" VERBOSE=1 WORKDIR=../../../../Desktop/rem_workdir PROJECT_FOLDER="package test_project" package:remfile_clean
```

## simplecov code coverage - check the codecoverage of the rem buildsystem itself
```Shell
rem ARCH="arm" MACH="stm32f3" VERBOSE=1 WORKDIR=../../../../Desktop/rem_workdir PROJECT_FOLDER="package test_project" package:test_project:image[bin] SIMPLECOV=1
```
The output will be placed in a folder called 'coverage'

## Dependency Check
There is also a little script which helps checking if there are any superfluous dependencies set:
```Shell
WORKDIR=/home/user/Desktop/rem_workdir ARCH=arm MACH=stm32f3 PROJECT_FOLDER="test_project rem_packages" PACKAGE_NAME=test_project check_deps.sh
```

## Supported microcontrollers
* Atmel Atmega168
* STMicroelectronics:
    - STM32F1
    - STM32F3
    - STM32F4
* SILABS
    - C8051FXXX

