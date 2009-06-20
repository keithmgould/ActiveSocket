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
    
    # Create our Blog < ActiveRecord::Base class
    Object.const_set("ARBlog", Class.new(ActiveRecord::Base)).class_eval do
      set_table_name "blogs"
      establish_connection(
        :adapter => "sqlite3",
        :database => "test.sqlite3",
        :pool => 3,
        :timeout => 5000)
    end
          
  end
  
  def teardown
    c = Connection.new("Blog","localhost",4010)
    c.communicate("exit", "blog")
    Object.send(:remove_const, :Blog)
    Object.send(:remove_const, :ARBlog)
  end
  
  # Test that custom methods declared in AR model
  # are properly processed when called client-side
  def test_server_methods
    
    assert Object::Blog.custom_class_method == "hello from a class method"
    
    b = Object::Blog.new 
    assert b.custom_instance_method == "hello from an instance method"
    
  end
  
  # Make sure client-side 
  def test_columns
    
    b = Object::Blog.new
    
    c = b.columns.find {|c| c.name == "id"}
    assert_column_integrity(c, :integer)   
       
    c = b.columns.find {|c| c.name == "author_id"}
    assert_column_integrity(c, :integer)
    
    c = b.columns.find {|c| c.name == "title"}
    assert_column_integrity(c, :string)
       
  end
  
  def assert_column_integrity(column, expected_type)
    assert column.type == expected_type
  end
  
end