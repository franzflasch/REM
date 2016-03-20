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
require_relative "machine_conf/#{global_config.arch}/#{global_config.mach}"
require_relative "scripts/#{global_config.compiler}_tasks/DefaultTasks"

# Prepare and Patch tasks:
require_relative "scripts/download_tasks/DefaultTasks"
require_relative "scripts/prepare_tasks/DefaultTasks"
require_relative "scripts/patch_tasks/DefaultTasks"

# Generic
require_relative "scripts/helper"
require_relative "scripts/print_functions"
require_relative "scripts/package"
require_relative "scripts/remfile_gen"

require "find"
require "fileutils"
require 'digest'

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
        recipe_filenames = []
        pkgs = []

        print_debug "Searching for recipes..."

        # Remove directory from all recipes - this is needed to check for duplicates
        recipes.each {|e| recipe_filenames.push(get_filename_from_uri(e))}

        check_duplicates_exit_with_error(recipe_filenames, "recipes")

        recipes.each do |r|

            print_debug "parsing recipe #{r}:"

            # Parse and include submakefiles
            cur_pkg = parse_recipe_file_and_fill_package_info(r)

            # Filter out packages which do not match arch or mach config
            arch_config = cur_pkg.arch
            mach_config = cur_pkg.mach

            if ( (arch_config == "generic") and  (mach_config == "generic") )
                pkgs.push(cur_pkg)
            elsif ( (arch_config == "#{global_config.arch}") and  (mach_config == "generic") )
                pkgs.push(cur_pkg)
            elsif( (arch_config == "generic") and  (mach_config != "generic") )
                print_abort "Invalid ARCH-MACH Combination: arch:#{cur_pkg.arch} mach:#{cur_pkg.mach}"
            elsif( arch_config != "#{global_config.arch}" )
                print_debug "ARCH Config: #{arch_config} does not match - current arch config: #{global_config.arch}, skipping recipe: #{r}"
            elsif ( mach_config != "#{global_config.mach}" )
                print_debug "MACH Config: #{mach_config} does not match - current mach config: #{global_config.mach}, skipping recipe: #{r}"
            else
                pkgs.push(cur_pkg)
            end
        end

        return prepare_pkg_list(pkgs)
    end

    def prepare_pkg_list(pkgs)
        package_ref_list = SoftwarePackageList.new()

        print_debug "Preparing pkgs..."
        pkgs.each do |pkg|
            # We need to extend all build functions here, as they're not
            # restored when loading the yaml file
            pkg.post_initialize()
            print_debug "parsing pkg #{pkg.name}:"
            package_ref_list.append("#{pkg.name}", pkg)
        end
        return package_ref_list
    end

    def package_add_non_file_task_dep(package_list, dependency_list, which, pkg_name)
        dep_str_array = []
        dependency_list.each do |dep|
            dep_ref = package_list.get_ref_by_name(dep, pkg_name)
            dep_str_array.push("package:#{dep_ref.name}:#{which}")
        end
        return dep_str_array
    end

    def package_add_file_task_dep(package_list, dependency_list, which, pkg_name)
        dep_str_array = []
        dependency_list.each do |dep|
            dep_ref = package_list.get_ref_by_name(dep, pkg_name)
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

    #### Behaviour begin: ####

    # At first set the main rakefile base directory
    global_config.set_main_working_dir(Rake.original_dir)
    global_config.set_rakefile_dir(File.dirname(__FILE__))

    # Check if a rem_file was already generated
    if File.exist?(global_config.get_remfile())
        temp_pkgs = yaml_parse(global_config.get_remfile())
        global_package_list = prepare_pkg_list(temp_pkgs)
    else
        print_any("Parsing recipes...")
        global_recipe_files = get_recipes()
        global_package_list = prepare_recipes(global_recipe_files)
    end

    # 'global' variables used across tasks:
    global_dep_chain = []

    global_package_list.ref_list.each do |pkg|

        namespace :"#{pkg.name}" do

            task :get_dep_chain => package_add_non_file_task_dep(global_package_list, pkg.deps_array, "get_dep_chain", pkg.name) do
                global_dep_chain.push("#{pkg.name}")
            end

            desc "depends_chain_print"
            task :depends_chain_print => package_add_non_file_task_dep(global_package_list, pkg.get_name_splitted, "get_dep_chain", pkg.name) do
                global_dep_chain.each do |dep|
                    dep_ref = global_package_list.get_ref_by_name(dep, pkg.name)
                    tmp_string = ""
                    dep_ref.deps_array.each do |e|
                        tmp_string << "#{e} "
                    end
                    if tmp_string.to_s == ""
                        print_any_green("#{dep_ref.name}")
                    else
                        print_any_green("#{dep_ref.name} --> " + tmp_string)
                    end
                end
            end

            desc "depends_chain_print_pkg_info"
            task :depends_chain_print_pkg_info => package_add_non_file_task_dep(global_package_list, pkg.get_name_splitted, "get_dep_chain", pkg.name) do
                # Do some verbose output
                global_dep_chain.each do |dep|
                    dep_ref = global_package_list.get_ref_by_name(dep, pkg.name)
                    print_any_green "#{dep_ref.get_info}"
                end
            end

            desc "depends_chain_print_version_hash"
            task :depends_chain_print_version_hash, [:what] => package_add_non_file_task_dep(global_package_list, pkg.get_name_splitted, "get_dep_chain", pkg.name) do |t, args|
                # Do some verbose output
                version_string = ""
                hash = 0
                global_dep_chain.each do |dep|
                    dep_ref = global_package_list.get_ref_by_name(dep, pkg.name)
                    version_string << "#{dep_ref.version}"
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
                        dep_ref = package_list.get_ref_by_name(dep, pkg_ref.name)
                        dep_ref_array.push(dep_ref)
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

                file "#{pkg_ref.get_download_state_file()}" do
                    # As this is the first task in the chain create work directories here:
                    Rake::Task["package:create_workdir"].invoke()

                    print_any_green "Downloading #{pkg_ref.name}..."
                    pkg_ref.download()
                end
            end

            desc "download"
            task :download do
                print_debug("download: #{pkg.name}")
                create_download_file_task(pkg, global_package_list, 0)
                Rake::Task["#{pkg.get_download_state_file()}"].invoke()
            end



            prepare_tasks_common = [ pkg.get_name_splitted, "download" ]
            def create_prepare_file_task(pkg_ref, package_list, tasks_common)

                pkg_prepare_list = package_add_common_task_dep_list(package_list, tasks_common, FILE_TASK, pkg_ref.name)

                # Add source file dependencies and include folders
                if pkg_ref.uri_type == ".local"
                    pkg_ref.src_array.each do |e|
                        pkg_prepare_list.push("#{pkg_ref.base_dir}/#{e}")
                    end

                    # At first find all *.h files:
                    header_files = []
                    pkg_ref.inc_dir_array.each do |e|
                        header_files.concat(find_files_with_ending("#{pkg_ref.base_dir}/#{e}", "h"))
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



            compile_tasks_common = [ pkg.deps_array, "compile", pkg.get_name_splitted, "prepare" ]
            def create_compile_file_task(pkg_ref, package_list, tasks_common)

                pkg_compile_list = package_add_common_task_dep_list(package_list, tasks_common, FILE_TASK, pkg_ref.name)

                # Prepare include directories of the dependencies
                dep_inc_array = []
                pkg_ref.deps_array.each do |dep|
                    dep_ref = package_list.get_ref_by_name(dep, pkg_ref.name)
                    dep_inc_array.concat(dep_ref.inc_dirs_prepared)
                end

                pkg_ref.set_dependency_incdirs(dep_inc_array)
                pkg_ref.incdir_prepare()
                pkg_ref.compile_and_link_prepare()

                # Check for updated header or c files
                header_files = []
                pkg_ref.inc_dir_array.each do |e|
                    header_files.concat(find_files_with_ending("#{pkg_ref.pkg_build_dir}/#{e}", "h"))
                end
                pkg_compile_list.concat(header_files)

                c_files = pkg_ref.src_array.map { |element| "#{pkg_ref.pkg_build_dir}/#{element}" }
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
            task :compile_globals_prepare => package_add_non_file_task_dep(global_package_list, pkg.deps_array, "compile_globals_prepare", pkg.name) do
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
                    dep_ref = package_list.get_ref_by_name(dep, pkg_ref.name)
                    dep_ref.compile_and_link_prepare()
                    dep_obj_array.concat(dep_ref.obj_files_prepared)

                    # Set global linker flags here, as the linker task does not have any other paralell
                    # executed tasks it is possible to set the linker flags here, locally.
                    dep_ref.global_linker_flags.each do |e|
                        global_config.set_link_flag("#{e}")
                    end
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

    task :remfile_clean do
        print_any("Deleting #{global_config.get_remfile()}")
        FileUtils.rm_f(global_config.get_remfile())
    end


    desc "List available packages"
    task :list_packages do |t, args|
        print_any ""
        print_any "Following software packages are available for this architecture: "
        global_package_list.ref_list.each do |pkg|
            print_any "#{pkg.name}"
        end
    end
end
