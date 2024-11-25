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

require_relative "build_functions/package_build_functions"
require_relative "misc/helper_string_parse"

# # This is used for packages to temporarily store the package info in a global variable
# # this is just used for easier handling when defining recipes
$global_sw_package
def sw_package; return $global_sw_package; end
def sw_package_set(pkg); $global_sw_package = pkg; end

class PackageUri
    public
        attr_reader :uri
        attr_reader :uri_type
        attr_reader :uri_src_rev

        def initialize(init_val)
                @uri = init_val
        end

        def parse_uri
            # set uri type:
            tmp_uri_arr = uri
            @uri = uri.split(";")[0]
            if((@uri_type = parse_string(tmp_uri_arr, "type=")) == "undefined")
                @uri_type = get_extension_from_uri(uri)
            end
            @uri_src_rev = parse_string(tmp_uri_arr, "src_rev=")
        end
end


module PackageDescriptor
    public
            # package name
        attr_reader :name
        # unique hash of the package
        attr_reader :unique_hash

        # abs path to rem file:
        attr_reader :recipe_paths
        # base_dir: recipe file location
        attr_reader :base_dir
        # pkg_dl_dir: download location
        attr_reader :pkg_dl_dir
        # pkg_dl_state_file: download state file location
        attr_reader :pkg_dl_state_file
        # pkg_build_dir: build directory
        attr_reader :pkg_build_dir
        # pkg_deploy_dir: output binary deploy directory
        attr_reader :pkg_deploy_dir
        # pkg_state_dir: package build state directory
        attr_reader :pkg_state_dir

        attr_reader :version

        attr_reader :srcs
        attr_reader :incdirs
        attr_reader :patches
        attr_reader :deps
        attr_reader :defs
        attr_reader :local_c_flags
        attr_reader :local_cpp_flags

        attr_reader :uri

        attr_reader :arch
        attr_reader :mach
        attr_reader :global_defines
        attr_reader :global_linker_flags

        # For all packages that want to prepare src files locally, but don't want to
        # use the default linking of objects in the end
        attr_reader :use_default_obj_linking

        attr_reader :instance_var_to_reset

        # pkg_work_dir: work directory
        attr_reader :pkg_work_dir

        ### SETTERS ###

        # No ARRAY values
        def set_name(name)
            @name = name
        end

        def set_unique_hash(hash)
            @unique_hash = hash
        end

        # ARRAY values
        def add_recipe_path(recipe_file)
            (@recipe_paths||= []).push(recipe_file)
        end

        def add_base_dir(recipe_file)
            (@base_dir||= []).push(get_dirname_from_uri(recipe_file))
        end

        def set_uri(uri)
            tmp_str = string_strip(uri).strip
            (@uri = []).concat([PackageUri.new(tmp_str)])
        end

        def set_work_dir(workdir_str)
            tmp_str = string_strip(workdir_str).strip
            (@pkg_work_dir = []).concat(string_strip_to_array("#{pkg_build_dir}/#{tmp_str}"))
        end

        def set_arch(arch)
            (@arch = []).concat(string_strip_to_array(arch))
        end

        def set_mach(mach)
            (@mach = []).concat(string_strip_to_array(mach))
        end

        def set_version(version)
            (@version = []).concat(string_strip_to_array(version))
        end

        # full ARRAY values
        def set_src(src)
            (@srcs ||= []).concat(string_strip_to_array(src))
        end

        def set_inc(inc)
            (@incdirs ||= []).concat(string_strip_to_array(inc))
        end

        def set_patch(patch)
            (@patches ||= []).concat(string_strip_to_array(patch))
        end

        def set_dep(dep)
            (@deps ||= []).concat(string_strip_to_array(dep))
        end

        def set_def(define)
            (@defs ||= []).concat(string_strip_to_array(define))
        end
    
        def set_local_c_flag(c_flag)
            (@local_c_flags ||= []).concat(string_strip_to_array(c_flag))
        end

        def set_local_cpp_flag(cpp_flag)
            (@local_cpp_flags ||= []).concat(string_strip_to_array(cpp_flag))
        end

        def set_global_define(define)
            (@global_defines ||= []).concat(string_strip_to_array(define))
        end

        def set_global_linker_flags(flags)
            (@global_linker_flags ||= []).concat(string_strip_to_array(flags))
        end

        def reset_var(var)
           (@instance_var_to_reset ||= []).concat(string_strip_to_array(var))
        end



        ### GETTERS ###
        def get_package_recipe_files
            return recipe_paths
        end

        def get_package_state_file(which)
            return "#{pkg_state_dir}/#{which}"
        end

        # Returns the name as array-list
        def get_name_splitted
            return name.split
        end

        def get_pkg_work_dir
            return pkg_work_dir[0].strip()
        end

        # Returns first arch entry in array list
        def get_arch
            return arch[0].strip()
        end

        def get_mach
            return mach[0].strip()
        end

    private
        ### Private set methods

        def default_setup_identifiers(recipe_file)
            # Extract the name of the package from the recipe name
            set_name(get_filename_without_extension_from_uri(recipe_file))
            set_unique_hash("nohash")

            add_base_dir(recipe_file)
            add_recipe_path(recipe_file)
        end

        def default_setup_settables()
            @pkg_dl_dir = "#{global_config.get_dl_dir()}/#{name}_#{unique_hash}"
            @pkg_dl_state_file = "#{global_config.get_dl_state_dir()}/#{name}_#{unique_hash}"
            @pkg_deploy_dir = "#{global_config.get_deploy_dir()}/#{name}_#{unique_hash}"
            @pkg_state_dir = "#{global_config.get_state_dir()}/#{name}_#{unique_hash}"
            @pkg_build_dir = "#{global_config.get_build_dir()}/#{name}_#{unique_hash}"
            @pkg_work_dir = [pkg_build_dir]

            @version = set_version("noversion")
            @srcs = []
            @incdirs = []
            @patches = []
            @deps = []
            @defs = []
            @local_c_flags = []
            @local_cpp_flags = []

            @uri = [PackageUri.new("package.local")]

            @arch = set_arch("generic")
            @mach = set_mach("generic")
            @global_defines = []
            @global_linker_flags = []

            @use_default_obj_linking = true;

            @instance_var_to_reset = []
        end

        def set_download_done()
            execute "touch #{pkg_dl_state_file}"
        end

        def set_state_done(which)
            execute "touch #{pkg_state_dir}/#{which}"
        end
