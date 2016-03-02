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

require_relative "package_build_functions"

# # This is used for packages to temporarily store the package info in a global variable
# # this is just used for easier handling when defining recipes
$global_sw_package
def sw_package; return $global_sw_package; end
def sw_package_set(pkg); $global_sw_package = pkg; end

# Package control functions
module PackageControl

    public

        ### GETTERS ###
        def get_download_state_file()
            return "#{pkg_dl_state_dir}"
        end

        def get_package_state_file(which)
            return "#{pkg_state_dir}/#{which}"
        end

        def get_incdirs_depends_prepared
            return inc_dirs_depends_prepared
        end

        def get_incdirs_prepared
            return inc_dirs_prepared
        end

        def get_objs
            return obj_files_prepared
        end

        def get_global_defines
            return global_defines
        end

        def get_global_linker_flags
            return global_linker_flags
        end

        def get_name
            return name
        end

        def get_version
            return version
        end

        # Returns the name as array-list
        def get_name_splitted
            return name.split
        end

        def get_arch
            return arch
        end

        def get_mach
            return mach
        end

        def get_uri
            return uri
        end

        def get_base_dir
            return base_dir
        end

        def get_deps_array
            return deps_array
        end

        def get_src_array
            return src_array
        end

        def get_inc_dir_array
            return inc_dir_array
        end

        def get_info
            ret_string = "NAME: #{name}\n"
            ret_string << "Version: #{version}\n"
            ret_string << "build_type: #{build_type}\n"
            ret_string << "DEPS: #{deps}\n"
            ret_string << "URI: #{uri}\n"
        end


        ### SETTERS ###
        def set_global_define(define)
            global_defines.push(define)
        end

        def set_global_linker_flags(flags)
            global_linker_flags.push(flags)
        end

        def set_version(version)
            @version = version
        end

        def set_src(src)
            @srcs << string_strip(src)
        end

        def set_inc(inc)
            @incdirs << string_strip(inc)
        end

        def set_dep(dep)
            @deps << string_strip(dep)
        end

        def set_uri(uri)
            @uri = string_strip(uri).strip
        end

        def set_arch(arch)
            @arch = string_strip(arch).strip
        end

        def set_mach(mach)
            @mach = string_strip(mach).strip
        end

        def set_def(define)
            defs.push(string_strip(define))
        end

        def set_patch(patch)
            @patches << string_strip(patch)
        end

        def set_custom_tasks(tasks)
            @custom_tasks = tasks
        end
end

