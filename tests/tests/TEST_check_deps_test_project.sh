#!/bin/bash

REM_PATH=$1

echo REMPATH $REM_PATH
export PATH=$REM_PATH:$PATH
export PATH=$REM_PATH/shell_scripts:$PATH

git clone https://github.com/franzflasch/rem_packages.git
git clone https://github.com/franzflasch/rem_test_project.git

ARCH=avr MACH=atmega168 PROJECT_FOLDER="rem_packages rem_test_project" PACKAGE_NAME=test_project check_deps.sh && echo OK || exit 1
rm -rf rem_workdir

rm -rf rem_packages
rm -rf rem_test_project
