require 'test/unit'
require File.dirname(__FILE__) + '/../../client/lib/active_socket'
include ActiveSocket

class StructureTest < Test::Unit::TestCase
  def setup
    
    # NOTE: every time we load mini_server, it wipes the database.
    
    #set up the server
    @server = Thread.new do
      system "ruby #{File.dirname(__FILE__)}/../server/mini_server.rb"
    end
    
    # give time for server to start
    sleep 1
    
    # Create our Blog < ActiveSocket::Base class
    Object.const_set("Blog", Class.new(ActiveSocket::Base)).class_eval do
      active_socket_settings :host => "localhost", :port => 4010
    end
    
    # Create our Post < ActiveSocket::Base class
    Object.const_set("Post", Class.new(ActiveSocket::Base)).class_eval do
      active_socket_settings :host => "localhost", :port => 4010
    end
          
  end
  
  def teardown
    c = Connection.new("Blog","localhost",4010)
    c.communicate("exit", "blog")
    Object.send(:remove_const, :Blog)
    Object.send(:remove_const, :Post)
  end
  
  # Test that custom methods declared in AR model
  # are properly processed when called client-side
  def test_server_methods
    
    # first test the class method
    assert Object::Blog.custom_class_method == "hello from a class method"
    
    # then test the instance method
    b = Object::Blog.new 
    assert b.custom_instance_method == "hello from an instance method"
    
  end
  
  # Make sure client-side structure matches server-side.
  def test_columns
    
    b = Object::Blog.new
    
    c = b.columns.find {|c| c.name == "id"}
    assert_column_integrity(c, :integer)   
       
    c = b.columns.find {|c| c.name == "author_id"}
    assert_column_integrity(c, :integer)
    
    c = b.columns.find {|c| c.name == "title"}
    assert_column_integrity(c, :string)
       
  end
  
  # Make sure the client-side models contain associations defined
  # service-side
  def test_associations
    assert Object::Blog.reflections.size == 1
    assert Object::Blog.reflections[:posts].macro == :has_many
    assert Object::Blog.reflections[:posts].name == :posts
    assert Object::Post.reflections.size == 1
    assert Object::Post.reflections[:blog].macro == :belongs_to
    assert Object::Post.reflections[:blog].name == :blog
  end
  
  def assert_column_integrity(column, expected_type)
    assert column.type == expected_type
  end
  
end