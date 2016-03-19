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

module DefaultPrepare
    module PreparePackageBuildDir

        private

            def prepare_copy
                FileUtils.cp_r("#{base_dir}/.", pkg_build_dir, {:verbose => false})
            end

            def prepare_clone_git
                execute "git clone #{uri} #{pkg_build_dir}"
            end

            def prepare_zip
                execute "unzip -qq #{pkg_dl_dir}/#{get_filename_from_uri(uri)} -d #{pkg_build_dir}"
            end

            def do_prepare_clean
                FileUtils.rm_rf(pkg_build_dir)
                FileUtils.rm_rf("#{pkg_state_dir}/prepare")
            end

            def do_prepare_builddir
                case uri_type
                    when ".local"
                        print_debug "Local package"
                    when ".zip"
                        print_debug "Zip package"
                        prepare_zip()
                    when ".git"
                        print_debug "Git repo"
                        prepare_clone_git()
                    else
                        print_abort('No valid URI type!')
                end
                # files need to be copied in every case:
                prepare_copy()
            end
    end
end