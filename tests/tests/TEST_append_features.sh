#!/bin/bash

REM_PATH=$1

echo REMPATH $REM_PATH
export PATH=$REM_PATH:$PATH

git clone https://github.com/franzflasch/rem_packages.git
git clone https://github.com/franzflasch/rem_recipe_testing.git

rem ARCH=avr MACH=atmega168 PROJECT_FOLDER="rem_packages rem_recipe_testing/avr_append_test rem_recipe_testing/common" -m -j4 package:test_project:image[hex] VERBOSE=1
rm -rf rem_workdir

rm -rf rem_packages
rm -rf rem_test_project
