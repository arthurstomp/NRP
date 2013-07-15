require 'graphviz'
require 'graphviz/theory'

class GraphViz::Math::Matrix
  def enhancements_for_implementation(binary_required_enhancements = Array.new(self.columns, 0))
    raise "Invalid required enhancements. binary_required_enhancements.class(#{binary_required_enhancements.class}) must be an Array" if binary_required_enhancements.class != Array

    #puts "Binary required enhancements = #{binary_required_enhancements.to_s}"

    result_column = Array.new self.lines, 0

    binary_required_enhancements.each_index do |binary_enhancement_index|
      binary_enhancement = binary_required_enhancements[binary_enhancement_index]
      #puts "enhancement = #{binary_enhancement_index + 1} will be implemented = #{binary_enhancement == 1 ? true : false}"
      if binary_enhancement == 1
        column_of_enhancement = self.column binary_enhancement_index + 1
        #puts "Column of enhancement = #{column_of_enhancement.to_s}"
        #puts "result column = #{result_column.to_s}"
        result_column = self.or_columns(result_column, column_of_enhancement)
        #puts "result column after or = #{result_column}"
      end
    end
    result_column = self.or_columns result_column, binary_required_enhancements
  end

  def or_columns(columnA, columnB)
    columnA, columnB = self.column(columnA_index) , self.column(columnB_index) if columnA.class == Fixnum and columnB.class == Fixnum
    raise "The columns dont have the same size" if columnA.size != columnB.size
    result_column = Array.new columnA.size, 0
    columnA.each_index do |i|
      result_column[i] = (columnA[i] == 1 or columnB[i] == 1) ? 1 : 0
    end
    return result_column
  end
end

