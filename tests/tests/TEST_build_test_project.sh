#!/bin/bash

REM_PATH=$1

echo REMPATH $REM_PATH
export PATH=$REM_PATH:$PATH

#ENV PATH /home/rem_build/REM:$PATH

git clone https://github.com/franzflasch/rem_packages.git
git clone https://github.com/franzflasch/rem_test_project.git

rem ARCH=avr MACH=atmega168 PROJECT_FOLDER="rem_packages rem_test_project" -m -j4 package:test_project:image[hex] VERBOSE=1
rm -rf rem_workdir
rem ARCH=arm MACH=stm32f3 PROJECT_FOLDER="rem_packages rem_test_project" -m -j4 package:test_project:image[bin] VERBOSE=1
rm -rf rem_workdir
