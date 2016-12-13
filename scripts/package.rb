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

        attr_reader :uri

        attr_reader :arch
        attr_reader :mach
        attr_reader :global_defines
        attr_reader :global_linker_flags
        attr_reader :linker_script

        attr_reader :instance_var_to_reset

        # pkg_work_dir: work directory
        attr_reader :pkg_work_dir

        # specific package data - not really used at the moment, but it is intended to
        # be used for build tasks other than the DefaultTasks - please see below:
        # At the moment the this class is only extended by default tasks
        attr_reader :download_specific_data
        attr_reader :prepare_specific_data
        attr_reader :patch_specific_data
        attr_reader :build_specific_data

        ### SETTERS ###

        # No ARRAY values
        def set_name(name)
            @name = name
        end

        def set_unique_hash(hash)
            @unique_hash = hash
        end

        # ARRAY values - (only the first one is used)
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

        def set_linker_script(script)
           (@linker_script = []).concat(string_strip_to_array(script))
        end

        def set_build_specific_data(data)
            (@build_specific_data = []).concat([data])
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

        def get_build_specific_data
            return build_specific_data[0]
        end

    private
        ### Private set methods

        def default_setup_identifiers(recipe_file)
            # Extract the name of the package from the recipe name
            set_name(get_filename_without_extension_from_uri(recipe_file))
            set_unique_hash("nohash")

            (@base_dir||= []).push(get_dirname_from_uri(recipe_file))
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

            @uri = [PackageUri.new("package.local")]

            @arch = set_arch("generic")
            @mach = set_mach("generic")
            @global_defines = []
            @global_linker_flags = []
            @linker_script = set_linker_script("")

            @instance_var_to_reset = []

            @build_specific_data = set_build_specific_data(nil)
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

        def initialize(recipe_file)
            default_setup_identifiers(recipe_file)
            default_setup_settables()

            # OK, we are done with the default setup, now load the recipe file and setup internals
            sw_package_set(self)
            load "./#{recipe_file}"

            # override the above defined function here, this way it is possible
            # to use "sw_package." in the method context also (for e.g if custom build methods are used)
            def sw_package; return self; end

            @src_files_prepared = []
            @obj_files_prepared = []

            @inc_dirs_prepared = []
            @inc_dirs_depends_prepared = []

            @uri[0].parse_uri()

            # Make sanity checks here:
            check_duplicates_exit_with_error(deps, "deps in package #{name}")
            check_duplicates_exit_with_error(srcs, "srcs in package #{name}")
        end

        def post_initialize

            case "#{download_specific_data.class.name}"
                when "NilClass"
                    extend DefaultDownload::DownloadPackage
                else
                    print_abort("Package download_type #{download_specific_data.class.name} not known")
            end

            case "#{prepare_specific_data.class.name}"
                when "NilClass"
                    extend DefaultPrepare::PreparePackageBuildDir
                else
                    print_abort("Package download_type #{prepare_specific_data.class.name} not known")
            end

            case "#{patch_specific_data.class.name}"
                when "NilClass"
                    extend DefaultPatch::Patch
                else
                    print_abort("Package download_type #{patch_specific_data.class.name} not known")
            end

            case "#{build_specific_data[0].class.name}"
                when "NilClass"
                    extend Default::Compile
                    extend Default::Link
                    extend Default::Image
                when "MakeTasksDesc"
                    extend MakePkg::Compile
                    extend MakePkg::Link
                    extend MakePkg::Image
                    print_any_yellow("Using class #{build_specific_data[0].class.name} for package #{name}")
                else
                    print_abort("Package build_type #{build_specific_data[0].class.name} not known")
            end
        end
end

class SoftwarePackageAppend
    include PackageDescriptor

    def initialize(recipe_file)
            # Only setup the identifiers
            default_setup_identifiers(recipe_file)

            # OK, we are done with the default setup, now load the recipe file and setup internals
            sw_package_set(self)
            load "./#{recipe_file}"
    end
end
