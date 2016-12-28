#!/bin/bash
#
#     Copyright (C) 2016 Franz Flasch <franz.flasch@gmx.at>
#     This file is part of REM - Rake for EMbedded Systems and Microcontrollers.
#     REM is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
#     REM is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
#     You should have received a copy of the GNU General Public License
#     along with REM.  If not, see <http://www.gnu.org/licenses/>.
#

file_name=$1
begin_of_function=$2

opened=0
closed=0
number_of_lines=`wc -l < $file_name`

#echo "NUMBER of lines: $number_of_lines"

line_number=$begin_of_function
while true
do
   var_open=`head -$line_number $file_name | tail -1 | grep -oh "{" | wc -w`
   var_closed=`head -$line_number $file_name | tail -1 | grep -oh "}" | wc -w`

   #tmp_opened=`head -$line_number $file_name | tail -1 | grep -oh "{"`
   #tmp_closed=`head -$line_number $file_name | tail -1 | grep -oh "}"`
   #echo "opened $tmp_opened"
   #echo "closed $tmp_closed"

   opened=$(($opened + $var_open))
   #echo "opened:" $opened

   closed=$(($closed + $var_closed))
   #echo "closed:" $closed
   #echo ""

   if [ $opened == $closed ] && [ $opened -ne 0 ]; then
      echo "Commenting file $file_name from linenumber $begin_of_function to linenumber $line_number"
      #echo "Function end: linenumber: $line_number"
      sed -i $begin_of_function's/.*/#if 0 /' $file_name
      # append after the bracket
      #sed -i $line_number's/$/ #endif/' $file_name
      # replace the bracket
      sed -i $line_number's/.*/#endif/' $file_name
      exit 0
   fi

   if [ $line_number -ge $number_of_lines ]; then
      echo "ERROR: End of file, could not find end of function!"
      exit 1
   fi

   line_number=$(($line_number + 1))
done
