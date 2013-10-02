require_relative "nrp"
@nrp_test_path = "/Users/Stomp/Development/Ruby/nrp/nrp-tests/"
@nrp = NRP.new :path => @nrp_test_path << 'nrp1.txt', :ration => 0.5

solution = Array.new(@nrp.customers.size,0)

29.times do |i|
  solution[i-1] = 1
end

puts "budget = #{@nrp.budget}"
puts "cost = #{@nrp.cost(solution)}"
puts "fitness = #{@nrp.fitness(solution)}"
