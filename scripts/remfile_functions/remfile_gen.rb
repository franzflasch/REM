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

require 'yaml'
require 'yaml/store'

def yaml_store(file, fieldname, data)
    store = YAML::Store.new(file)
    store.transaction do
        store[fieldname] = data
    end
end

def yaml_parse(file, append)
    data = YAML::load_file(file)

    recipes = []

    data['pkg'].each do |pkg|
        if append == true
            if pkg.include? ".remappend"
                (recipes||= []).push(pkg)
            end
        else
            if !pkg.include? ".remappend"
                (recipes||= []).push(pkg)
            end
        end
    end

    if recipes.empty? 
        return nil
    else
        return recipes
    end
end
