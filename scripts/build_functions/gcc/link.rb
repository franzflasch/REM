=begin

    Copyright (C) 2018 Franz Flasch <franz.flasch@gmx.at>

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

module Link
    private
        def do_link_clean
        end

        def do_prepare_link_string
            tmp_str = ""
            global_linker_flags.each do |e|
                tmp_str.concat("#{e} ")
            end

            return tmp_str
        end

        def do_link(objs)
            print_debug "hey I am the Default link function"
            print_debug "Objects to link: #{objs}"
            objs_string = objs.join(" ")
            execute "#{global_config.get_c_compiler} #{objs_string} #{global_config.get_link_flags} -Wl,-Map=#{pkg_deploy_dir}/#{name}.map -o #{pkg_deploy_dir}/#{name}.elf"
        end
end
