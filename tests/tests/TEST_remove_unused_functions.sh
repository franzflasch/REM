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
export PATH=$REM_PATH/shell_scripts:$PATH

git clone https://github.com/franzflasch/rem_packages.git
git clone https://github.com/franzflasch/rem_test_project.git

rem ARCH=8051 MACH=nrf24le1_32 PROJECT_FOLDER=rem_packages,rem_test_project -m -j4 package:test_project:link VERBOSE=1 && echo OK || exit 1
comment_unused_functions_cppcheck.sh rem_workdir/8051_nrf24le1_32/build "rem_workdir/8051_nrf24le1_32/build/nrf24le1_sdk_nohash/" && echo OK || exit 2
rm -rf rem_workdir

rm -rf rem_packages
rm -rf rem_test_project
