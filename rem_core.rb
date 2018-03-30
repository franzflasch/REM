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

# Helper function
require_relative "scripts/misc/helper"
require_relative "scripts/misc/print_functions"

# Global Config
require_relative "scripts/global_config/global_config"

# At first set the main rakefile base directory
global_config.set_rakefile_dir(File.dirname(__FILE__))

if(SIMPLECOV == "1")
    require 'simplecov'
    SimpleCov.command_name "rem codecoverage"
    SimpleCov.start
end

# Try to find machine specific folders
machine_conf_file = nil
project_folders = global_config.get_project_folder.split(",")
project_folders.each do |folder|
    if File.file?("./#{folder}/machine_conf/machine/#{global_config.arch}/#{global_config.mach}.rb")
        machine_conf_file = "./#{folder}/machine_conf/machine/#{global_config.arch}/#{global_config.mach}.rb"
        break
    end
end

if(machine_conf_file != nil)
    load "#{machine_conf_file}"
else
    print_abort("No valid machine conf found!")
end

# Prepare and Patch tasks:
require_relative "scripts/download_tasks/download"
require_relative "scripts/prepare_tasks/prepare"
require_relative "scripts/patch_tasks/patch"

# Generic
require_relative "scripts/package"
require_relative "scripts/dependency_functions/dependency_tasks"
require_relative "scripts/dependency_functions/dependency_graph"
require_relative "scripts/remfile_functions/remfile_gen"
require_relative "scripts/recipe_handling/recipes"

require "find"
require "fileutils"
require 'digest'

def create_workdir
    FileUtils.mkdir_p(BUILD_DIR)
    FileUtils.mkdir_p(DL_DIR)
    FileUtils.mkdir_p(DL_STATE_DIR)
end

