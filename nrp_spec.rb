require_relative 'nrp'

def generate_article_graph
    article_graph = RGL::DirectedAdjacencyGraph.new

    article_graph.add_vertex(1)
    article_graph.add_vertex(2)
    article_graph.add_vertex(3)
    article_graph.add_vertex(4)
    article_graph.add_vertex(5)
    article_graph.add_vertex(6)
    article_graph.add_vertex(7)

    article_graph.add_edge(1,3)
    article_graph.add_edge(1,4)
    article_graph.add_edge(3,6)
    article_graph.add_edge(4,7)
    article_graph.add_edge(2,5)
    article_graph.add_edge(5,7)
    return article_graph
end

RSpec.configure do |config|
  config.before(:all) {
    @article_graph = generate_article_graph
    @article_test_path = '/Users/Stomp/Development/Ruby/nrp/nrp-tests/article_example.txt'
  }
end

describe Array, ".or" do
  it "two arrays perfectly" do
    a = [1,0,0,1]
    b = [0,1,1,0]
    a.or(b).should eq([1,1,1,1])
  end

  it "two arrays with diferent lenght" do
    a = [1,0,0,1]
    b = [0,0,0]
    expect{a.or(b)}.to raise_error(ArgumentError)
  end
end

describe Array, ".column" do 
  it "get column of a matrix" do
    m = [[1,0],[0,1]]
    m.column(0).should eq([1,0])
  end

  it "get column of a array" do
    m = [1,0]
    m.column(0).should eq(1)
  end
end

describe RGL::Graph do
  it "generate adjancy matrix" do
    adjancy_matrix = [
      [0,0,1,1,0,0,0],
      [0,0,0,0,1,0,0],
      [0,0,0,0,0,1,0],
      [0,0,0,0,0,0,1],
      [0,0,0,0,0,0,1],
      [0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0]
    ]
    @article_graph.adjancy_matrix.should eq(adjancy_matrix)
  end
end

describe Enhancement do
  it "create enhancement" do
    enhancement = Enhancement.new 10
    enhancement.id.should eq 1
    enhancement.cost.should eq 10
    enhancement.require.should be_a_kind_of Array
    enhancement.required_by.should be_a_kind_of Array
  end

  it "id assingment" do
    5.times { Enhancement.new 10}
    Enhancement.give_id.should eq 7
  end

  it "reset id assingment" do
    5.times { Enhancement.new 10}
    Enhancement.reset_id
    Enhancement.give_id.should eq 1
  end
end

describe Customer do 

end
