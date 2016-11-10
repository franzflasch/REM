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

require_relative "../common/sdcc_LinkPrepare"

module Default
    module Compile
        private
            def do_compile_clean
                FileUtils.rm_rf("#{pkg_state_dir}/compile")
            end

            def do_compile
                print_debug "hey I am the SDCC compile function"

                print_debug "IncDirs: #{incdirs}"
                print_debug "IncDirsPrepared: #{inc_dirs_prepared}"
                print_debug "SrcFilesPrepared: #{src_files_prepared}"

                inc_dirs_string = inc_dirs_depends_prepared.map { |element| "-I #{element} " }.join("")
                inc_dirs_string << inc_dirs_prepared.map { |element| "-I #{element} " }.join("")

                defines_string = defs.map { |element| "-D#{element} " }.join("")
                defines_string << "#{global_config.get_defines()}"

                src_files_prepared.each_with_index  do |src, obj|
                    execute "#{global_config.get_compiler} #{defines_string} #{global_config.get_compile_flags()} #{inc_dirs_string} -c #{src} -o #{obj_files_prepared[obj]}"
                end
            end
    end

    module Link
        private
            def do_link_clean
                FileUtils.rm_rf("#{pkg_state_dir}/link")
            end

            def do_prepare_link_string
                return ""
            end

            def do_link(objs)
                print_debug "hey I am the Default link function"
                print_debug "Objects to link: #{objs}"
                objs_string = ""
                objs.each do |e|
                    objs_string << "#{e} "
                end

                execute "#{global_config.get_compiler} #{global_config.get_link_flags()} #{objs_string} -o #{pkg_deploy_dir}/#{name}.ihx"
                #set_state_done("link")
            end
    end

    module Image
        private
            def do_make_bin
            end

            def do_make_hex
            end
    end
end
