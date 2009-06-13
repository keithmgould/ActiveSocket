require 'test/unit'
require File.dirname(__FILE__) + '/../../client/lib/connection'
require File.dirname(__FILE__) + '/../../server/active_socket'
require File.dirname(__FILE__) + '/../server/mini_server.rb'
include ActiveSocket

class ConnectionTest < Test::Unit::TestCase
  
  def setup
    #set up the server
    @server = Thread.new do
      ActiveSocketServer.new(4010)
    end
  end
  
  def teardown
    Thread.kill(@server)
  end
  
  # Here we connect with the mini_server (see setup above),
  # and use the passalong command to test basic communication.
  # In this test we create a local object, shoot it over to the server,
  # and ask the server if this obj is an Object.  we expect the response
  # to be true.
  
  def test_communication
    c = Connection.new("Object", "localhost", 4010)
    obj = Object.new
    request = {:t => 'i', :o => obj, :m => "kind_of?", :a => Object}
    r = c.communicate("passalong", "Object", request)
    assert r[:r] == true
  end
end