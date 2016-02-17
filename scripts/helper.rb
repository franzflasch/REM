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

require 'open3'

def find_files_with_ending(folders, ending)
    files = []
    folders.each do |e|
        Find.find("#{e}") do |path|
            files << path if path =~ /.*\.#{ending}$/
        end
    end
    return files
end

def check_duplicates(array)
    return array.select{|element| array.count(element) > 1 }
end

def execute2(cmd)
    if(VERBOSE == "0")
        # everything has to be quiet
        cmd << " >/dev/null 2>&1"
    end
    print_debug(cmd)
    exit_code = system(cmd, out: $stdout)
    if exit_code != true
        abort("Error when calling #{cmd} - exit code: #{$?.exitstatus}")
    end
end

def get_std_lines(input)
    ret_str = ""
    while line = input.gets
        ret_str << line
    end
    return ret_str
end

def execute(cmd)
    Open3.popen2e(cmd) do |stdin, stdout_err, wait_thr|
        cmd_std_message = get_std_lines(stdout_err)
        if(VERBOSE != "0")
            #print_lines(stdout_err)
            puts "#{cmd}"
        end

        exit_status = wait_thr.value
        unless exit_status.success?
            puts("Error when calling #{cmd} - exit code: #{exit_status} - STDOUT/STDERR:")
            abort("#{cmd_std_message}")
        end
    end
end