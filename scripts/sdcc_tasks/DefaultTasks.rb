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

module Default
    module Compile

        public

            def do_compile_clean
                FileUtils.rm_rf("#{pkg_state_dir}/compile")
            end

            def do_compile
                print_debug "hey I am the SDCC compile function"

                print_debug "IncDirs: #{self.incdirs}"
                print_debug "IncDirsPrepared: #{self.inc_dirs_prepared}"
                print_debug "SrcFilesPrepared: #{self.src_files_prepared}"

                inc_dirs_string = ""
                self.inc_dirs_prepared.each do |e|
                    inc_dirs_string << "#{e} "
                end

                defines_string = ""

                # local package defines
                self.defs.each do |e|
                    defines_string << "-D#{e} "
                end

                defines_string << "#{global_config.get_defines()}"

                src_files_prepared.each_with_index  do |src, obj|
                    execute "#{global_config.get_compiler} #{defines_string} #{global_config.get_compile_flags()} #{inc_dirs_string} -c #{src} -o #{self.obj_files_prepared[obj]}"
                end
            end
    end

    module Link

        public

            def do_link_clean
                FileUtils.rm_rf("#{pkg_state_dir}/link")
            end

            def do_link(objs)
                print_debug "hey I am the Default link function"
                print_debug "Objects to link: #{objs}"
                objs_string = ""
                objs.each do |e|
                    objs_string << "#{e} "
                end

                execute "#{global_config.get_compiler} #{global_config.get_link_flags()} #{objs_string} -o #{self.pkg_deploy_dir}/#{self.name}.ihx"
                #set_state_done("link")
            end
    end

    module Image

        public

        def do_make_bin
        end

        def do_make_hex
        end
    end
end
