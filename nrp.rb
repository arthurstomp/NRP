require 'graphviz'
require 'graphviz/theory'

class Array
  def or(other_array)
    raise "Array dont have the same size" if self.size != other_array.size
    result_array = Array.new self.size, 0
    self.each_index do |i|
      result_array[i] = (self[i] == 1 or other_array[i] == 1) ? 1 : 0
    end
    return result_array
  end
end

class GraphViz::Math::Matrix
  def enhancements_for_implementation(binary_required_enhancements = Array.new(self.columns, 0))
    raise "Invalid required enhancements. binary_required_enhancements.class(#{binary_required_enhancements.class}) must be an Array" if binary_required_enhancements.class != Array

    result_column = Array.new self.lines, 0

    binary_required_enhancements.each_index do |binary_enhancement_index|
      binary_enhancement = binary_required_enhancements[binary_enhancement_index]
      if binary_enhancement == 1
        column_of_enhancement = self.column binary_enhancement_index + 1
        result_column = self.or_columns(result_column, column_of_enhancement)
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
  attr_accessor :id, :customers, :enhancements, :budget, :ratio, :adjancy_matrix

  def initialize(opt={})
    self.customers = opt[:customers] if not opt[:customers].nil? and opt[:customers].class == Hash
    self.enhancements = opt[:enhancements] if opt[:enhancements] and opt[:enhancements].class == Hash
    self.ratio = (not opt[:ratio].nil?) ? opt[:ratio] : 0.5
    self.budget = opt[:budget] * self.ratio if opt[:budget]
    
    if not opt[:path].nil? 
      if opt[:path][0] != '/'
        pwd = String.new ENV['PWD']
        opt[:path].prepend pwd << '/'
      end
      result = self.class.read_test opt[:path] 
      self.enhancements = result[0]
      self.customers = result[1]
      cost_of_all_enhancements = result[2]
      self.budget = cost_of_all_enhancements * self.ratio
    end

    if self.adjancy_matrix.nil?
      graph_theory = GraphViz::Theory.new(graph_of_enhancements)
      self.adjancy_matrix = graph_theory.adjancy_matrix
    end
  end

  def required_enhancements_of_customer(customer)
    customer = self.customers[customer] if customer.class == Fixnum
    required_enhancements = customer.enhancements
    binary_representation_of_required_enhancements = Array.new self.adjancy_matrix.columns, 0
    required_enhancements.each do |enhancement|
      binary_representation_of_required_enhancements[enhancement.to_i - 1] = 1
    end
    return self.adjancy_matrix.enhancements_for_implementation binary_representation_of_required_enhancements
  end

  def cost_of_customer(customer_id)
    enhancements_for_implementation = self.adjancy_matrix.enhancements_for_implementation self.required_enhancements_of_customer customer_id
    cost_sum = 0
    enhancements_for_implementation.each_index do |i|
      if  enhancements_for_implementation[i] == 1
        enhancement = self.enhancements[i+1]
        cost_sum += enhancement.cost
      end
    end
    return cost_sum
  end

  def cost_of_enhancements(binary_enhancements)
    raise "Enhancements must be an Array" if binary_enhancements.class != Array
    cost_sum = 0
    binary_enhancements.each_index do |binary_enhancement_index|
      binary_enhancement = binary_enhancements[binary_enhancement_index]
      if binary_enhancement == 1
        enhancement = self.enhancements[binary_enhancement_index + 1]
        cost_sum += enhancement.cost
      end
    end
    return cost_sum
  end

  def treat_customers(customers)
    if customers.class != Array and customers.class == Fixnum
      customers_aux = Array.new(self.customers.size, 0)
      customers_aux[customers - 1] = 1
      customers = customers_aux
    else
    end
    return customers
  end

  def cost(customers)
    customers = self.treat_customers(customers)

    final_required_enhancements = Array.new self.enhancements.size, 0
    customers.each_index do |binary_customer_index|
      binary_customer = customers[binary_customer_index].to_i
      if binary_customer == 1
        final_required_enhancements = final_required_enhancements.or(required_enhancements_of_customer(binary_customer_index + 1))
      end
    end
    return cost_of_enhancements final_required_enhancements
  end

  def gain(customers)
    customers = self.treat_customers(customers)
    gain_sum = 0
    customers.each_index do |i|
      gain_sum += self.customers[i+1].weight.to_i if customers[i].to_i == 1
    end
    return gain_sum
  end

  def viable?(customers)
    customers = self.treat_customers(customers)
    return self.cost(customers) <= self.budget
  end

  def to_s
    raise "enhancements and customers not loaded" if self.customers.nil? or self.enhancements.nil?
    enhancements_hash = self.enhancements
    customers_hash = self.customers

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
    customers_hash.each do |key,customer|
      min_enhancements = customer.enhancements.count if min_enhancements > customer.enhancements.count
      max_enhancements = customer.enhancements.count if max_enhancements < customer.enhancements.count
    end
    puts "Cost/Node #{cost_per_level.join("/")}"
    puts "Nodes/Level #{nodes_per_level.join("/")}"
    puts "Maximum Children/node #{max_children_per_level.join("/")}"
    puts "Customers #{customers_hash.count}"
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
    enhancements_cost_sum = 0
    levels_of_enhancements = test_file.gets.to_i
    (1..levels_of_enhancements).each do |level|
      number_of_enhancements_at_level  = test_file.gets.to_i
      cost_of_level = test_file.gets.split(" ")
      cost_of_level.each do |cost|
        enhancements_cost_sum += cost.to_i
        enhancement = Enhancement.new(cost.to_i)
        enhancement.level = level
        enhancements_hash[enhancement.id] = enhancement
        enhancements << enhancement
      end
    end
    number_of_dependencies = test_file.gets.to_i
    (1..number_of_dependencies).each do 
      dependence = test_file.gets.split(" ")
      required_id = dependence[0].to_i
      enhancement_id = dependence[1].to_i
      destination_enhancement = enhancements_hash[enhancement_id]
      destination_enhancement.require << required_id 
      enhancements_hash[required_id].required_by << destination_enhancement.id
    end
    number_of_customers = test_file.gets.to_i
    customers = []
    customers_hash = {}
    (1..number_of_customers).each do
      customer_data = test_file.gets.split(' ')
      customer = Customer.new(customer_data[0], customer_data[2..-1])
      customers << customer
      customers_hash[customer.id] = customer
    end
    test_file.close
    Enhancement.reset_id
    Customer.reset_id
    return [enhancements_hash,customers_hash,enhancements_cost_sum]
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

class Customer
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

