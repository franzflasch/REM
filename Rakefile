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
require_relative "scripts/package"

require "find"
require "fileutils"


# Main:
namespace :package do

    mk_files = []
    package_list = []

    # This is used for packages to temporarily store the package info in a global variable
    # this is just used for easier handling when defining recipes
    $global_sw_package
    def sw_package; return $global_sw_package; end
    def sw_package_set(pkg); $global_sw_package = pkg; end

    def get_recipes
        project_folders = "#{global_config.get_project_folder()}".split(" ")
        files = []
        files = find_files_with_ending(project_folders, "rem")

        if files.empty?
            abort ("No recipes found!")
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

    def parse_recipe_file_and_fill_package_info(pkg_name, pkg_basedir, recipe_file)
        sw_package_set(SoftwarePackage.new(pkg_name, pkg_basedir))
        load "./#{recipe_file}"

        # Initialize internal recipe infos
        cur_pkg = Package.new(sw_package)

        # Extend custom tasks
        if !sw_package.custom_tasks.nil?
            cur_pkg.extend sw_package.custom_tasks
        end

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
            abort ("ERROR: Duplicates in the recipe list: #{duplicates.uniq}")
        end

        recipes.each do |r|

            print_debug "parsing recipe " + r + ":"

            # Extract the name of the package from the recipe name
            pkg_name = File.basename(r, File.extname(r))
            pkg_basedir = File.dirname(r)

            # Parse and include submakefiles
            cur_pkg = parse_recipe_file_and_fill_package_info(pkg_name, pkg_basedir, r)

            # Do some verbose output
            print_debug "#{cur_pkg.get_info}"

            case cur_pkg.arch
                when "generic"
                    if cur_pkg.mach == "generic"
                        package_ref_list.append("#{cur_pkg.name}", cur_pkg)                        
                    else
                        abort "Invalid ARCH-MACH Combination: arch:#{cur_pkg.arch} mach:#{cur_pkg.mach}"
                    end                    
                when "#{global_config.get_arch()}"
                    if (cur_pkg.mach == "generic" or cur_pkg.mach == "#{global_config.get_mach()}")
                        package_ref_list.append("#{cur_pkg.name}", cur_pkg)
                    else
                        print_debug "MACH Config: #{cur_pkg.mach} does not match - current mach config: #{global_config.get_mach()}, skipping recipe: #{r}"
                    end
                else
                    print_debug "ARCH Config: #{cur_pkg.arch} does not match - current arch config: #{global_config.get_arch()}, skipping recipe: #{r}"
            end
        end

        return package_ref_list
    end


    #### Behaviour begin: ####

    # At first set the main rakefile base directory
    global_config.set_main_working_dir(Rake.original_dir)

    # Always check and prepare for recipes:
    print_any("Preparing work directories...")
    create_workdir()

    print_any("Parsing recipes...")
    mk_files = get_recipes()
    package_list = prepare_recipes(mk_files)
    
    # All variables which have to be used accross packages must be global for all packages, otherwise
    # we might miss something when linking
    dependency_pkgs_to_build = ""
    dependency_chain = []
    dependency_incs = []
    dependency_objs = []

    # Dynamically create tasks:
    package_list.get_ref_list.each do |pkg|
        namespace :"#{pkg.name}" do

            # override the above defined function here, this way it is possible
            # to use "sw_package." in the method context also (for e.g if custom build methods are used)
            def sw_package; return self; end

            # set global defines
            pkg.global_defines.each do |e|
                global_config.set_define("#{e}")
            end

            # set global_linkerflags
            pkg.global_linker_flags.each do |e|
                global_config.set_link_flag("#{e}")
            end

            # Prepare dependencies
            # These variables are used in a local context, and are used for preparing and compiling, here it is not necessary to have all
            # data from every package available
            dep_depends_chain_list = []
            dep_depends_compile_list = []
            dep_depends_link_list = []
            dep_prepare_list = []
            dep_compile_list = []
            dep_link_list = []
            
            pkg.deps_array.each do |dep|
                dep_ref = package_list.get_ref_by_name(dep)
                dep_depends_chain_list.push("package:"+dep.to_s + ":depends_chain_get")

                # Especially for the non-file tasks:
                dep_depends_compile_list.push("package:"+dep.to_s + ":depends_compile")
                dep_depends_link_list.push("package:"+dep.to_s + ":depends_link")

                # For file tasks:
                dep_compile_list.push("#{dep_ref.get_package_state_file("prepare")}")
                dep_compile_list.push("#{dep_ref.get_package_state_file("compile")}")
            end

            # Add dependencies to previous tasks:
            dep_prepare_list.push("#{pkg.get_download_state_file()}")

            # Add own package to the compile dep list
            dep_compile_list.push("#{pkg.get_package_state_file("prepare")}")

            # Also add source file dependencies and include folders
            if pkg.uri == "package.local"
                pkg.src_array.each do |e|
                    dep_prepare_list.push("#{pkg.base_dir}/#{e}")
                end

                # At first find all *.h files:
                header_files = []
                pkg.inc_dir_array.each do |e|
                    header_files = find_files_with_ending("#{pkg.base_dir}/#{e}".split(" "), "h")                    
                end

                # Now add it to the dependendy list
                header_files.each do |e|
                    dep_prepare_list.push("#{e}")
                end
            end

            # Also add the own package to the link dep list
            dep_link_list.push("#{pkg.get_package_state_file("compile")}")

            desc "Do #{pkg.name} clean"
            task :clean, [:what] do |t, args|
                print_any "Cleaning #{pkg.name}..."
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
                        abort("Invalid argument #{args[:what]}")
                end
            end

            task :depends_chain_get => dep_depends_chain_list do |t, args|
                tmp_string = ""
                dependency_pkgs_to_build << "#{pkg.name} "

                pkg.deps_array.each do |e|
                    tmp_string << "#{e} "
                end                
                if !pkg.deps_array.empty?
                    tmp_string << "<-- #{pkg.name} "
                    dependency_chain.push("#{tmp_string}");
                end
            end

            desc "Print dependency chain task #{pkg.name}"
            task :depends_chain_print => "package:#{pkg.name}:depends_chain_get" do |t, args|
                print_any ("")
                print_any ("The package has the following dependencies: ")
                dependency_chain.each do |e|
                    print_any("#{e}")
                end
                print_any ("")
                print_any ("The following packages need to be built: ")
                print_any ("#{dependency_pkgs_to_build}")
            end

            desc "Depends compile task #{pkg.name}"
            task :depends_compile => dep_depends_compile_list do |t, args|
                pkg.compile_prepare()
                pkg.incdir_prepare(dependency_incs)
                pkg.get_incdirs.each do |e|
                    dependency_incs.push("#{e}")
                end
            end

            desc "Depends link task #{pkg.name}"
            task :depends_link => dep_depends_link_list do |t, args|
                pkg.compile_prepare()
                pkg.get_objs.each do |e|
                    dependency_objs.push("#{e}")
                end
            end

            desc "#{pkg.get_download_state_file()}"
            file "#{pkg.get_download_state_file()}" do
                print_any "Downloading #{pkg.name}..."
                pkg.download()
            end

            desc "#{pkg.get_package_state_file("prepare")}"
            file "#{pkg.get_package_state_file("prepare")}" => dep_prepare_list do
                print_any "Preparing #{pkg.name}..."
                pkg.prepare_package_state_dir()
                pkg.prepare()
                print_debug "#{pkg.name} prepare list: #{dep_prepare_list}"
            end

            desc "#{pkg.get_package_state_file("compile")}"
            file "#{pkg.get_package_state_file("compile")}" =>  dep_compile_list do
                print_any "Compiling #{pkg.name}..."
                Rake::Task["package:#{pkg.name}:depends_compile"].invoke()
                pkg.compile()   
            end

            desc "#{pkg.get_package_state_file("link")}"
            file "#{pkg.get_package_state_file("link")}" =>  dep_link_list do
                print_any "Linking #{pkg.name}..."
                pkg.prepare_package_deploy_dir()
                Rake::Task["package:#{pkg.name}:depends_link"].invoke()
                pkg.link(dependency_objs)
            end

            desc "Do #{pkg.name} image"
            task :image, [:what] => "#{pkg.get_package_state_file("link")}" do |t, args|
                print_any "Making image #{pkg.name}..."
                pkg.make_image("#{args[:what]}")
            end
        end
    end

    desc "List available packages"
    task :list_packages do |t, args|
        print_any ""
        print_any "Following software packages are available for this architecture: "
        package_list.get_ref_list.each do |pkg|
            print_any "#{pkg.name}"
        end
    end
end
