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

def get_recipes(project_folders, recipe_file_ending)
    project_folders = project_folders.split(" ")
    files = []
    files = find_files_with_ending(project_folders, recipe_file_ending)

    if files.empty?
        return nil
    end

    print_debug("Found the following recipes:")
    print_debug(files)
    print_debug("")

    return files
end

def prepare_recipes(recipes, append=false)
    recipe_filenames = []
    pkgs = []

    print_debug "Searching for recipes..."

    # Remove directory from all recipes - this is needed to check for duplicates
    recipes.each {|e| recipe_filenames.push(get_filename_from_uri(e))}

    check_duplicates_exit_with_error(recipe_filenames, "recipes")

    recipes.each do |r|

        print_debug "parsing recipe #{r}:"

        # Parse and include submakefiles
        if(append == true)
            cur_pkg = SoftwarePackageAppend.new(r)
        else
            cur_pkg = SoftwarePackage.new(r)
        end

        # # Iterate and set instance variables:
        # cur_pkg.instance_variables.each do |var|
        #     print(var)
        #     #cur_pkg.instance_variable_set(var, 'foobar')
        #     print("\n")
        #     print(cur_pkg.instance_variable_get(var).inspect)
        #     print("\n")

        #     if cur_pkg.instance_variable_get(var).kind_of?(Array)
        #         printf("ARRAY!")
        #     end
        # end

        pkgs.push(cur_pkg)
    end
    return pkgs
end

def merge_recipes_append(recipe_list, append_recipe_list)

    append_recipe_list.each do |append_pkg|
        print_any_yellow(append_pkg.name)
        tmp_pkg = pkg_get_ref_by_name(recipe_list, append_pkg.name)

        if tmp_pkg == nil
            print_any_yellow("Could not find matching base recipe for append recipe " + append_pkg.name)
        else
            print_any_yellow(tmp_pkg.name)
            # Iterate and set instance variables:
            append_pkg.instance_variables.each do |var|
                # print(var)
                # #cur_pkg.instance_variable_set(var, 'foobar')
                # print("\n")
                print_any_yellow(append_pkg.instance_variable_get(var).inspect)
                # print("\n")

                # At the moment only array types will get appended
                if tmp_pkg.instance_variable_get(var).kind_of?(Array)
                    val_to_append = append_pkg.instance_variable_get(var)
                    tmp_pkg.instance_variable_get(var).concat(val_to_append)
                    print_any_yellow("Appending #{var} #{val_to_append} to recipe #{tmp_pkg.name}")
                    print_any_yellow(tmp_pkg.instance_variable_get(var.to_s))
                end
            end
        end
    end

    print_any_yellow("Merging append recipes done.")
end

def filter_packages(pkg_list, current_arch_config, current_mach_config)
    tmp_pkg_list = []
    pkg_list.each_with_index do |cur_pkg, index|
        # Filter out packages which do not match arch or mach config
        arch_config = cur_pkg.arch
        mach_config = cur_pkg.mach

        if ( (arch_config == "generic") or 
             (arch_config == current_arch_config and mach_config == "generic")  or 
             (arch_config == current_arch_config and mach_config == current_mach_config)
            )
            tmp_pkg_list.push(cur_pkg)
        else
            print_debug "ARCH Config #{arch_config} or MACH Config #{mach_config} does not match - current arch config: #{current_arch_config} - current mach config: #{current_mach_config}, skipping recipe: #{cur_pkg.name}"
            #pkg_list.delete_at(index)
        end
    end

    pkg_list = tmp_pkg_list

    print_any("Now having the following recipes:")
    pkg_list.each do | pkg |
        print_any(pkg.name)
    end

    return tmp_pkg_list
end

def pkg_get_ref_by_name(pkg_list, name, needed_by_info=nil)

    # find via index:
    #result = ref_list.index{ |item| item.name == name }
    #return ref_list[result]

    # find directly:
    result = pkg_list.find{ |item| item.name == name }

    if result == nil
        if needed_by_info != nil
            return print_abort("ERROR: No recipe found for package #{name}!" + " Needed by: " + needed_by_info)
        else
            return nil
        end
    else
        return result
    end
end
