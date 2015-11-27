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

module DownloadPackage

    private

        def download_zip(pkg_name, uri)
            execute "wget #{uri} -P #{global_config.get_dl_dir()}/#{pkg_name}"
        end

    public

        def do_download_clean(pkg_name, name)
            FileUtils.rm_rf("#{global_config.get_dl_dir()}/#{pkg_name}")
            FileUtils.rm_rf("#{global_config.get_dl_state_dir()}/#{name}")
        end

        def do_set_download_state(name)
            execute "touch #{global_config.get_dl_state_dir()}/#{name}"
        end

        def do_get_download_state(name)
            return "#{global_config.get_dl_state_dir()}/#{name}"
        end

        def do_download(pkg_name, uri)
            case File.extname(uri)
                when ".local"
                    print_debug "Local package nothing to download"
                when ".zip"
                    print_debug "Zip package"
                    download_zip(pkg_name, uri)
                when ".git"
                    print_debug "Git repo nothing to download"
                else
                    abort('No valid URI type!')
            end
        end
end