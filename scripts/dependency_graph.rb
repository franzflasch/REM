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

begin
    $dep_graph_support = 1
    require 'ruby-graphviz'
    rescue LoadError
        $dep_graph_support = 0
end

require_relative "print_functions"

class DependencyGraph
    attr_reader :dependency_graph
    attr_reader :node_list
    attr_reader :node_list_str
    attr_reader :filename

    def initialize(output_filename)
        if($dep_graph_support == 0)
            print_abort("No support for ruby-graphviz, please install with gem install ruby-graphviz")
        end
        @dependency_graph = GraphViz.new( :G, :type => :digraph )
        @node_list = []
        @node_list_str = []
        @filename = output_filename
    end

    def get_node_by_name(name)
        result = node_list_str.index(name)
        if result == nil
            return print_abort("ERROR: No node found for package #{name}!")
        else
            return node_list[result]
        end
    end

    def add_node(name)
        @node_list.push(dependency_graph.add_nodes(name))
        @node_list_str.push(name)
    end

    def add_dep(base_node, dependency)
        node = get_node_by_name(base_node)
        dep = get_node_by_name(dependency)

        dependency_graph.add_edges(node, dep)
    end

    def draw()
        dependency_graph.output( :png => "#{filename}.png")
    end
end
