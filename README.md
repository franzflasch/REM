# REM
Rake based buildsystem for EMbedded Systems and Microcontrollers

## Prerequisites
Appropriate Microcontroller toolchain (arm-none-eabi, avr, sdcc ...)
ruby (a recent version: >= version 2.2.1)
rake (a recent version: >= version 10.4.2)
simplecov (if you want to use codecoverage tool)
unzip
git
patch

## How to build a hex file of the test project suited for an avr atmega168:
```Shell
rake ARCH=avr MACH=atmega168 PROJECT_FOLDER="package test_project" -m -j4 package:test_project:image[hex]
```
The arguments "-m -j4" mean to build with max 4 threads simultaneously.

## How to build a binary file of the test project suited for an arm stm32f3:
```Shell
rake ARCH=arm MACH=stm32f3 PROJECT_FOLDER="package test_project" -m -j4 package:test_project:image[bin]
```

## You can also add verbose output:
```Shell
rake ARCH=arm MACH=stm32f3 PROJECT_FOLDER="package test_project" -m -j4 package:test_project:image[bin] VERBOSE=1
```

## Example of how to load the hex file into an atmega168 microcontroller.
```Shell
avrdude -F -cstk500v2 -P/dev/ttyUSB0 -patmega168p -Uflash:w:workdir/avr_atmega168/deploy/test_project/test_project.hex
```

## List all available packages for this architecture:
```Shell
rake ARCH="avr" MACH="atmega168" PROJECT_FOLDER="package" package:list_packages
```

## Get a list of dependencies for a particular package:
```Shell
rake ARCH="avr" MACH="atmega168" PROJECT_FOLDER="package" package:msglib_test:depends_chain_print
```

## Using the shell based wrapper script to start the build:
REM also comes with a wrapper script, which basically calls rake -f "path/to/main/Rakefile" and allows to start the build outside of the REM base directory, if it is added to the PATH variable:
```Shell
rem ARCH="avr" MACH="atmega168" PROJECT_FOLDER="package" package:msglib_test:depends_chain_print
```

## It is also possible to generate a package specific "remfile", in which all infos about the package and its dependencies are stored. This should increase the speed of the whole build process, as it is not needed to reparse all recipes when starting a new build.
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

## There is also a little script which helps checking if you have unnecessary dependencies set:
```Shell
WORKDIR=/home/user/Desktop/rem_workdir ARCH=arm MACH=stm32f3 PROJECT_FOLDER="test_project rem_packages" PACKAGE_NAME=test_project check_deps.sh
```

## Currently supported microcontrollers (resp. eval-boards)
AVR Atmega168
ST Olimex STM32H103
ST STM32F3 Discovery
ST STM32F4 Discovery
