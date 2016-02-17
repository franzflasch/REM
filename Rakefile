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


    #### Behaviour begin: ####

    # At first set the main rakefile base directory
    global_config.set_main_working_dir(Rake.original_dir)

    print_any("Parsing recipes...")
    global_recipe_files = get_recipes()
    global_package_list = prepare_recipes(global_recipe_files)
    
    # All variables which have to be used accross packages must be global for all packages, otherwise
    # we might miss something when linking
    global_pkgs_to_build = ""
    global_dependency_chain = []
    global_incs = []
    global_objs = []

    # Dynamically create tasks:
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

            # Prepare dependencies
            # These variables are used in a local context, and are used for preparing and compiling, here it is not necessary to have all
            # data from every package available
            pkg_depends_chain_list = []
            pkg_depends_compile_list = []
            pkg_depends_link_list = []
            pkg_prepare_list = []
            pkg_compile_list = []
            pkg_link_list = []
            
            pkg.get_deps_array.each do |dep|
                dep_ref = global_package_list.get_ref_by_name(dep)

                if dep_ref.nil?
                    #puts "   \033[31mRed (31)\033[0m\n"
                    print_abort("FAIL: No recipe found for #{dep}, needed by #{pkg.name}. Will abort!")
                end

                pkg_depends_chain_list.push("package:"+dep.to_s + ":depends_chain_get")

                # Especially for the non-file tasks:
                pkg_depends_compile_list.push("package:"+dep.to_s + ":depends_compile")
                pkg_depends_link_list.push("package:"+dep.to_s + ":depends_link")

                # For file tasks:
                pkg_compile_list.push("#{dep_ref.get_package_state_file("prepare")}")
                pkg_compile_list.push("#{dep_ref.get_package_state_file("compile")}")
            end

            # Add dependencies to previous tasks:
            pkg_prepare_list.push("#{pkg.get_download_state_file()}")

            # Add own package to the compile dep list
            pkg_compile_list.push("#{pkg.get_package_state_file("prepare")}")

            # Also add source file dependencies and include folders
            if pkg.get_uri == "package.local"
                pkg.get_src_array.each do |e|
                    pkg_prepare_list.push("#{pkg.get_base_dir}/#{e}")
                end

                # At first find all *.h files:
                header_files = []
                pkg.get_inc_dir_array.each do |e|
                    header_files = find_files_with_ending("#{pkg.get_base_dir}/#{e}".split(" "), "h")                    
                end

                # Now add it to the dependendy list
                header_files.each do |e|
                    pkg_prepare_list.push("#{e}")
                end
            end

            # Also add the own package to the link dep list
            pkg_link_list.push("#{pkg.get_package_state_file("compile")}")

            task :depends_chain_get => pkg_depends_chain_list do |t, args|
                tmp_string = ""
                global_pkgs_to_build << "#{pkg.get_name} "

                pkg.get_deps_array.each do |e|
                    tmp_string << "#{e} "
                end                
                if !pkg.get_deps_array.empty?
                    tmp_string << "<-- #{pkg.get_name} "
                    global_dependency_chain.push("#{tmp_string}");
                end
            end

            desc "Print dependency chain task #{pkg.get_name}"
            task :depends_chain_print => "package:#{pkg.get_name}:depends_chain_get" do |t, args|
                print_any ("")
                print_any ("The package has the following dependencies: ")
                global_dependency_chain.each do |e|
                    print_any("#{e}")
                end
                print_any ("")
                print_any ("The following packages need to be built: ")
                print_any ("#{global_pkgs_to_build}")
            end

            task :depends_compile => pkg_depends_compile_list do |t, args|
                pkg.compile_prepare()
                pkg.incdir_prepare(global_incs)
                pkg.get_incdirs.each do |e|
                    global_incs.push("#{e}")
                end
            end

            task :depends_link => pkg_depends_link_list do |t, args|
                pkg.compile_prepare()
                pkg.get_objs.each do |e|
                    global_objs.push("#{e}")
                end
            end

            desc "#{pkg.get_download_state_file()}"
            file "#{pkg.get_download_state_file()}" do
                # As this is the first task in the chain create work directories here:
                Rake::Task["package:create_workdir"].invoke()

                print_any_green "Downloading #{pkg.get_name}..."
                pkg.download()
            end

            desc "#{pkg.get_package_state_file("prepare")}"
            file "#{pkg.get_package_state_file("prepare")}" => pkg_prepare_list do
                print_any_green "Preparing #{pkg.get_name}..."
                pkg.prepare_package_state_dir()
                pkg.prepare()
                print_debug "#{pkg.get_name} prepare list: #{pkg_prepare_list}"
            end

            desc "#{pkg.get_package_state_file("compile")}"
            file "#{pkg.get_package_state_file("compile")}" =>  pkg_compile_list do
                print_any_green "Compiling #{pkg.get_name}..."
                Rake::Task["package:#{pkg.get_name}:depends_compile"].invoke()
                pkg.compile()   
            end

            desc "#{pkg.get_package_state_file("link")}"
            file "#{pkg.get_package_state_file("link")}" =>  pkg_link_list do
                print_any_green "Linking #{pkg.get_name}..."
                pkg.prepare_package_deploy_dir()
                Rake::Task["package:#{pkg.get_name}:depends_link"].invoke()
                pkg.link(global_objs)
            end

            desc "Do #{pkg.get_name} image"
            task :image, [:what] => "#{pkg.get_package_state_file("link")}" do |t, args|
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
