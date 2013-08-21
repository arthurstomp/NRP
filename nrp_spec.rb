require_relative 'nrp'

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
