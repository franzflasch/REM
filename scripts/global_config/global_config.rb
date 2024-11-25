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

require_relative "./config_helper/check_env"
require_relative "./config_helper/config"


class GlobalConfig
    attr_reader :rakefile_dir

    attr_reader :arch
    attr_reader :mach

    attr_reader :project_folder

    attr_reader :build_dir
    attr_reader :state_dir
    attr_reader :deploy_dir

    attr_reader :download_dir
    attr_reader :download_state_dir

    attr_reader :prefix
    attr_reader :compiler_dir
    attr_reader :c_compiler
    attr_reader :cpp_compiler
    attr_reader :obj_cp
    attr_reader :defines
    attr_reader :c_flags
    attr_reader :cpp_flags
    attr_reader :link_flags
    attr_reader :compiler_obj_extension
    attr_reader :obj_copy_flags

    attr_reader :deps

    def initialize()
        @rakefile_dir = ""

        @arch = ARCH
        @mach = MACH

        @project_folder = PROJECT_FOLDER

        @build_dir = BUILD_DIR
        @state_dir = STATE_DIR
        @deploy_dir = DEPLOY_DIR

        @download_dir = DL_DIR
        @download_state_dir = DL_STATE_DIR

        @prefix = ""
        @compiler_dir = ""
        @c_compiler = ""
        @cpp_compiler = ""
        @obj_cp = ""
        @defines = []
        @c_flags = []
        @cpp_flags = []
        @link_flags = []
        @compiler_obj_extension = "o"
        @obj_copy_flags = []

        @deps = []
    end

    # The getter methods should be considered as 'public' and
    # can be called from anywhere:

    def get_rakefile_dir
        return rakefile_dir
    end

    def get_arch
        return arch
    end

    def get_mach
        return mach
    end

    def get_project_folder
        return project_folder
    end

    def get_build_dir
        return build_dir
    end

    def get_state_dir
        return state_dir
    end

    def get_deploy_dir
        return deploy_dir
    end

    def get_dl_dir
        return download_dir
    end

    def get_dl_state_dir
        return download_state_dir
    end

    def get_compiler_prefix()
        return prefix
    end

    def get_c_compiler
        return "#{compiler_dir}#{prefix}#{c_compiler}"
    end

    def get_cpp_compiler
        return "#{compiler_dir}#{prefix}#{cpp_compiler}"
    end

    def get_obj_cp
        return "#{prefix}#{obj_cp}"
    end

    def get_defines
        defines_string = ""
        defines.each do |e|
            defines_string << "-D#{e} "
        end
        return defines_string
    end

    def get_c_flags
        c_flags_combined = ""
        c_flags.each do |e|
            c_flags_combined << "#{e} "
        end

        return c_flags_combined
    end

    def get_cpp_flags
        cpp_flags_combined = ""
        cpp_flags.each do |e|
            cpp_flags_combined << "#{e} "
        end

        return cpp_flags_combined
    end

    def get_link_flags
        link_flags_combined = ""
        link_flags.each do |e|
            link_flags_combined << "#{e} "
        end

        return link_flags_combined
    end

    def get_obj_extension
        return compiler_obj_extension
    end

    def get_obj_copy_flags
        obj_copy_flags_combined = ""
        obj_copy_flags.each do |e|
            obj_copy_flags_combined << "#{e} "
        end

        return obj_copy_flags_combined
    end

    def get_global_deps
        return deps
    end



    # These are the setter methods. They should be considered as 'private'
    # and should only be called from dedicated configure files.

    def set_rakefile_dir(dir)
        @rakefile_dir = dir
    end

    def set_compiler_prefix(prefix)
        @prefix = prefix
    end

    def set_compiler_dir(dir)
        @compiler_dir = dir
    end

    def set_c_compiler(c_compiler)
        @c_compiler = c_compiler
    end

    def set_cpp_compiler(cpp_compiler)
        @cpp_compiler = cpp_compiler
    end

    def set_obj_cp(obj_cp)
        @obj_cp = obj_cp
    end

    def set_define(define)
        @defines.push(define)
    end

    def set_c_flag(flags)
        @c_flags.push(flags)
    end

    def set_cpp_flag(flags)
        @cpp_flags.push(flags)
    end

    def set_link_flag(flags)
        @link_flags.push(flags)
    end

    def set_obj_extension(extension)
        @compiler_obj_extension = "#{extension}"
    end

    def set_objcopy_flag(flags)
        @obj_copy_flags.push(flags)
    end

    def set_global_dep(dep)
        @deps.push(dep)
    end
end

$global_config = GlobalConfig.new()

def global_config
    return $global_config
end
