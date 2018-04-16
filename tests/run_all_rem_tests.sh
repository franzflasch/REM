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

BASEDIR=$(dirname "$0")
REM_PATH=$1

BUILD_ITEM_NAME=()
BUILD_ITEM_RESULT=()

for f in $BASEDIR/tests/TEST_*.sh ; 
do
	$f $REM_PATH
	BUILD_ITEM_RESULT+=("$?")
	BUILD_ITEM_NAME+=("$f")
done

for ((i=0; i < ${#BUILD_ITEM_RESULT[@]}; i++))
do
	if [[ ${BUILD_ITEM_RESULT[$i]} != 0 ]]; then
		echo "${BUILD_ITEM_NAME[$i]} not passed!"
		exit 1
	else
		echo "${BUILD_ITEM_NAME[$i]} passed!"
	fi
done

exit 0
