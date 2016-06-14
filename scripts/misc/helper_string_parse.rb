=begin

    Copyright (C) 2016 Franz Flasch <franz.flasch@gmx.at>

    This file is part of REM - Rake for EMbedded Systems and Microcontrollers.

    REM is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    REM is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with REM.  If not, see <http://www.gnu.org/licenses/>.
=end

def parse_string(str_input_array, what)
    found = 0
    ret_str = ""
    tmp_str_arr = str_input_array
    tmp_str = tmp_str_arr.split(";")

    tmp_str.each do |e|
        if(e[/#{what}(.*)/])
            e.slice! "#{what}"
            ret_str = e
            found = 1
        end
    end

    if(found == 1)
        return ret_str
    else
        return "undefined"
    end
end
