require 'test/unit'
require File.dirname(__FILE__) + '/../../client/lib/active_socket'
include ActiveSocket

class CrudTest < Test::Unit::TestCase
  
  def setup
    #set up the server
    @server = Thread.new do
      system "ruby #{File.dirname(__FILE__)}/../server/mini_server.rb"
    end
  end
  
  def teardown
    c = Connection.new("Blog","localhost",4010)
    c.communicate("exit", "blog")
  end
  
  def test_create
    
    # give time for server in setup to start
    sleep 1
    
    # Create our Blog < ActiveSocket::Base class
    Object.const_set("Blog", Class.new(ActiveSocket::Base)).class_eval do
      active_socket_settings :host => "localhost", :port => 4010
    end
    
    # Try to create a record
    b = Object::Blog.new
    b.author_id = 5
    b.title = "testing ActiveSocket"
    assert b.save
    
    # Check that it exists
    saved = Object::Blog.find(:all).size
    assert saved == 1
  end
  
  # def test_read
  #   sleep 1
  #   assert true
  # end
  # 
  # def test_update
  #   sleep 1
  #   assert true
  # end
  # 
  # def test_delete
  #   sleep 1
  #   assert true
  # end
  # 
  # def test_destroy
  #   sleep 1
  #   assert true
  # end
  
end