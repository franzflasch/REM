#!/bin/bash

# Copyright (C) 2018 Franz Flasch <franz.flasch@gmx.at>

# This file is part of REM - Rake for EMbedded Systems and Microcontrollers.

# REM is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# REM is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with REM.  If not, see <http://www.gnu.org/licenses/>.

set -e

REM_PATH=$1

echo REMPATH $REM_PATH
export PATH=$REM_PATH:$PATH

git clone https://github.com/franzflasch/rem_packages.git
git clone https://github.com/franzflasch/rem_recipe_testing.git

rem ARCH=avr MACH=atmega168 PROJECT_FOLDER=rem_packages,rem_recipe_testing/avr_append_test,rem_recipe_testing/common -m -j4 package:test_project:image[hex] VERBOSE=1 && echo OK || exit 5
rm -rf rem_workdir

# Testing the task appending feature
rem ARCH=arm MACH=stm32f3 PROJECT_FOLDER=rem_packages,rem_recipe_testing/avr_append_task_test/foobar -m -j4 package:foo_task:compile VERBOSE=1 | grep -i "hello from the base recipe" && echo OK || exit 6
rm -rf rem_workdir

# If adding the append recipe it should be possible to use it on avr and also the compile task should have changed
rem ARCH=avr MACH=atmega168 PROJECT_FOLDER=rem_packages,rem_recipe_testing/avr_append_task_test -m -j4 package:foo_task:compile VERBOSE=1 | grep -i "hello from the append recipe" && echo OK || exit 6
rm -rf rem_workdir

rm -rf rem_packages
rm -rf rem_recipe_testing
