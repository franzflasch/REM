#!/bin/bash

# Copyright (C) 2016 Franz Flasch <franz.flasch@gmx.at>

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

folder_to_check=$1
folders_to_exclude=($2)

excluded=()
for var in "${folders_to_exclude[@]}"
do
	excluded+=("-i$var ")
done

# output will be put to stderr so we need to redirect to stdout with 2>&1
cpp_output=(`cppcheck --template='{file} {line}' -q ${excluded[@]} --enable=unusedFunction $folder_to_check 2>&1`)
#echo ${cpp_output[@]}

cpp_output_len=${#cpp_output[@]}

echo "Found unused functions in the following files:"
for (( i=0; i<$(( cpp_output_len )); i+=2 ))
do
	echo ${cpp_output[i]}
done

for (( i=0; i<$(( cpp_output_len )); i+=2 ))
do
	file_name=${cpp_output[i]}
	line_number=${cpp_output[i+1]}
	#echo $file_name $line_number
	find_func_and_comment.sh $file_name $line_number
done
