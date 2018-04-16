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

OUTPUT=`rem ARCH=avr MACH=atmega168 PROJECT_FOLDER=rem_packages,rem_recipe_testing/avr_append_test,rem_recipe_testing/common,rem_recipe_testing/global_dependency -m -j4 package:test_project:depends_chain_print VERBOSE=1`

echo $OUTPUT | grep -q 'global_dep_test' && echo OK || exit 1
echo $OUTPUT | grep -q 'global_dep_test2 --> global_dep_test' && echo OK || exit 2
echo $OUTPUT | grep -q 'global_dep_test3 --> global_dep_test2' && echo OK || exit 3

rm -rf rem_workdir
rm -rf rem_packages
rm -rf rem_recipe_testing
