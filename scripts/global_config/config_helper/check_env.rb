=begin

    Copyright (C) 2015 Franz Flasch <franz.flasch@gmx.at>

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

require 'pathname'

def set_input_env(var)
    if ENV[var].nil? || ENV[var].empty?
        abort ("#{var} not set!")
    end
    return ENV[var]
end


def set_input_env_default(var, default_val)
    if ENV[var].nil? || ENV[var].empty?
        puts ("#{var} not set, using #{default_val}")
        return default_val
    else
        return ENV[var]
    end
end

def set_workdir(input_keyword, default_val)
    tmp_path = set_input_env_default(input_keyword, default_val)

    if (Pathname.new tmp_path).absolute?
        return "#{tmp_path}"
    else
        return "#{Rake.original_dir}/#{tmp_path}"
    end
end


# Check for environment variables
ARCH = set_input_env("ARCH")
MACH = set_input_env("MACH")
PROJECT_FOLDER = set_input_env("PROJECT_FOLDER")
WORKDIR = set_workdir("WORKDIR", "rem_workdir")
VERBOSE = set_input_env_default("VERBOSE", "0")
SIMPLECOV = set_input_env_default("SIMPLECOV", "0")
USE_CLANG = set_input_env_default("USE_CLANG", "0")
