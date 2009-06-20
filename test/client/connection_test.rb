require 'test/unit'
require File.dirname(__FILE__) + '/../../client/lib/active_socket'
include ActiveSocket

class ConnectionTest < Test::Unit::TestCase
  
  def setup
    #set up the server
    @server = Thread.new do
      system "ruby #{File.dirname(__FILE__)}/../server/mini_server.rb"
    end
    
    # wait for server to start up
    sleep 1
  end
  
  def teardown
    c = Connection.new("Blog","localhost",4010)
    c.communicate("exit", "blog")
  end
  
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
  
  # Test proper response when client can not find server.
  # Note port does not match mini-server's port.
  def test_noserver
    c = Connection.new("Object","localhost", 4011)
    obj = Object.new
    request = {:t => 'i', :o => obj, :m => "kind_of?", :a => Object}
    r = c.communicate("passalong", "Object", request)
    assert r == false
  end
end