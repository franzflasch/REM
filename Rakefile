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

# Global Config
require_relative "scripts/global_config"

# Machine and compiler specific
require_relative "machine_conf/#{global_config.get_arch}/#{global_config.get_mach}"
require_relative "scripts/#{global_config.compiler}_tasks/DefaultTasks"

# Prepare and Patch tasks:
require_relative "scripts/download_tasks/DefaultTasks"
require_relative "scripts/prepare_tasks/DefaultTasks"
require_relative "scripts/patch_tasks/DefaultTasks"

# Generic
require_relative "scripts/helper"
require_relative "scripts/print_functions"
require_relative "scripts/package"

require "find"
require "fileutils"

# Main:
namespace :package do

    NON_FILE_TASK = 0
    FILE_TASK = 1

    global_recipe_files = []
    global_package_list = []

    def get_recipes
        project_folders = "#{global_config.get_project_folder()}".split(" ")
        files = []
        files = find_files_with_ending(project_folders, "rem")

        if files.empty?
            print_abort ("No recipes found!")
        end

        print_debug("Found the following recipes:")
        print_debug(files)
        print_debug("")

        return files
    end

    def create_workdir
        FileUtils.mkdir_p(BUILD_DIR)
        FileUtils.mkdir_p(DL_DIR)
        FileUtils.mkdir_p(DL_STATE_DIR)
    end

    def parse_recipe_file_and_fill_package_info(recipe_file)
        cur_pkg = SoftwarePackage.new(recipe_file)
        return cur_pkg
    end

    def prepare_recipes(recipes)
        package_ref_list = SoftwarePackageList.new()
        recipe_filenames = []

        print_debug "Including recipes..."

        # Remove directory from all recipes - this is needed to check for duplicates
        recipes.each {|e| recipe_filenames << File.basename(e)}

        # Now put warning if there are any duplicate recipes
        duplicates = check_duplicates(recipe_filenames)
        if duplicates.uniq.any?
            print_abort ("ERROR: Duplicates in the recipe list: #{duplicates.uniq}")
        end

        recipes.each do |r|

            print_debug "parsing recipe " + r + ":"

            # Parse and include submakefiles
            cur_pkg = parse_recipe_file_and_fill_package_info(r)

            # Do some verbose output
            print_debug "#{cur_pkg.get_info}"

            case cur_pkg.get_arch
                when "generic"
                    if cur_pkg.get_mach == "generic"
                        package_ref_list.append("#{cur_pkg.get_name}", cur_pkg)
                    else
                        print_abort "Invalid ARCH-MACH Combination: arch:#{cur_pkg.get_arch} mach:#{cur_pkg.get_mach}"
                    end
                when "#{global_config.get_arch}"
                    if (cur_pkg.get_mach == "generic" or cur_pkg.get_mach == "#{global_config.get_mach}")
                        package_ref_list.append("#{cur_pkg.get_name}", cur_pkg)
                    else
                        print_debug "MACH Config: #{cur_pkg.get_mach} does not match - current mach config: #{global_config.get_mach}, skipping recipe: #{r}"
                    end
                else
                    print_debug "ARCH Config: #{cur_pkg.get_arch} does not match - current arch config: #{global_config.get_arch}, skipping recipe: #{r}"
            end
        end

        return package_ref_list
    end

    def package_add_non_file_task_dep(package_list, dependency_list, which)
        dep_str_array = []
        dependency_list.each do |dep|
            dep_ref = package_list.get_ref_by_name(dep)
            dep_str_array.push("package:#{dep_ref.get_name}:#{which}")
        end
        return dep_str_array
    end

    def package_add_file_task_dep(package_list, dependency_list, which)
        dep_str_array = []
        dependency_list.each do |dep|
            dep_ref = package_list.get_ref_by_name(dep)
            case which
                when "download"
                        dep_str_array.push("#{dep_ref.get_download_state_file()}")
                else
                        dep_str_array.push("#{dep_ref.get_package_state_file("#{which}")}")
            end
        end
        return dep_str_array
    end

    # Generates a list of dependencies
    # input has to be composed like this
    # package_list - list of package references
    # task_list - [ pkg.get_deps_array, "compile", pkg.get_name_splitted, "prepare"] # Every second entry is the dependency array, Every second+1 entry is the "which" entry
    # file_task - specifies if the output dependencies shall be file tasks or non file tasks
    def package_add_common_task_dep_list(package_list, task_list, file_task)
        dep_str_array = []
        # At first get the number of tasks
        task_count = ((task_list.length/2)-1)
        (0..task_count).step(1) do |i|
            # Every second entry is the dependency list
            deps_array = task_list[(i*2)]
            which = task_list[(i*2)+1]
            if(file_task == 1)
                dep_str_array.concat(package_add_file_task_dep(package_list, deps_array, which))
            else
                dep_str_array.concat(package_add_non_file_task_dep(package_list, deps_array, which))
            end
        end
        return dep_str_array
    end

    #### Behaviour begin: ####

    # At first set the main rakefile base directory
    global_config.set_main_working_dir(Rake.original_dir)

    print_any("Parsing recipes...")
    global_recipe_files = get_recipes()
    global_package_list = prepare_recipes(global_recipe_files)

    # 'global' variables used across tasks:
    global_dep_chain = []

    global_package_list.get_ref_list.each do |pkg|

        namespace :"#{pkg.get_name}" do

            # set global defines
            pkg.get_global_defines.each do |e|
                global_config.set_define("#{e}")
            end

            # set global_linkerflags
            pkg.get_global_linker_flags.each do |e|
                global_config.set_link_flag("#{e}")
            end



            task :get_dep_chain => package_add_non_file_task_dep(global_package_list, pkg.get_deps_array, "get_dep_chain") do
                global_dep_chain.push("#{pkg.get_name}")
            end



            desc "depends_chain_print"
            task :depends_chain_print => package_add_non_file_task_dep(global_package_list, pkg.get_deps_array, "depends_chain_print") do
                tmp_string = ""
                pkg.get_deps_array.each do |e|
                    tmp_string << "#{e} "
                end
                if tmp_string.to_s == ""
                    print_any_green("#{pkg.get_name}")
                else
                    print_any_green("#{pkg.get_name} --> " + tmp_string)
                end
            end



            def create_download_file_task(pkg_ref, package_list, tasks_common)

                file "#{pkg_ref.get_download_state_file()}" do
                    # As this is the first task in the chain create work directories here:
                    Rake::Task["package:create_workdir"].invoke()

                    print_any_green "Downloading #{pkg_ref.get_name}..."
                    pkg_ref.download()
                end
            end

            desc "download"
            task :download do
                print_debug("download: #{pkg.get_name}")
                create_download_file_task(pkg, global_package_list, 0)
                Rake::Task["#{pkg.get_download_state_file()}"].invoke()
                print_debug("finish #{pkg.get_name} download")
            end



            prepare_tasks_common = [ pkg.get_name_splitted, "download" ]
            def create_prepare_file_task(pkg_ref, package_list, tasks_common)

                pkg_prepare_list = package_add_common_task_dep_list(package_list, tasks_common, FILE_TASK)

                # Add source file dependencies and include folders
                if pkg_ref.get_uri == "package.local"
                    pkg_ref.get_src_array.each do |e|
                        pkg_prepare_list.push("#{pkg_ref.get_base_dir}/#{e}")
                    end

                    # At first find all *.h files:
                    header_files = []
                    pkg_ref.get_inc_dir_array.each do |e|
                        header_files = find_files_with_ending("#{pkg_ref.get_base_dir}/#{e}".split(" "), "h")
                    end

                    # Now add it to the dependendy list
                    header_files.each do |e|
                        pkg_prepare_list.push("#{e}")
                    end
                end

                file "#{pkg_ref.get_package_state_file("prepare")}" => pkg_prepare_list do
                    print_any_green "Preparing #{pkg_ref.get_name}..."
                    pkg_ref.prepare_package_state_dir()
                    pkg_ref.prepare()
                    print_debug "#{pkg_ref.get_name} prepare list: #{pkg_prepare_list}"
                end
            end

            desc "prepare"
            task :prepare => package_add_common_task_dep_list(global_package_list, prepare_tasks_common, NON_FILE_TASK) do
                print_debug("prepare: #{pkg.get_name}")
                create_prepare_file_task(pkg, global_package_list, prepare_tasks_common)
                Rake::Task["#{pkg.get_package_state_file("prepare")}"].invoke()
                print_debug("finish: #{pkg.get_name} prepare")
            end



            compile_tasks_common = [ pkg.get_deps_array, "compile", pkg.get_name_splitted, "prepare"]
            def create_compile_file_task(pkg_ref, package_list, tasks_common)

                pkg_compile_list = package_add_common_task_dep_list(package_list, tasks_common, FILE_TASK)

                # Prepare include directories of the dependencies
                dep_inc_array = []
                pkg_ref.get_deps_array.each do |dep|
                    dep_ref = package_list.get_ref_by_name(dep)
                    dep_ref.incdir_prepare(dep_inc_array)
                    dep_inc_array.concat(dep_ref.get_incdirs)
                end

                pkg_ref.compile_prepare()
                pkg_ref.incdir_prepare(dep_inc_array)

                desc "#{pkg_ref.get_package_state_file("compile")}"
                file "#{pkg_ref.get_package_state_file("compile")}" => pkg_compile_list do
                    print_any_green "Compiling #{pkg_ref.get_name}..."
                    pkg_ref.compile()
                end
            end

            desc "compile"
            task :compile => package_add_common_task_dep_list(global_package_list, compile_tasks_common, NON_FILE_TASK) do
                print_debug("compile: #{pkg.get_name}")
                create_compile_file_task(pkg, global_package_list, compile_tasks_common)
                Rake::Task["#{pkg.get_package_state_file("compile")}"].invoke()
                print_debug("finish: #{pkg.get_name} compile")
            end



            link_tasks_common = [ pkg.get_name_splitted, "compile"]
            def create_link_file_task(pkg_ref, package_list, tasks_common, dep_chain)
                pkg_link_list = package_add_common_task_dep_list(package_list, tasks_common, FILE_TASK)

                # Prepare include directories of the dependencies
                dep_obj_array = []
                dep_chain.each do |dep|
                    dep_ref = package_list.get_ref_by_name(dep)
                    dep_ref.compile_prepare()
                    dep_obj_array.concat(dep_ref.get_objs)
                end

                desc "#{pkg_ref.get_package_state_file("link")}"
                file "#{pkg_ref.get_package_state_file("link")}" =>  pkg_link_list do
                    print_any_green "Linking #{pkg_ref.get_name}..."
                    pkg_ref.prepare_package_deploy_dir()
                    pkg_ref.link(dep_obj_array)
                end
            end

            desc "link"
            task :link => package_add_non_file_task_dep(global_package_list, pkg.get_name_splitted, "get_dep_chain") +
                          package_add_common_task_dep_list(global_package_list, link_tasks_common, NON_FILE_TASK) do
                print_debug("link: #{pkg.get_name}")
                create_link_file_task(pkg, global_package_list, link_tasks_common, global_dep_chain)
                Rake::Task["#{pkg.get_package_state_file("link")}"].invoke()
                print_debug("finish: #{pkg.get_name} link")
            end



            desc "Do #{pkg.get_name} image"
            task :image, [:what] => package_add_non_file_task_dep(global_package_list, pkg.get_name_splitted, "link") do |t, args|
                print_any_green "Making image #{pkg.get_name}..."
                pkg.make_image("#{args[:what]}")
            end



            desc "Do #{pkg.get_name} clean"
            task :clean, [:what] do |t, args|
                print_any_green "Cleaning #{pkg.get_name}..."
                case args[:what]
                    when "download"
                        pkg.clean_download()
                    when "prepare"
                        pkg.cleanprepare()
                    when "compile"
                        pkg.clean_compile()
                    when "link"
                        pkg.clean_link()
                    when "all"
                        pkg.cleanall()
                    else
                        print_abort("Invalid argument #{args[:what]}")
                end
            end


        end
    end

    task :create_workdir do
        print_any("Preparing work directories...")
        create_workdir()
    end



    desc "List available packages"
    task :list_packages do |t, args|
        print_any ""
        print_any "Following software packages are available for this architecture: "
        global_package_list.get_ref_list.each do |pkg|
            print_any "#{pkg.get_name}"
        end
    end



end
