require 'rubygems'
require 'shoulda'
require 'test/unit'
require File.dirname(__FILE__) + '/../../client/lib/active_socket'
include ActiveSocket

class StructureTest < Test::Unit::TestCase
  
  context "An AS model" do
    setup do
    
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
  
    teardown do
      c = Connection.new("Blog","localhost",4010)
      c.communicate("exit", "blog")
      Object.send(:remove_const, :Blog)
      Object.send(:remove_const, :Post)
    end 
    
    should "have the same column structure as the server-side AR model" do
      b = Object::Blog.new
    
      c = b.columns.find {|c| c.name == "id"}
      assert_column_integrity(c, :integer)   
       
      c = b.columns.find {|c| c.name == "author_id"}
      assert_column_integrity(c, :integer)
    
      c = b.columns.find {|c| c.name == "title"}
      assert_column_integrity(c, :string)      
    end 
    
    should "have the same associations as the server-side AR model" do
      assert Object::Blog.reflections.size == 1
      assert Object::Blog.reflections[:posts].macro == :has_many
      assert Object::Blog.reflections[:posts].name == :posts
      assert Object::Post.reflections.size == 1
      assert Object::Post.reflections[:blog].macro == :belongs_to
      assert Object::Post.reflections[:blog].name == :blog      
    end
  
    context "calling a server-side-defined custom class method" do
      setup do
        @custom_class_method_results = Object::Blog.custom_class_method
      end
      
      should "be executed server side and return proper results" do
         assert @custom_class_method_results == "hello from a class method"
      end
      
    end
    
    context "calling a server-side-defined custom instance method" do
      setup do    
        b = Object::Blog.new 
        @custom_instance_method_results = b.custom_instance_method
      end
      
      should "be executed server side and return proper results" do
        assert @custom_instance_method_results == "hello from an instance method"
      end
    end
  
  end

  def assert_column_integrity(column, expected_type)
    assert column.type == expected_type
  end
  
end