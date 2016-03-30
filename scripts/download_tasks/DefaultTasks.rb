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

module DefaultDownload
    module DownloadPackage

        private

            def download_zip
                execute "wget -c #{uri} -P #{pkg_dl_dir}"
            end

            def do_download_clean
                FileUtils.rm_rf("#{pkg_dl_dir}")
                FileUtils.rm_rf("#{pkg_dl_state_dir}")
            end

            def do_download
                case uri_type
                    when "local"
                        print_debug "Local package nothing do download"
                    when "zip"
                        print_debug "Zip package"
                        download_zip()
                    when "git"
                        print_debug "git uri, nothing to download"
                    else
                        print_abort('No valid URI type!')
                end
            end
    end
end