require 'rubygems'
require 'shoulda'
require 'test/unit'
require File.dirname(__FILE__) + '/../../common/protocol'
include ActiveSocket

class ProtocolTest < Test::Unit::TestCase
  
  context "The Protocol" do
    context "given simple objects as inputs" do
      setup do 
        @inputs = ["Hello, World!", "", nil, true, false, -1, 0, :sym, ["a", "r", "r", "a", "y"], {"ha" => "sh"}]
      end
      
      should "pass along the objects" do
        @inputs.each do |input|
          assert_valid_input(input)
        end
      end
    end
    
    context "given complex objects as inputs" do
      setup do
        @input = Object.new
        @input.instance_variable_set(:@foo, "bar")
      end
      
      should "pass along the objects" do 
        assert_valid_input(@input)
      end
    end
    
  end
  
  #take the input through a round trip
  def assert_valid_input(input)
    
    # round trip
    packed = Protocol.pack(input)
    unpacked = Protocol.unpack(packed)
    
    # dirty way to check if objects identical.
    j = Marshal::dump input
    k = Marshal::dump unpacked
    
    assert j == k
  end
  
end