end


class SoftwarePackage
    include PackageDescriptor

    public
        # All sources prepared with root directory added
        attr_reader :src_files_prepared
        # All source-extensions replaced with the configured obj-extension
        attr_reader :obj_files_prepared
        attr_reader :inc_dirs_prepared
        attr_reader :inc_dirs_depends_prepared

        # Extend with various modules here
        include PackageBuildFunctions

        def load_package(recipe_file)
            # OK, we are done with the default setup, now load the recipe file and setup internals
            sw_package_set(self)
            load "./#{recipe_file}"

            # override the above defined function here, this way it is possible
            # to use "sw_package." in the method context also (for e.g if custom build methods are used)
            def sw_package; return self; end
        end

        def initialize(recipe_file)
            default_setup_identifiers(recipe_file)
            default_setup_settables()

            load_package(recipe_file)

            @src_files_prepared = []
            @obj_files_prepared = []

            @inc_dirs_prepared = []
            @inc_dirs_depends_prepared = []

            @uri[0].parse_uri()

            # Make sanity checks here:
            check_duplicates_exit_with_error(deps, "deps in package #{name}")
            check_duplicates_exit_with_error(srcs, "srcs in package #{name}")

            extend DownloadPackage
            extend PreparePackageBuildDir
            extend Patch
            extend Compile
            extend Link
            extend Image
        end

        def override_func(name, &block)
            (class << self; self; end).class_eval do
            define_method name, &block
            end
        end

        def invalidate_build_funcs
            # Don't use default linking of objects for
            # recipes which override build funcs
            @use_default_obj_linking = false

            self.override_func :do_compile_clean do
                print_abort("not implemented")
            end

            self.override_func :do_compile do
                print_abort("not implemented")
            end

            self.override_func :do_link_clean do
                print_abort("not implemented")
            end

            self.override_func :do_link do |objs|
                print_abort("not implemented")
            end

            self.override_func :do_make_bin do
                print_abort("not implemented")
            end

            self.override_func :do_make_hex do
                print_abort("not implemented")
            end
        end
end
