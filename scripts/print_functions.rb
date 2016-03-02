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

def print_debug(text)
    if(VERBOSE == "1")
        puts text
    end
end

def print_any_green(text)
    puts "\033[32m#{text}\033[0m\n"
end

def print_any_red(text)
    # will produce red text color
    puts "\033[31m#{text}\033[0m\n"
end

def print_any(text)
    puts text
end

def print_abort(text)
    # will produce red text color
    print_any_red(text)
    abort
end
