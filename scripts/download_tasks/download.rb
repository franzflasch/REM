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

module DownloadPackage

    private

        def download_compressed_file
            #execute "wget -c #{uri[0].uri} -P #{pkg_dl_dir}"
            FileUtils.mkdir_p("#{pkg_dl_dir}")
            execute "curl -o #{pkg_dl_dir}/#{get_filename_from_uri(uri[0].uri)} -LOk #{uri[0].uri}"
        end

        def do_download_clean
            FileUtils.rm_rf("#{pkg_dl_dir}")
        end

        def do_download
            case uri[0].uri_type
                when "zip"
                    print_debug "Zip package"
                    download_compressed_file()
                when "gz"
                    print_debug "GZ package"
                    download_compressed_file()
                else
                    print_debug('No zip package, falling through...')
            end
        end
end
