#!/bin/bash

REM_PATH=$1

echo REMPATH $REM_PATH
export PATH=$REM_PATH:$PATH

git clone https://github.com/franzflasch/rem_packages.git
git clone https://github.com/franzflasch/rem_test_project.git
git clone https://github.com/franzflasch/rem_libopenpic32.git

rem ARCH=avr MACH=atmega168 PROJECT_FOLDER="rem_packages rem_test_project" -m -j4 package:test_project:image[hex] VERBOSE=1 && echo OK || exit 1
rm -rf rem_workdir
rem ARCH=arm MACH=stm32f1 PROJECT_FOLDER="rem_packages rem_test_project" -m -j4 package:test_project:image[bin] VERBOSE=1 && echo OK || exit 2
rm -rf rem_workdir
rem ARCH=arm MACH=stm32f3 PROJECT_FOLDER="rem_packages rem_test_project" -m -j4 package:test_project:image[bin] VERBOSE=1 && echo OK || exit 3
rm -rf rem_workdir
rem ARCH=arm MACH=stm32f4 PROJECT_FOLDER="rem_packages rem_test_project" -m -j4 package:test_project:image[bin] VERBOSE=1 && echo OK || exit 4
rm -rf rem_workdir
rem ARCH=8051 MACH=nrf24le1_32 PROJECT_FOLDER="rem_packages rem_test_project" -m -j4 package:test_project:image[bin] VERBOSE=1 && echo OK || exit 5
rm -rf rem_workdir
rem ARCH=mips MACH=pic32mx2 PROJECT_FOLDER="rem_test_project rem_libopenpic32 rem_packages" package:test_project:image[srec] VERBOSE=1 && echo OK || exit 5
rm -rf rem_workdir
rem ARCH=mips MACH=pic32mz2048 PROJECT_FOLDER="rem_test_project rem_libopenpic32 rem_packages" package:test_project:image[srec] VERBOSE=1 && echo OK || exit 5
rm -rf rem_workdir

rm -rf rem_packages
rm -rf rem_test_project