class NRP
  attr_accessor :id, :costumers, :enhancements, :adjancy_matrix


  def initialize(opt={})
    self.costumers = opt[:costumers] if not opt[:costumers].nil? and opt[:costumers].class == Hash
    self.enhancements = opt[:enhancements] if opt[:enhancements] and opt[:enhancements].class == Hash
    if not opt[:path].nil? 
      if opt[:path][0] != '/'
        pwd = String.new ENV['PWD']
        opt[:path].prepend pwd << '/'
      end
      result = self.class.read_test opt[:path] 
      self.enhancements = result[0]
      self.costumers = result[1]
    end

    if self.adjancy_matrix.nil?
      graph_theory = GraphViz::Theory.new(graph_of_enhancements)
      self.adjancy_matrix = graph_theory.adjancy_matrix
    end
  end

  def required_enhancements_of_costumer(costumer)
    costumer = self.costumers[costumer] if costumer.class == Fixnum
    required_enhancements = costumer.enhancements
    binary_representation_of_required_enhancements = Array.new self.adjancy_matrix.columns, 0
    required_enhancements.each do |enhancement|
      binary_representation_of_required_enhancements[enhancement.to_i - 1] = 1
    end
    return binary_representation_of_required_enhancements
  end

  def cost(costumer_id)
    costumer = self.costumer[costumer_id]
    enhancements_required = costumers.enhancements
    enhancements_required.each do |id|

    end
  end

  def weight(costumer_id)
  end

  def to_s
    raise "enhancements and costumers not loaded" if self.costumers.nil? or self.enhancements.nil?
    enhancements_hash = self.enhancements
    costumers_hash = self.costumers

    nodes_per_level = []
    min_cost_per_level = []
    max_cost_per_level = []
    max_children_per_level = []
    enhancements_hash.each do |key,enhancement|
      level = enhancement.level - 1

      nodes_per_level[level] = 0 if nodes_per_level[level] == nil
      nodes_per_level[level] += 1 

      max_cost_per_level[level] = 0 if max_cost_per_level[level] == nil
      max_cost_per_level[level] = enhancement.cost if max_cost_per_level[level] < enhancement.cost 

      min_cost_per_level[level] = max_cost_per_level[level] if min_cost_per_level[level] == nil
      min_cost_per_level[level] = enhancement.cost if min_cost_per_level[level] > enhancement.cost

      max_children_per_level[level] = 0 if max_children_per_level[level] == nil
      max_children_per_level[level] = enhancement.required_by.count if enhancement.required_by.count > max_children_per_level[level]
    end

    cost_per_level = []
    (0..min_cost_per_level.count - 1).each do |i|
      min = min_cost_per_level[i]
      max = max_cost_per_level[i]
      cost_per_level[i] = "#{min}-#{max}"
    end

    min_enhancements = nodes_per_level.reduce(:+)
    max_enhancements = 0
    costumers_hash.each do |key,costumer|
      min_enhancements = costumer.enhancements.count if min_enhancements > costumer.enhancements.count
      max_enhancements = costumer.enhancements.count if max_enhancements < costumer.enhancements.count
    end
    puts "Cost/Node #{cost_per_level.join("/")}"
    puts "Nodes/Level #{nodes_per_level.join("/")}"
    puts "Maximum Children/node #{max_children_per_level.join("/")}"
    puts "Customers #{costumers_hash.count}"
    puts "Enhancements/Customers #{min_enhancements}-#{max_enhancements}"
  end

  def graph_of_enhancements
    raise "Enhancements arent loaded" if self.enhancements.nil?
    enhancements_hash =  self.enhancements

    enhancements_digraph = GraphViz.new( :enhancements, :type => :digraph )
    nodes_hash = {}
    enhancements_hash.each do |key, value|
      nodes_hash[key] = enhancements_digraph.add_nodes("node#{key}", :label => "#{key}") 
    end

    nodes_hash.each do |key,value|
      enhancement = enhancements_hash[key]
      enhancement.require.each do |enhancement_required|
        edge = enhancements_digraph.add_edges(nodes_hash[enhancement_required], nodes_hash[enhancement.id])
      end
    end
    return enhancements_digraph
  end

  def self.read_test(test_file_path)
    if not File.exist? test_file_path
      raise "File not found"
    end
    test_file = File.open(test_file_path,'r')
    enhancements = []
    enhancements_hash = {}
    levels_of_enhancements = test_file.gets.to_i
    (1..levels_of_enhancements).each do |level|
      number_of_enhancements_at_level  = test_file.gets.to_i
      cost_of_level = test_file.gets.split(" ")
      cost_of_level.each do |cost|
        enhancement = Enhancement.new(cost.to_i)
        enhancement.level = level
        enhancements_hash[enhancement.id] = enhancement
        enhancements << enhancement
      end
    end
    number_of_dependencies = test_file.gets.to_i
    #puts "Number of dependencies = #{number_of_dependencies}"
    (1..number_of_dependencies).each do 
      dependence = test_file.gets.split(" ")
      #puts "dependence #{dependence}"
      required_id = dependence[0].to_i
      enhancement_id = dependence[1].to_i
      destination_enhancement = enhancements_hash[enhancement_id]
      destination_enhancement.require << required_id 
      enhancements_hash[required_id].required_by << destination_enhancement.id
    end
    number_of_costumers = test_file.gets.to_i
    costumers = []
    costumers_hash = {}
    (1..number_of_costumers).each do
      costumer_data = test_file.gets.split(' ')
      costumer = Costumer.new(costumer_data[0], costumer_data[2..-1])
      costumers << costumer
      costumers_hash[costumer.id] = costumer
      #puts "costumer #{costumer.id} weight #{costumer.weight} enhancements #{costumer.enhancements}"
    end
    test_file.close
    Enhancement.reset_id
    Costumer.reset_id
    return [enhancements_hash,costumers_hash]
  end
end

class Enhancement
  @@id_count = 1
  attr_accessor :id , :cost , :require, :required_by, :level

  def initialize(cost)
    self.id = self.class.give_id
    self.cost = cost
    self.require = []
    self.required_by = []
  end

  def self.give_id
    given_id = @@id_count
    @@id_count = @@id_count + 1
    return given_id
  end

  def self.reset_id
    @@id_count = 1
  end
end

class Costumer
  @@id_count = 1
  attr_accessor :id ,:weight, :enhancements

  def initialize(weight,enhancements)
    self.id = self.class.give_id
    self.weight = weight
    self.enhancements = enhancements
  end

  def self.give_id
    given_id = @@id_count
    @@id_count = @@id_count + 1
    return given_id
  end

  def self.reset_id
    @@id_count = 1
  end
end


n = NRP.new :path => 'nrp-tests/article_example.txt'
