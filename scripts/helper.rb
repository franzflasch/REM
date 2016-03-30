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

### Searches for files with ending in folderlist
### Returns files as array
def find_files_with_ending(folder_list, ending)
    files = []
    folders = folder_list

    # check if folder_list is array or string
    unless folder_list.is_a?(Array)
        folders = folder_list.split(" ")
    end

    folders.each do |e|
        if File.exist?("#{e}")
            Find.find("#{e}") do |path|
                files << path if path =~ /.*\.#{ending}$/
            end
        else
            print_abort("Error: path #{e} does not exist!")
        end
    end
    return files
end

### Searches for files with ending in folderlist
### Returns files as string
def find_files_with_ending_str(folder_list, ending)
    list = find_files_with_ending(folder_list, ending)
    return list.join(" ")
end

def get_duplicates_in_array(array)
    return array.select{|element| array.count(element) > 1 }
end

def check_duplicates_exit_with_error(array, list_name)
    # Now put warning if there are any duplicate recipes
    duplicates = get_duplicates_in_array(array)
    if duplicates.uniq.any?
        print_abort ("ERROR: Duplicates in #{list_name}, duplicates: #{duplicates.uniq}")
    end
end

def execute(cmd)
    Open3.popen2e(cmd) do |stdin, stdout_err, wait_thr|
        cmd_std_message = ""
        print_debug(cmd)
        stdout_err.each do |line|
            print_debug(line)
            cmd_std_message << line
        end
        exit_status = wait_thr.value
        unless exit_status.success?
            print_any_red("Error when calling #{cmd} - exit code: #{exit_status} - STDOUT/STDERR:")
            print_any_red(cmd_std_message)
            abort
        end
    end
end

### Removes leading and trailing spaces as well as removing superflous
### spaces between strings
def string_strip(val)
    return "#{val.gsub(/\s+/, " ").strip} "
end

### Cuts the directory and the extension from the given uri
def get_filename_without_extension_from_uri(uri)
    #return File.basename(uri, extension)
    return File.basename(uri, File.extname(uri))
end

### Cuts the extension from the given uri
def get_uri_without_extension(uri)
    return File.join(File.dirname(uri), File.basename(uri, '.*'))
end

### Cuts the filename from the given uri
def get_dirname_from_uri(uri)
    return File.dirname(uri)
end

### Cuts the directory from the given uri
def get_filename_from_uri(uri)
    return File.basename(uri)
end

### Returns the file extension from the given uri
def get_extension_from_uri(uri)
    tmp = File.extname(uri)
    # return the "."
    tmp.slice!(0)
    return tmp
end
