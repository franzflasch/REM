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

module Compile
    private
        def do_compile_clean
        end

        def do_compile
            print_debug "hey I am the Default compile function"

            print_debug "IncDirsDependsPrepared: #{inc_dirs_depends_prepared}"
            print_debug "IncDirsPrepared: #{inc_dirs_prepared}"
            print_debug "SrcFilesPrepared: #{src_files_prepared}"

            inc_dirs_string = inc_dirs_depends_prepared.map { |element| "-I #{element} " }.join("")
            inc_dirs_string << inc_dirs_prepared.map { |element| "-I #{element} " }.join("")

            defines_string = defs.map { |element| "-D#{element} " }.join("")
            defines_string << "#{global_config.get_defines()}"

            src_files_prepared.each_with_index do |src, index|
                extension = File.extname(src)
                obj = obj_files_prepared[index]

                case extension
                when '.c'
                    compiler = global_config.get_c_compiler
                    compiler_flags = global_config.get_c_flags
                    local_flags_string = local_c_flags.join(' ')
                when '.cpp', '.cc', '.cxx'
                    compiler = global_config.get_cpp_compiler
                    compiler_flags = global_config.get_cpp_flags
                    local_flags_string = local_cpp_flags.join(' ')
                else
                    print_debug "Unknown source file extension for #{src}, skipping."
                    next
                end

                execute "#{compiler} #{defines_string} #{compiler_flags} #{local_flags_string} #{inc_dirs_string} -c #{src} -o #{obj}"
            end
        end
end
