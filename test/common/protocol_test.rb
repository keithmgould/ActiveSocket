require 'test/unit'
require File.dirname(__FILE__) + '/../../common/protocol'
include ActiveSocket

class ProtocolTest < Test::Unit::TestCase
  
  #Anything that is marshalable is a valid input
  def test_simple_valid_protocol_inputs
    inputs = ["Hello, World!", "", nil, true, false, -1, 0, :sym, ["a", "r", "r", "a", "y"], {"ha" => "sh"}]  
    inputs.each do |input|
      assert_valid_input(input)
    end
  end
  
  def test_complex_valid_protocol_inputs
    input = Object.new
    input.instance_variable_set(:@foo, "bar")
    assert_valid_input(input)
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