# This is only used for the recipes
class SoftwarePackage

    public
        # package name
        attr_reader :name
        attr_reader :version
        # unique hash of the package
        attr_reader :unique_hash
        # package type - not really used at the moment, but it is intended to
        # be used for build tasks other than the DefaultTasks - please see below:
        # At the moment the this class is only extended by default tasks
        attr_reader :download_type
        attr_reader :prepare_type
        attr_reader :patch_type
        attr_reader :build_type

        attr_reader :srcs
        attr_reader :incdirs
        attr_reader :patches
        attr_reader :deps
        attr_reader :defs
        attr_reader :uri
        attr_reader :arch
        attr_reader :mach
        attr_reader :global_defines
        attr_reader :global_linker_flags
        attr_reader :custom_tasks

        # base_dir: recipe file location
        attr_reader :base_dir
        # pkg_dl_dir: download location
        attr_reader :pkg_dl_dir
        # pkg_dl_state_dir: download state file location
        attr_reader :pkg_dl_state_dir
        # pkg_build_dir: build working directory
        attr_reader :pkg_build_dir
        # pkg_deploy_dir: output binary deploy directory
        attr_reader :pkg_deploy_dir
        # pkg_state_dir: package build state directory
        attr_reader :pkg_state_dir

    private
        # All dependencies stored in an array
        attr_reader :deps_array

        # All sources stored in an array
        attr_reader :src_array
        # All sources prepared with root directory added
        attr_reader :src_files_prepared

        # All source-extensions replaced with the configured obj-extension
        attr_reader :obj_files_prepared

        attr_reader :inc_dir_array
        attr_reader :inc_dirs_prepared
        attr_reader :inc_dirs_depends_prepared

        attr_reader :patches_array

        def set_download_done()
            execute "touch #{pkg_dl_state_dir}"
        end

        def set_state_done(which)
            execute "touch #{pkg_state_dir}/#{which}"
        end

        # Extend with various modules here
        include PackageControl
        include PackageBuildFunctions

    def initialize(recipe_file)
        # Extract the name of the package from the recipe name
        @name = get_filename_without_extension_from_uri(recipe_file)
        @version = "noversion"
        # TODO: implement appropriate way of generating a unique hash of the package
        @unique_hash = "nohash"
        @base_dir = get_dirname_from_uri(recipe_file)

        @download_type = "default"
        @prepare_type = "default"
        @patch_type = "default"
        @build_type = "default"

        @srcs = ""
        @incdirs = ""
        @patches = ""
        @deps = ""
        @defs = []
        @uri = "package.local"
        @arch = "generic"
        @mach = "generic"
        @global_defines = []
        @global_linker_flags = []

        @pkg_dl_dir = "#{global_config.get_dl_dir()}/#{name}_#{unique_hash}"
        @pkg_dl_state_dir = "#{global_config.get_dl_state_dir()}/#{name}_#{unique_hash}"
        @pkg_build_dir = "#{global_config.get_build_dir()}/#{name}_#{unique_hash}"
        @pkg_deploy_dir = "#{global_config.get_deploy_dir()}/#{name}_#{unique_hash}"
        @pkg_state_dir = "#{global_config.get_state_dir()}/#{name}_#{unique_hash}"

        # OK, we are done with the default setup, now load the recipe file and setup internals
        sw_package_set(self)
        load "./#{recipe_file}"

        # override the above defined function here, this way it is possible
        # to use "sw_package." in the method context also (for e.g if custom build methods are used)
        def sw_package; return self; end

        @deps_array = deps.split(" ")
        @src_array = srcs.split(" ")

        @src_files_prepared = []
        @obj_files_prepared = []

        @inc_dir_array = incdirs.split(" ")
        @inc_dirs_prepared = []
        @inc_dirs_depends_prepared = []
        @patches_array = patches.split(" ")

        case download_type
            when "default"
                extend DefaultDownload::DownloadPackage
            else
                abort("Package download_type #{download_type} not known")
        end

        case prepare_type
            when "default"
                extend DefaultPrepare::PreparePackageBuildDir
            else
                abort("Package download_type #{prepare_type} not known")
        end

        case patch_type
            when "default"
                extend DefaultPatch::Patch
            else
                abort("Package download_type #{patch_type} not known")
        end

        case build_type
            when "default"
                extend Default::Compile
                extend Default::Link
                extend Default::Image
            # when "SomeOtherTasks"
            #     print_debug "Some other task"
            #     #extend SomeOtherTasks::DownloadPackage
            #     extend SomeOtherTasks::PreparePackageBuildDir
            #     extend SomeOtherTasks::Compile
            else
                print_abort("Package build_type #{build_type} not known")
        end

        # Extend custom tasks
        if !custom_tasks.nil?
            extend custom_tasks
        end


        # Make sanity checks here:
        check_duplicates_exit_with_error(deps_array, "deps_array in package #{name}")
        check_duplicates_exit_with_error(src_array, "src_array in package #{name}")
    end
end

# Class for associating a package name with the swpackage reference
class SoftwarePackageList
    attr_accessor :name_list
    attr_accessor :ref_list

    def initialize()
        @name_list = []
        @ref_list = []
    end

    def append(name, ref)
        name_list.push(name)
        ref_list.push(ref)
    end

    def get_ref_by_name(name)
        result = name_list.index(name)
        if result == nil
            return print_abort("ERROR: No recipe found for package #{name}!")
        else
            return ref_list[result]
        end
    end

    def get_ref_list
        return ref_list
    end
end
