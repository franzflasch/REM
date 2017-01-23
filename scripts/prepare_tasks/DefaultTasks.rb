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
                base_dir.each do |dir|
                    FileUtils.cp_r("#{dir}/.", pkg_build_dir, {:remove_destination => true, :verbose => false})
                end
            end

            def prepare_clone_git
                execute "git clone #{uri[0].uri} #{pkg_build_dir}"
                if(uri[0].uri_src_rev != "undefined")
                    execute "git --git-dir=#{pkg_build_dir}/.git --work-tree=#{pkg_build_dir} checkout #{uri[0].uri_src_rev}"
                end
            end

            def prepare_checkout_svn
                execute "svn co #{uri[0].uri} #{pkg_build_dir}"
                if(uri[0].uri_src_rev != "undefined")
                    # TODO: add possibilty to checkout specific revision
                end
            end

            def prepare_zip
                execute "unzip -qq #{pkg_dl_dir}/#{get_filename_from_uri(uri[0].uri)} -d #{pkg_build_dir}"
            end

            def do_prepare_clean
                FileUtils.rm_rf(pkg_build_dir)
            end

            def do_prepare_builddir
                case uri[0].uri_type
                    when "local"
                        print_debug "LOCAL package"
                    when "zip"
                        print_debug "ZIP package"
                        prepare_zip()
                    when "git"
                        print_debug "GIT repo"
                        prepare_clone_git()
                    when "svn"
                        print_debug "SVN repo"
                        prepare_checkout_svn()
                    else
                        print_abort('No valid URI type!')
                end
                # files need to be copied in every case:
                prepare_copy()
            end
    end
end