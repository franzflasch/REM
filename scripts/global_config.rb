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

require_relative "./config/check_env"
require_relative "./config/config"


class GlobalConfig
    attr_accessor :arch
    attr_accessor :mach

    attr_accessor :project_folder

    attr_accessor :build_dir    
    attr_accessor :state_dir
    attr_accessor :deploy_dir

    attr_accessor :download_dir
    attr_accessor :download_state_dir

    attr_accessor :prefix
    attr_accessor :compiler
    attr_accessor :obj_cp
    attr_accessor :defines
    attr_accessor :compile_flags
    attr_accessor :link_flags
    attr_accessor :compiler_obj_extension

    attr_reader :cc_prefix

    def initialize()
        @arch = ARCH 
        @mach = MACH

        @project_folder = PROJECT_FOLDER

        @build_dir = BUILD_DIR
        @state_dir = STATE_DIR
        @deploy_dir = DEPLOY_DIR

        @download_dir = DL_DIR
        @download_state_dir = DL_STATE_DIR

        @prefix = ""
        @compiler = ""
        @obj_cp = ""
        @defines = []
        @compile_flags = []
        @link_flags = []
        @compiler_obj_extension = "o"

        @cc_prefix = ""
    end

    def get_arch
        return self.arch 
    end

    def get_mach
        return self.mach
    end

    def get_project_folder
        return self.project_folder
    end

    def get_build_dir
        return self.build_dir
    end

    def get_state_dir
        return self.state_dir
    end

    def get_deploy_dir
        return self.deploy_dir
    end

    def get_dl_dir
        return self.download_dir
    end

    def get_dl_state_dir
        return self.download_state_dir
    end

    def set_compiler_prefix(prefix)
        self.prefix = prefix
    end

    def get_compiler_prefix()
        return self.prefix
    end

    def set_compiler(compiler)
        self.compiler = compiler
    end

    def set_obj_cp(obj_cp)
        self.obj_cp = obj_cp
    end

    def get_compiler
        if self.prefix.nil? || self.prefix.empty?
            return "#{self.compiler}"
        else
            return "#{self.prefix}-#{self.compiler}"
        end
    end

    def get_obj_cp
        if self.prefix.nil? || self.prefix.empty?
            return "#{self.obj_cp}"
        else
            return "#{self.prefix}-#{self.obj_cp}"
        end
    end

    def set_define(define)
        self.defines.push(define)
    end

    def get_defines
        defines_string = ""
        self.defines.each do |e|
            defines_string << "-D#{e} "
        end
        return defines_string
    end

    def set_compile_flag(flags)
        self.compile_flags.push(flags)
    end

    def get_compile_flags
        compile_flags_combined = ""
        self.compile_flags.each do |e|
            compile_flags_combined << "#{e} "
        end

        return compile_flags_combined
    end

    def set_link_flag(flags)
        self.link_flags.push(flags)
    end

    def get_link_flags
        link_flags_combined = ""
        self.link_flags.each do |e|
            link_flags_combined << "#{e} "
        end

        return link_flags_combined
    end

    def set_obj_extension(extension)
        self.compiler_obj_extension = "#{extension}"
    end

    def get_obj_extension
        return self.compiler_obj_extension
    end
end

$global_config = GlobalConfig.new()

def global_config
    return $global_config
end
