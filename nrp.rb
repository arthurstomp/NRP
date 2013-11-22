require 'rgl/transitivity'
require 'rgl/dot'
require 'rgl/traversal'
require 'rgl/connected_components'

class Array
  def or(other_array)
    raise ArgumentError,"Array dont have the same size" if self.size != other_array.size
    result_array = Array.new self.size, 0
    self.each_index do |i|
      result_array[i] = (self[i] == 1 or other_array[i] == 1) ? 1 : 0
    end
    return result_array
  end

  def column(index)
    if self[index].class == Array
      column = []
      self.each do |line|
        column << line[index]
      end
    else
      column = self[index]
    end
    return column 
  end
  
  def print 
    if self.first.class == Array
      self.each do |item|
        puts item.to_s
      end
    else
      puts self.to_s
    end
  end
end

module RGL::Graph
  def adjancy_matrix
    adjancy_matrix = []
    self.vertices.size.times do 
      adjancy_matrix << Array.new(self.vertices.size, 0)
    end
    self.each_vertex do |vertex_a|
      self.each_adjacent(vertex_a).each do |vertex_b|
        adjancy_matrix[vertex_a-1][vertex_b-1] = 1
      end
    end
    return adjancy_matrix
  end
end

class NRP
  attr_accessor :id, :customers, :enhancements, :budget, :ratio, :adjancy_matrix_of_transitive_closure, :transitive_closure, :graph_of_enhancements

  def load_test(test_path)
    if test_path[0] != '/'
      pwd = String.new ENV['PWD']
      test_path.prepend pwd << '/'
    end
    puts test_path
    result = self.class.read_test test_path
    self.enhancements = result[0]
    self.customers = result[1]
    cost_of_all_enhancements = result[2]
    self.budget = (cost_of_all_enhancements * self.ratio).round
    return true
  end

  def initialize(opt={})
    self.ratio = (not opt[:ratio].nil?) ? opt[:ratio] : 0.5
    if not opt[:path].nil? 
      puts "initialize from a file."
      raise "you must give the path for the test as NRP.new :path => ..." if opt[:path].nil?

      load_test(opt[:path]) if not opt[:path].nil? 
    end


    if not opt[:customers].nil? and not opt[:enhancements].nil?
      puts "initialize with a set of customers and enhancements"
      self.customers = opt[:customers]
      self.enhancements = opt[:enhancements]
      self.budget = (cost_of_all_enhancements * self.ratio).round 
    end

    generate_graph_of_enhancements

    if self.transitive_closure.nil?
      self.transitive_closure = self.graph_of_enhancements.transitive_closure
    end

    if self.adjancy_matrix_of_transitive_closure.nil?
      self.adjancy_matrix_of_transitive_closure = self.transitive_closure.adjancy_matrix
    end
  end

  def cost_of_all_enhancements
    cost_sum = 0
    self.enhancements.each do |key,enhancement|
      cost_sum += enhancement.cost
    end
    cost_sum
  end

  def generate_graph_of_enhancements
    raise "Enhancements arent loaded" if self.enhancements.nil?
    enhancements_hash =  self.enhancements

    enhancements_digraph = RGL::DirectedAdjacencyGraph.new
    enhancements_hash.each do |key, enhancement|
      enhancements_digraph.add_vertex(key) 
      enhancement.require.each do |enhancement_required|
        edge = enhancements_digraph.add_edge(enhancement_required, enhancement.id)
      end
    end

    self.graph_of_enhancements = enhancements_digraph
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

  def enhancements_to_be_implemented(binary_required_enhancements = Array.new(self.adjancy_matrix_of_transitive_closure.size, 0))
    result_column = binary_required_enhancements

    binary_required_enhancements.each_index do |binary_enhancement_index|
      binary_enhancement = binary_required_enhancements[binary_enhancement_index]
      if binary_enhancement == 1
        column_of_enhancement = self.adjancy_matrix_of_transitive_closure.column(binary_enhancement_index)
        result_column = result_column.or column_of_enhancement
      end
    end

    return result_column
  end

  def standardize_enhancements(enhancements)
    standardized_enhancements = Array.new self.adjancy_matrix_of_transitive_closure.size, 0
    enhancements.each do |enhancement|
      standardized_enhancements[enhancement.to_i - 1] = 1
    end
    return standardized_enhancements
  end

  def required_enhancements_of_customer(customer)
    customer = self.customers[customer] if customer.class == Fixnum
    required_enhancements = self.standardize_enhancements(customer.enhancements)
    return enhancements_to_be_implemented required_enhancements
  end

  def cost_of_enhancements(binary_enhancements)
    raise "Enhancements must be an Array" if binary_enhancements.class != Array
    cost_sum = 0
    binary_enhancements.each_index do |binary_enhancement_index|
      binary_enhancement = binary_enhancements[binary_enhancement_index]
      if binary_enhancement == 1
        cost_sum += self.enhancements[binary_enhancement_index + 1].cost
      end
    end
    return cost_sum
  end

  def standardize_customers(customers)
    if customers.class != Array and customers.class == Fixnum
      customers_aux = Array.new(self.customers.size, 0)
      customers_aux[customers - 1] = 1
      customers = customers_aux
    elsif customers.class == Array
      customers.each_index do |i|
        customers[i] = customers[i].to_i
      end
    end
    return customers
  end

  def cost(customers)
    standardized_customers = self.standardize_customers(customers)

    final_required_enhancements = Array.new self.enhancements.size, 0
    standardized_customers.each_index do |standardized_customer_index|
      if standardized_customers[standardized_customer_index] == 1
        final_required_enhancements = final_required_enhancements.or(required_enhancements_of_customer(standardized_customer_index + 1))
      end
    end
    return cost_of_enhancements(final_required_enhancements)
  end

  def weight(customers)
    customers = self.standardize_customers(customers)
    weight_sum = 0
    customers.each_index do |i|
      weight_sum += self.customers[i+1].weight.to_i if customers[i].to_i == 1
    end
    return weight_sum
  end

  def fitness(customers)
    cost = self.cost(customers)
    if self.budget - cost > 0
      return self.weight(customers)
    else
      return self.budget - cost
    end
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

  def save_into_file(file_path)
    file = File.open(file_path,'w')
    enhancements_per_level = self.enhancements_per_level
    file.puts(enhancements_per_level.size)
    
    enhancements_per_level.each do |key,enhancements_of_level|
      file.puts(enhancements_of_level.size)
      enhancements_of_level.each do |enhancement|
        file.print("#{enhancement.id} ")
      end
      file.puts
    end

    enhancements_links = self.enhancements_links
    file.puts enhancements_links.size
    enhancements_links.each do |link|
      file.puts "#{link[0]} #{link[1]}"
    end

    file.puts self.customers.size
    self.customers.each do |key,customer|
      file.print "#{customer.weight} "
      file.print "#{customer.enhancements.size} "
      customer.enhancements.each do |enhancement_id|
        file.print "#{enhancement_id} "
      end
      file.puts 
    end
    file.close
  end

  def enhancements_per_level
    levels = {}
    self.enhancements.each do |key,enhancement|
      if not levels.include?(enhancement.level)
        levels[enhancement.level] = [enhancement]
      else
        levels[enhancement.level] << enhancement
      end
    end
    levels
  end

  def enhancements_links 
    links = []
    self.enhancements.each do |key,enhancement|
      enhancement.require.each do |require_id|
        links << [require_id, enhancement.id]
      end
    end
    links
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
