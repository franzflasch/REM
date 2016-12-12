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
                execute "wget -c #{uri[0].uri} -P #{pkg_dl_dir}"
            end

            def do_download_clean
                FileUtils.rm_rf("#{pkg_dl_dir}")
            end

            def do_download
                case uri[0].uri_type
                    when "zip"
                        print_debug "Zip package"
                        download_zip()
                    else
                        print_debug('No zip package, falling through...')
                end
            end
    end
end