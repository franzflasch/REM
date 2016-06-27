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

        private

            def do_compile_clean
                FileUtils.rm_rf("#{pkg_state_dir}/compile")
            end

            def do_compile
                print_debug "hey I am the Default compile function"

                print_debug "IncDirsDependsPrepared: #{inc_dirs_depends_prepared}"
                print_debug "IncDirsPrepared: #{inc_dirs_prepared}"
                print_debug "SrcFilesPrepared: #{src_files_prepared}"

                inc_dirs_string = ""
                inc_dirs_depends_prepared.each do |e|
                    inc_dirs_string << "#{e} "
                end
                inc_dirs_prepared.each do |e|
                    inc_dirs_string << "#{e} "
                end

                defines_string = ""

                # local package defines
                defs.each do |e|
                    defines_string << "-D#{e} "
                end

                defines_string << "#{global_config.get_defines()}"

                src_files_prepared.each_with_index  do |src, obj|
                    execute "#{global_config.get_compiler} #{defines_string} #{global_config.get_compile_flags} #{inc_dirs_string} -c #{src} -o #{obj_files_prepared[obj]}"
                end

                if !srcs.empty?
                    # Archive object files into static library:
                    FileUtils.rm_rf("#{pkg_build_dir}/lib#{name}.a")
                    execute "#{global_config.get_archiver} rcs #{pkg_build_dir}/lib#{name}.a #{obj_files_prepared.join(" ")}"
                end
            end
    end

    module Link

        private

            def do_link_clean
                FileUtils.rm_rf("#{pkg_state_dir}/link")
            end

            def do_link(deps)
                print_debug "hey I am the Default link function"
                libs_string = ""
                library_dirs_string = ""

                deps.reverse.each do |e|
                    if !e.srcs.empty?
                        libs_string << "-l#{e.name} "
                        library_dirs_string << "-L#{e.pkg_build_dir} "
                    end
                end
                execute "#{global_config.get_compiler} -static #{global_config.get_link_flags} #{library_dirs_string} #{libs_string} -o #{pkg_deploy_dir}/#{name}.elf"
            end
    end

    module Image

        private

            def do_make_bin
                execute "#{global_config.get_obj_cp} #{global_config.get_obj_copy_flags} -S -O binary #{pkg_deploy_dir}/#{name}.elf #{pkg_deploy_dir}/#{name}.bin"
            end

            def do_make_hex
                execute "#{global_config.get_obj_cp} #{global_config.get_obj_copy_flags} -S -O ihex #{pkg_deploy_dir}/#{name}.elf #{pkg_deploy_dir}/#{name}.hex"
            end
    end
end
