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

NON_FILE_TASK = 0
FILE_TASK = 1

def package_add_non_file_task_dep(package_list, dependency_list, which, pkg_name)
    dep_str_array = []
    dependency_list.each do |dep|
        dep_ref = pkg_get_ref_by_name(package_list, dep, pkg_name)
        dep_str_array.push("package:#{dep_ref.name}:#{which}")
    end
    return dep_str_array
end

def package_add_file_task_dep(package_list, dependency_list, which, pkg_name)
    dep_str_array = []
    dependency_list.each do |dep|
        dep_ref = pkg_get_ref_by_name(package_list, dep, pkg_name)
        case which
            when "download"
                    dep_str_array.push("#{dep_ref.pkg_dl_state_file}")
            else
                    dep_str_array.push("#{dep_ref.get_package_state_file("#{which}")}")
        end
    end
    return dep_str_array
end

# Generates a list of dependencies
# input has to be composed like this
# package_list - list of package references
# task_list - [ pkg.deps_array, "compile", pkg.get_name_splitted, "prepare"] # Every second entry is the dependency array, Every second+1 entry is the "which" entry
# file_task - specifies if the output dependencies shall be file tasks or non file tasks
def package_add_common_task_dep_list(package_list, task_list, file_task, pkg_name)
    dep_str_array = []
    # At first get the number of tasks
    task_count = ((task_list.length/2)-1)
    (0..task_count).step(1) do |i|
        # Every second entry is the dependency list
        deps_array = task_list[(i*2)]
        which = task_list[(i*2)+1]
        if(file_task == 1)
            dep_str_array.concat(package_add_file_task_dep(package_list, deps_array, which, pkg_name))
        else
            dep_str_array.concat(package_add_non_file_task_dep(package_list, deps_array, which, pkg_name))
        end
    end
    return dep_str_array
end

def package_get_dependency_list(package_list, pkg, dep_list)
    if(pkg.deps.any?)
        dep_list.concat(pkg.deps)
    end
    pkg.deps.each do |dep|
        dep_ref = pkg_get_ref_by_name(package_list, dep, pkg.name)
        package_get_dependency_list(package_list, dep_ref, dep_list)
    end
end