# Main:
namespace :package do

    # 'global' variables used across tasks:
    global_package_list = []
    global_dep_chain = []

    # Check if a rem_file was already generated
    if File.exist?(global_config.get_remfile())
        rem_recipes = yaml_parse(global_config.get_remfile())
    else
        print_debug("Parsing recipes...")
        rem_recipes = get_recipes("#{global_config.get_project_folder()}", "rem")
    end

    if rem_recipes == nil
        print_abort ("No recipes found!")
    end

    temp_pkgs = prepare_recipes(rem_recipes)

    remappend_recipes = get_recipes("#{global_config.get_project_folder()}", "remappend")
    if remappend_recipes != nil
        temp_pkgs_append = prepare_recipes(remappend_recipes, true)
        merge_recipes_append(temp_pkgs, temp_pkgs_append)
    end

    temp_pkgs = filter_packages(temp_pkgs, "#{global_config.arch}", "#{global_config.mach}")

    global_package_list = temp_pkgs

    # We get a list of all dependencies of the global dependencies
    # so that we eclude these from adding the global one
    # otherwise we would get a lot of circular dependencies
    glob_dep_list_to_exclude = []
    global_config.get_global_deps.each do |glob_dep|
        package_get_dependency_list(global_package_list, pkg_get_ref_by_name(global_package_list, glob_dep, glob_dep), glob_dep_list_to_exclude)
        print_any_green("global_deps for #{glob_dep} #{glob_dep_list_to_exclude}")
    end

    global_package_list.each do |pkg|

        namespace :"#{pkg.name}" do

            # Check if the current package is not the one we are adding
            # also we need to check if the current one is included in the 'excluded' list
            # we also need to ensure, that we do not set the global dependency to
            # another package which is also a global dependency, otherwise we would get
            # a circular dependency if we would set 2 global dependencies
            global_config.get_global_deps.each do |glob_dep|
                if((glob_dep != pkg.name) && 
                   (!glob_dep_list_to_exclude.include?(pkg.name)) && 
                   (!global_config.get_global_deps.include?(pkg.name)) )
                    pkg.set_dep(glob_dep)
                end
            end

            task :get_dep_chain => package_add_non_file_task_dep(global_package_list, pkg.deps, "get_dep_chain", pkg.name) do
                global_dep_chain.push("#{pkg.name}")
            end

            desc "depends_chain_print"
            task :depends_chain_print => package_add_non_file_task_dep(global_package_list, pkg.get_name_splitted, "get_dep_chain", pkg.name) do
                print_any_green "DEPENDENCY-CHAIN:"
                global_dep_chain.each do |dep|
                    dep_ref = pkg_get_ref_by_name(global_package_list, dep, pkg.name)
                    tmp_string = ""
                    dep_ref.deps.each do |e|
                        tmp_string << "#{e} "
                    end
                    if tmp_string.to_s == ""
                        print_any_green("#{dep_ref.name}")
                    else
                        print_any_green("#{dep_ref.name} --> " + tmp_string)
                    end
                end
            end

            desc "depends_chain_graph"
            task :depends_chain_graph => package_add_non_file_task_dep(global_package_list, pkg.get_name_splitted, "get_dep_chain", pkg.name) do
                print_any_green("Generating dependency graph for #{pkg.name}")
                dep_graph = DependencyGraph.new(pkg.name)
                global_dep_chain.each do |dep|
                    dep_ref = pkg_get_ref_by_name(global_package_list, dep, pkg.name)
                    dep_graph.add_node("#{dep_ref.name}")

                    dep_ref.deps.each do |e|
                        dep_graph.add_dep("#{dep_ref.name}", "#{e}")
                    end
                end
                dep_graph.draw()
            end

            desc "depends_chain_print_version_hash"
            task :depends_chain_print_version_hash, [:what] => package_add_non_file_task_dep(global_package_list, pkg.get_name_splitted, "get_dep_chain", pkg.name) do |t, args|
                # Do some verbose output
                version_string = ""
                hash = 0
                global_dep_chain.each do |dep|
                    dep_ref = pkg_get_ref_by_name(global_package_list, dep, pkg.name)
                    version_string << "#{dep_ref.version[0]}"
                end
                case args[:what]
                    when "md5"
                        hash = Digest::MD5.hexdigest(version_string)
                    when "sha1"
                        hash = Digest::SHA1.hexdigest(version_string)
                    else
                        print_abort("Invalid argument #{args[:what]}, please specify [md5] or [sha1]")
                end
                print_any_green(hash)
            end



            def create_remfile_generate_file_task(pkg_ref, package_list, remfile, dep_chain)
                Rake::Task["package:create_workdir"].invoke()
                file remfile do
                    dep_ref_array = []
                    dep_chain.each do |dep|
                        dep_ref = pkg_get_ref_by_name(package_list, dep, pkg_ref.name)
                        dep_ref_array.push(dep_ref.recipe_path[0])
                        print_any_green("Writing #{dep_ref.name}")
                    end
                    yaml_store(remfile, "pkg", dep_ref_array)
                end
            end

            desc "remfile_generate"
            task :remfile_generate => package_add_non_file_task_dep(global_package_list, pkg.get_name_splitted, "get_dep_chain", pkg.name) do
                create_remfile_generate_file_task(pkg, global_package_list, global_config.get_remfile(), global_dep_chain)
                Rake::Task["#{global_config.get_remfile()}"].invoke()
            end



            def create_download_file_task(pkg_ref, package_list, tasks_common)

                # As this is the first task in the chain create work directories here:
                Rake::Task["package:create_workdir"].invoke()

                file "#{pkg_ref.pkg_dl_state_file}" do
                    print_any_green "Downloading #{pkg_ref.name}..."
                    pkg_ref.download()
                end
            end

            desc "download"
            task :download do
                print_debug("download: #{pkg.name}")
                create_download_file_task(pkg, global_package_list, 0)
                Rake::Task["#{pkg.pkg_dl_state_file}"].invoke()
            end



            prepare_tasks_common = [ pkg.get_name_splitted, "download" ]
            def create_prepare_file_task(pkg_ref, package_list, tasks_common)

                pkg_prepare_list = package_add_common_task_dep_list(package_list, tasks_common, FILE_TASK, pkg_ref.name)

                # Add source file dependencies and include folders
                # This is quite hacky, but the best solution so far:
                if pkg_ref.uri[0].uri_type == "local"
                    pkg_ref.srcs.each do |e|
                        found = 0
                        pkg_ref.base_dir.each do |dir|
                            if File.exist?("#{dir}/#{e}")
                                pkg_prepare_list.push("#{dir}/#{e}")
                                found = 1
                                break
                            end
                        end
                        if found != 1
                            print_abort("Could not find file #{e} in the following dirs #{pkg_ref.base_dir}")
                        end
                    end

                    # At first find all *.h files:
                    header_files = []
                    pkg_ref.incdirs.each do |e|
                        found = 0
                        pkg_ref.base_dir.each do |dir|
                            if File.exist?("#{dir}/#{e}")
                                header_files.concat(find_files_with_ending("#{dir}/#{e}", "h"))
                                found = 1
                                break
                            end
                        end
                        if found != 1
                            print_abort("Could not find path #{e} in the following dirs #{pkg_ref.base_dir}")
                        end
                    end
                    pkg_prepare_list.concat(header_files)
                end

                file "#{pkg_ref.get_package_state_file("prepare")}" => pkg_prepare_list do
                    print_any_green "Preparing #{pkg_ref.name}..."
                    pkg_ref.prepare_package_state_dir()
                    pkg_ref.prepare()
                    print_debug "#{pkg_ref.name} prepare list: #{pkg_prepare_list}"
                end
            end

            desc "prepare"
            task :prepare => package_add_common_task_dep_list(global_package_list, prepare_tasks_common, NON_FILE_TASK, pkg.name) do
                print_debug("prepare: #{pkg.name}")
                create_prepare_file_task(pkg, global_package_list, prepare_tasks_common)
                Rake::Task["#{pkg.get_package_state_file("prepare")}"].invoke()
            end



            compile_tasks_common = [ pkg.deps, "compile", pkg.get_name_splitted, "prepare" ]
            def create_compile_file_task(pkg_ref, package_list, tasks_common)

                pkg_compile_list = package_add_common_task_dep_list(package_list, tasks_common, FILE_TASK, pkg_ref.name)

                # Prepare include directories of the dependencies
                dep_inc_array = []
                pkg_ref.deps.each do |dep|
                    dep_ref = pkg_get_ref_by_name(package_list, dep, pkg_ref.name)
                    dep_inc_array.concat(dep_ref.inc_dirs_prepared)
                end

                pkg_ref.set_dependency_incdirs(dep_inc_array)
                pkg_ref.incdir_prepare()
                pkg_ref.compile_and_link_prepare()

                # Check for updated header or c files
                header_files = []
                pkg_ref.incdirs.each do |e|
                    header_files.concat(find_files_with_ending("#{pkg_ref.get_pkg_work_dir}/#{e}", "h"))
                end
                pkg_compile_list.concat(header_files)

                c_files = pkg_ref.srcs.map { |element| "#{pkg_ref.get_pkg_work_dir}/#{element}" }
                pkg_compile_list.concat(c_files)

                desc "#{pkg_ref.get_package_state_file("compile")}"
                file "#{pkg_ref.get_package_state_file("compile")}" => pkg_compile_list do
                    print_any_green "Compiling #{pkg_ref.name}..."
                    pkg_ref.compile()
                end
            end

            # The compile task is kind of special, because we need to set all global defines
            # of the dependency chain before we start with any of the upcoming compile tasks.
            # It's a pity that it's not possible to integrate this in create_compile_file_task(),
            # however I haven't found any other solution to this problem yet.
            task :compile_globals_prepare => package_add_non_file_task_dep(global_package_list, pkg.deps, "compile_globals_prepare", pkg.name) do
                # set global defines
                pkg.global_defines.each do |e|
                    global_config.set_define("#{e}")
                end
            end

            desc "compile"
            task :compile => package_add_non_file_task_dep(global_package_list, pkg.get_name_splitted, "compile_globals_prepare", pkg.name) +
                             package_add_common_task_dep_list(global_package_list, compile_tasks_common, NON_FILE_TASK, pkg.name) do
                print_debug("compile: #{pkg.name}")
                create_compile_file_task(pkg, global_package_list, compile_tasks_common)
                Rake::Task["#{pkg.get_package_state_file("compile")}"].invoke()
            end



            link_tasks_common = [ pkg.get_name_splitted, "compile" ]
            def create_link_file_task(pkg_ref, package_list, tasks_common, dep_chain)
                pkg_link_list = package_add_common_task_dep_list(package_list, tasks_common, FILE_TASK, pkg_ref.name)

                # Prepare include directories of the dependencies
                dep_obj_array = []
                dep_chain.each do |dep|
                    dep_ref = pkg_get_ref_by_name(package_list, dep, pkg_ref.name)
                    dep_ref.compile_and_link_prepare()
                    dep_obj_array.concat(dep_ref.obj_files_prepared)

                    # Set global linker flags here, as the linker task does not have any other paralell
                    # executed tasks it is possible to set the linker flags here, locally.
                    global_config.set_link_flag(dep_ref.get_prepared_link_string())
                end

                desc "#{pkg_ref.get_package_state_file("link")}"
                file "#{pkg_ref.get_package_state_file("link")}" =>  pkg_link_list do
                    print_any_green "Linking #{pkg_ref.name}..."
                    pkg_ref.prepare_package_deploy_dir()
                    pkg_ref.link(dep_obj_array)
                end
            end

            desc "link"
            task :link => package_add_common_task_dep_list(global_package_list, link_tasks_common, NON_FILE_TASK, pkg.name) +
                          package_add_non_file_task_dep(global_package_list, pkg.get_name_splitted, "get_dep_chain", pkg.name) do
                print_debug("link: #{pkg.name}")
                create_link_file_task(pkg, global_package_list, link_tasks_common, global_dep_chain)
                Rake::Task["#{pkg.get_package_state_file("link")}"].invoke()
            end



            desc "Do #{pkg.name} image"
            task :image, [:what] => package_add_non_file_task_dep(global_package_list, pkg.get_name_splitted, "link", pkg.name) do |t, args|
                print_any_green "Making image #{pkg.name}..."
                pkg.make_image("#{args[:what]}")
            end



            desc "Do #{pkg.name} clean"
            task :clean, [:what] do |t, args|
                print_any_green "Cleaning #{pkg.name}..."
                case args[:what]
                    when "download"
                        pkg.clean_download()
                    when "prepare"
                        pkg.clean_prepare()
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



            desc "Do #{pkg.name} check dependency chain"
            task :check_deps, [:what, :compile_link, :base_pkg] do |t, args|
                if !args.what
                    print_abort("No package for removal given!")
                end

                if !args.base_pkg
                    print_abort("No base package given!")
                end

                # Prepare globals like global defines to be sure we are using the correct setup
                Rake::Task["package:#{args[:base_pkg]}:compile_globals_prepare"].invoke()

                pkg_to_remove = args[:what]
                print_any_green "Building #{pkg.name} without dep #{pkg_to_remove}"

                if !pkg.deps.include? pkg_to_remove
                    print_abort "Package #{pkg_to_remove} not in list!"
                end
                
                # Now remove one dep, and build again, to check compile step
                print_any_green "Deps before #{pkg.deps}"
                pkg.deps.delete(pkg_to_remove)
                print_any_green "Deps after #{pkg.deps}"

                if args[:compile_link] == "compile"
                    # Remove the task from the prerequisite list:
                    Rake::Task["package:#{pkg.name}:compile"].prerequisites.delete("package:#{pkg_to_remove}:compile")
                    Rake::Task["package:#{pkg.name}:compile"].invoke()
                elsif args[:compile_link] == "link"

                    Rake::Task["package:#{pkg.name}:get_dep_chain"].invoke()

                    # Now remove the one package from the dep list:
                    print_any_green "Deps before #{global_dep_chain}"
                    global_dep_chain.delete(pkg_to_remove)
                    print_any_green "Deps after #{global_dep_chain}"
                    Rake::Task["package:#{pkg.name}:link"].invoke()
                else
                    print_abort "Please specify if link or compile command!"
                end
            end

        end
    end



    task :create_workdir do
        print_debug("Preparing work directories...")
        create_workdir()
    end

    task :remfile_clean do
        print_debug("Deleting #{global_config.get_remfile()}")
        FileUtils.rm_f(global_config.get_remfile())
    end

    task :dirclean do
        print_debug("Deleting basedir #{BASE_DIR}")
        FileUtils.rm_rf("#{BASE_DIR}")
    end

    desc "List available packages"
    task :list_packages do |t, args|
        print_debug ""
        print_debug "Following software packages are available for this architecture: "
        global_package_list.each do |pkg|
            print_debug "#{pkg.name}"
            print_debug "\t\t\t#{pkg.version[0]}"
            print_debug ""
        end
    end
end
