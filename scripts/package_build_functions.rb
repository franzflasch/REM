=begin

    Copyright (C) 2016 Franz Flasch <franz.flasch@gmx.at>

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

module PackageCustomCompile
    def do_compile
        execute custom_build_string
    end
end

module PackageBuildFunctions

        def download
            do_download()
            set_download_done()
        end

        def prepare_package_state_dir
            FileUtils.mkdir_p(pkg_state_dir)
        end

        def prepare_package_build_dir
            FileUtils.mkdir_p(pkg_build_dir)
        end

        def prepare_package_deploy_dir
            FileUtils.mkdir_p(pkg_deploy_dir)
        end

        def prepare
            do_prepare_builddir()
            do_patch()
            set_state_done("prepare")
        end

        def set_dependency_incdirs(inc_dep_array)
            inc_dirs_depends_prepared.concat(inc_dep_array)
        end

        def incdir_prepare()
            #@inc_dirs_prepared = inc_dirs_prepared.uniq
            inc_dir_array.each do |e|
                inc_dirs_prepared.push("-I #{pkg_work_dir}/#{e}")
            end
        end

        def compile_and_link_prepare
            if src_files_prepared.empty?
                src_array.each do |e|
                    src_files_prepared.push("#{pkg_work_dir}/#{e}")
                    obj_files_prepared.push("#{pkg_work_dir}/#{get_uri_without_extension(e)}.#{global_config.get_obj_extension}")
                end
            end
        end

        def compile
            print_debug "Compiling package #{name}..."
            do_compile()
            set_state_done("compile")
        end

        def link(objs)
            print_debug "Linking package #{name}..."
            do_link(objs)
            set_state_done("link")
        end

        def make_image(which)
            case which
                when "bin"
                    do_make_bin()
                when "hex"
                    do_make_hex()
                else
                    abort("Invalid image argument!")
            end
        end

        def clean_download
            print_debug "cleaning prepare package #{name}"
            do_download_clean()
        end

        def clean_prepare
            print_debug "cleaning prepare package #{name}"
            do_prepare_clean()
        end

        def clean_compile
            print_debug "cleaning compile package #{name}"
            do_compile_clean()
        end

        def clean_link
            print_debug "cleaning link package #{name}"
            do_link_clean()
        end

        def cleanall
            print_debug "cleaning all for package #{name}"
            do_download_clean()
            do_prepare_clean()
            do_compile_clean()
            do_link_clean()
        end
end
