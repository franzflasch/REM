=begin
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

require "./scripts/global_config"
require "./machine_conf/#{global_config.get_arch}/#{global_config.get_mach}"
require "./scripts/package_download"
require "./scripts/package_prepare"
require "./scripts/package_patch"
require "./scripts/package"
require "./scripts/#{global_config.compiler}_tasks/DefaultTasks"
require "./scripts/helper"

require "find"
require "fileutils"

def create_OMM_workdir
    FileUtils.mkdir_p(BUILD_DIR)
    FileUtils.mkdir_p(DL_DIR)
    FileUtils.mkdir_p(DL_STATE_DIR)
end

def parse_recipe_file_and_fill_package_info(pkg_name, pkg_basedir, recipe_file)
    src_array = []
    pkg_deps_array = []

    sw_package_set(SoftwarePackage.new(pkg_name, pkg_basedir))
    load "./#{recipe_file}"

    # OBSOLETE: This is a little bit hacky, but the best solution I could find so far:
    # The sw_package object will be filled in the recipe itself, so evaluate the recipe file here:
    #eval(File.open(recipe_file).read)

    cur_pkg = Package.new(sw_package)

    # Extend custom tasks
    if !sw_package.custom_tasks.nil?
        cur_pkg.extend sw_package.custom_tasks
    end

    return cur_pkg
end

