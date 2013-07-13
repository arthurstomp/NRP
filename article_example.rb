require 'graphviz'
require 'graphviz/theory'
require_relative 'readTest'
include ReadTest

g = GraphViz.new(:G, :type => :digraph )
n1 = g.add_node "node1",:label => "1"
n2 = g.add_node "node2",:label => "2"
n3 = g.add_node "node3",:label => "3"
n4 = g.add_node "node4",:label => "4"
n5 = g.add_node "node5",:label => "5"
n6 = g.add_node "node6",:label => "6"
n7 = g.add_node "node7",:label => "7"

g.add_edge(n1,n3)
g.add_edge(n1,n4)
g.add_edge(n2,n5)
g.add_edge(n3,n6)
g.add_edge(n4,n7)
g.add_edge(n5,n7)

g.each_node do |n|
  puts n
end

t = GraphViz::Theory.new(g)
puts t.adjancy_matrix
