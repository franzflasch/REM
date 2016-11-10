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

require_relative "../common/#{global_config.compiler}_LinkPrepare"

class MakeTasksDesc

    attr_reader :compile_clean_command
    attr_reader :compile_command
    attr_reader :link_command
    attr_reader :image_command

    def initialize()
            @compile_clean_command = ""
            @compile_command = ""
            @link_command = ""
            @image_command = ""
    end

    def set_compile_clean_command(command)
        @compile_clean_command = command
    end
    def set_compile_command(command)
        @compile_command = command
    end
    def set_link_command(command)
        @link_command = command
    end
    def set_image_command(command)
        @image_command = command
    end
end

module MakePkg
    module Compile
        private
            def do_compile_clean
                execute build_specific_data.compile_clean_command
            end

            def do_compile
                print_debug "hey I am the Make compile function"
                execute build_specific_data.compile_command
            end
    end

    module Link
        private
            def do_link_clean
            end

            include CommonLinkTasks

            def do_link(objs)
                print_debug "Not implemented"
            end
    end

    module Image
        private
            def do_make_bin
                print_debug "Not implemented"
            end

            def do_make_hex
                print_debug "Not implemented"
            end
    end
end
