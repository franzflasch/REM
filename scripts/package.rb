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

# This is only used for the recipes
class SoftwarePackage

    attr_accessor :name
    attr_accessor :type
    attr_accessor :srcs
    attr_accessor :incdirs
    attr_accessor :patches
    attr_accessor :deps
    attr_accessor :defs
    attr_accessor :uri
    attr_accessor :arch
    attr_accessor :mach
    attr_accessor :global_defines
    attr_accessor :global_linker_flags
    attr_reader :base_dir

    attr_reader :pkg_build_dir
    attr_reader :pkg_deploy_dir
    attr_reader :pkg_state_dir

    attr_accessor :custom_tasks

    def initialize(pkg_name, base_dir)
        @name = pkg_name
        @type = "default"
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
        @base_dir = base_dir

        @pkg_build_dir = "#{global_config.get_build_dir()}/#{self.name}"
        @pkg_deploy_dir = "#{global_config.get_deploy_dir()}/#{self.name}"
        @pkg_state_dir = "#{global_config.get_state_dir()}/#{self.name}"
    end

    def set_global_define(define)
        self.global_defines.push(define)
    end

    def set_global_linker_flags(flags)
        self.global_linker_flags.push(flags)
    end
end


class Package < SoftwarePackage

    attr_reader :deps_array

    attr_reader :src_array
    attr_reader :src_files_prepared

    attr_reader :obj_files_prepared

    attr_reader :inc_dir_array
    attr_reader :inc_dirs_prepared

    attr_reader :patches_array

    private

        def get_filename_without_extension_from_uri(string, extension)
            return File.basename(string, extension)
        end

        def get_uri_without_extension(string)
            return File.join(File.dirname(string), File.basename(string, '.*'))
        end

        def get_filename_from_uri
            return File.basename(self.uri)
        end

        def set_state_done(which)
            execute "touch #{self.pkg_state_dir}/#{which}"
        end

    public

        def initialize(swpackage_ref)
            @name = swpackage_ref.name
            @type = swpackage_ref.type
            @srcs = swpackage_ref.srcs
            @incdirs = swpackage_ref.incdirs
            @patches = swpackage_ref.patches
            @deps = swpackage_ref.deps
            @defs = swpackage_ref.defs
            @uri = swpackage_ref.uri
            @arch = swpackage_ref.arch
            @mach = swpackage_ref.mach
            @global_defines = swpackage_ref.global_defines
            @global_linker_flags = swpackage_ref.global_linker_flags
            @base_dir = swpackage_ref.base_dir

            @pkg_build_dir = swpackage_ref.pkg_build_dir
            @pkg_deploy_dir = swpackage_ref.pkg_deploy_dir
            @pkg_state_dir = swpackage_ref.pkg_state_dir

            @deps_array = self.deps.split(" ")

            @src_array = self.srcs.split(" ")
            @src_files_prepared = []

            @obj_files_prepared = []

            @inc_dir_array = self.incdirs.split(" ")
            @inc_dirs_prepared = []

            @patches_array = self.patches.split(" ")

            case self.type
                when "default"
                    print_debug "default task"
                    #extend Default::PrepareFoldersPackage
                    #extend Default::DownloadPackage
                    extend DefaultPrepare::PreparePackageBuildDir
                    extend DefaultPatch::Patch
                    extend Default::Compile
                    extend Default::Link
                    extend Default::Image
                # when "SomeOtherTasks"
                #     print_debug "Some other task"
                #     #extend SomeOtherTasks::PrepareFoldersPackage
                #     #extend SomeOtherTasks::DownloadPackage
                #     extend SomeOtherTasks::PreparePackageBuildDir
                #     extend SomeOtherTasks::Compile
                else
                    abort("Package type #{self.type} not known")
            end            
        end

        def get_incdirs
            return self.inc_dirs_prepared
        end

        def get_objs
            return self.obj_files_prepared
        end

        def prepare_package_state_dir
            FileUtils.mkdir_p(self.pkg_state_dir)
        end

        def prepare_package_build_dir
            FileUtils.mkdir_p(self.pkg_build_dir)
        end

        def prepare_package_deploy_dir
            FileUtils.mkdir_p(self.pkg_deploy_dir)
        end

        def prepare
            self.do_prepare_builddir()
            self.do_patch()
            set_state_done("prepare")
        end

        def incdir_prepare(incdirs_depend)
            #print_debug "IncDir dependencies so far: #{incdirs_depend}"
            incdirs_depend.each {|e| self.inc_dirs_prepared.push("#{e}")}
            self.inc_dir_array.each {|e| self.inc_dirs_prepared.push("-I #{self.pkg_build_dir}/#{e}")}
            @inc_dirs_prepared = self.inc_dirs_prepared.uniq
        end

        def compile_prepare
            if self.src_files_prepared.empty?
                self.src_array.each do |e| 
                    self.src_files_prepared.push("#{self.pkg_build_dir}/#{e}")
                    self.obj_files_prepared.push("#{self.pkg_build_dir}/#{get_uri_without_extension(e)}.#{global_config.get_obj_extension}")
                end
            end
        end

        def compile
            print_debug "Compiling package #{self.name}..."
            self.do_compile()
            set_state_done("compile")
        end

        def link(objs)
            print_debug "Linking package #{self.name}..."
            self.do_link(objs)
            set_state_done("link")
        end

        def make_image(which)
            case which
                when "bin"
                    self.do_make_bin()
                when "hex"
                    self.do_make_hex()
                else
                    abort("Invalid image argument!")
            end
        end

        def clean_prepare
            print_debug "cleaning prepare package #{self.name}"
            self.do_prepare_clean()
        end

        def clean_compile
            print_debug "cleaning compile package #{self.name}"
            self.do_compile_clean()
        end

        def clean_link
            print_debug "cleaning link package #{self.name}"
            self.do_link_clean()
        end

        def cleanall
            print_debug "cleaning all for package #{self.name}"
            self.do_prepare_clean()
            self.do_compile_clean()
            self.do_link_clean()
        end
end
