=begin

    Copyright (C) 2024 Franz Flasch <franz.flasch@gmx.at>

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

module Patch

    private

        def do_patch
            main_working_dir = Rake.original_dir
            patches.each do |e|
                # try to apply the patch using git am
                ret_success = execute_check_return "git -C #{get_pkg_work_dir} am --keep-cr #{pkg_build_dir}/#{e}"
                if !ret_success
                    # no git patch, use normal patch command, which is less strict than git apply
                    execute "patch -d #{get_pkg_work_dir} -i #{pkg_build_dir}/#{e} -p1 -t"

                    #try to create a git commit of the patch:
                    execute "lsdiff #{pkg_build_dir}/#{e} -p1 | xargs git -C #{get_pkg_work_dir} add"
                    git_commit_files(e)
                end
            end
        end
end