namespace :package do
    mk_files = []
    package_list = []

    # This is used for packages to temporarily store the package info in a global variable
    # this is just used for easier handling when defining recipes
    $global_sw_package
    def sw_package; return $global_sw_package; end
    def sw_package_set(pkg); $global_sw_package = pkg; end

    extend DownloadPackage

    def get_package_state_file(name, which)
        return "#{global_config.get_state_dir()}/#{name}/#{which}"
    end

    def get_recipes
        project_folders = "#{global_config.get_project_folder()}".split(" ")
        files = []

        project_folders.each do |e|
            Find.find("#{e}") do |path|
                files << path if path =~ /.*\.rk$/
            end
        end

        if files.empty?
            abort ("No recipes found!")
        end

        print_debug("Found the following recipes:")
        print_debug(files)
        print_debug("")

        return files
    end

    def prepare_recipes(recipes)
        found_packages = []
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
            print_debug "Package: " + cur_pkg.name
            print_debug "Sources: "
            cur_pkg.src_array.each {|src| print_debug "        #{src}"}
            print_debug "Deps: "
            cur_pkg.deps_array.each {|dep| print_debug "        #{dep}"}
            print_debug " "

            print_debug "#{cur_pkg.name} #{cur_pkg.arch} #{cur_pkg.mach}"

            case cur_pkg.arch
                when "generic"
                    if cur_pkg.mach == "generic"
                        found_packages.push(cur_pkg)                        
                    else
                        abort "Invalid ARCH-MACH Combination: arch:#{cur_pkg.arch} mach:#{cur_pkg.mach}"
                    end                    
                when "#{global_config.get_arch()}"
                    if (cur_pkg.mach == "generic" or cur_pkg.mach == "#{global_config.get_mach()}")
                        found_packages.push(cur_pkg)
                    else
                        print_debug "MACH Config: #{cur_pkg.mach} does not match - current mach config: #{global_config.get_mach()}, skipping recipe: #{r}"
                    end
                else
                    print_debug "ARCH Config: #{cur_pkg.arch} does not match - current arch config: #{global_config.get_arch()}, skipping recipe: #{r}"
            end
        end

        return found_packages
    end

    # Always check and prepare for recipes:
    print_any("Preparing work directories...")
    create_OMM_workdir()

    print_any("Parsing recipes...")
    mk_files = get_recipes()
    package_list = prepare_recipes(mk_files)
    
    # All variables which have to be used accross packages must be global for all packages, otherwise
    # we might miss something when linking
    dependency_chain = []
    dependency_incs = []
    dependency_objs = []

    # Dynamically create tasks:
    package_list.each do |pkg|
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
            dep_depends_compile_list = []
            dep_depends_link_list = []
            dep_prepare_list = []
            dep_compile_list = []
            dep_link_list = []
            
            pkg.deps_array.each do |dep|

                # Especially for the non-file tasks:
                dep_depends_compile_list.push("package:"+dep.to_s + ":depends_compile")
                dep_depends_link_list.push("package:"+dep.to_s + ":depends_link")

                # For file tasks:
                dep_compile_list.push("#{get_package_state_file(dep.to_s,"prepare")}")
                dep_compile_list.push("#{get_package_state_file(dep.to_s,"compile")}")
                #dep_link_list.push("#{get_package_state_file(dep.to_s,"compile")}")
            end

            # Add dependencies to previous tasks:
            dep_prepare_list.push("#{do_get_download_state("#{pkg.name}_#{pkg.arch}_#{pkg.mach}")}")

            # Add own package to the compile dep list
            dep_compile_list.push("#{get_package_state_file("#{pkg.name}","prepare")}")

            # Also add source file dependencies
            pkg.src_array.each do |e|
                if pkg.uri == "package.local"
                    dep_prepare_list.push("#{pkg.base_dir}/#{e}")
                end
            end

            # Also add the own package to the link dep list
            dep_link_list.push("#{get_package_state_file("#{pkg.name}","compile")}")

            desc "Do #{pkg.name} clean"
            task :clean, [:what] do |t, args|
                print_any "Cleaning #{pkg.name}..."
                case args[:what]
                    when "download"
                        do_download_clean("#{pkg.name}", "#{pkg.name}_#{pkg.arch}_#{pkg.mach}")
                    when "prepare"
                        pkg.cleanprepare()
                    when "compile"
                        pkg.clean_compile()
                    when "link"
                        pkg.clean_link()
                    when "all"
                        do_download_clean("#{pkg.name}", "#{pkg.name}_#{pkg.arch}_#{pkg.mach}")
                        pkg.cleanall()
                    else
                        abort("Invalid argument #{args[:what]}")
                end
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

            desc "#{do_get_download_state("#{pkg.name}_#{pkg.arch}_#{pkg.mach}")}"
            file "#{do_get_download_state("#{pkg.name}_#{pkg.arch}_#{pkg.mach}")}" do
                print_any "Downloading #{pkg.name}..."
                do_download("#{pkg.name}", "#{pkg.uri}")
                do_set_download_state("#{pkg.name}_#{pkg.arch}_#{pkg.mach}")
            end

            desc "#{get_package_state_file("#{pkg.name}", "prepare")}"
            file "#{get_package_state_file("#{pkg.name}", "prepare")}" => dep_prepare_list do
                print_any "Preparing #{pkg.name}..."
                pkg.prepare_package_state_dir()
                pkg.prepare()
                print_debug "#{pkg.name} prepare list: #{dep_prepare_list}"
            end

            desc "#{get_package_state_file("#{pkg.name}", "compile")}"
            file "#{get_package_state_file("#{pkg.name}", "compile")}" =>  dep_compile_list do
                print_any "Compiling #{pkg.name}..."
                Rake::Task["package:#{pkg.name}:depends_compile"].invoke()
                pkg.compile()   
            end

            desc "#{get_package_state_file("#{pkg.name}", "link")}"
            file "#{get_package_state_file("#{pkg.name}", "link")}" =>  dep_link_list do
                print_any "Linking #{pkg.name}..."
                pkg.prepare_package_deploy_dir()
                Rake::Task["package:#{pkg.name}:depends_link"].invoke()
                pkg.link(dependency_objs)
            end

            desc "Do #{pkg.name} image"
            task :image, [:what] => "#{get_package_state_file("#{pkg.name}", "link")}" do |t, args|
                print_any "Making image #{pkg.name}..."
                pkg.make_image("#{args[:what]}")
            end
        end
    end
end
