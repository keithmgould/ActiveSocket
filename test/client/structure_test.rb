require 'rubygems'
require 'ruby-debug'
require 'shoulda'
require 'test/unit'
require File.dirname(__FILE__) + '/../../client/lib/active_socket'
include ActiveSocket

class StructureTest < Test::Unit::TestCase
  
  context "An AS model" do
    setup do
      puts "\n----------------------------------------------------------in setup An AS model\n"
      # NOTE: every time we load mini_server, it wipes the database.
    
      #set up the server
      @server = Thread.new do
        system "ruby #{File.dirname(__FILE__)}/../server/mini_server.rb"
      end
    
      # give time for server to start
      puts "\n-------------about to wait 5 sec (#{Time.new})\n"
      sleep 5
      puts "\n-------------waited 5 sec. (#{Time.new})\n"
      
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
      puts "\n-------------in teardown An AS model\n"
      c = Connection.new("Blog","localhost",4010)
      c.communicate("exit", "blog")
      Object.send(:remove_const, :Blog)
      Object.send(:remove_const, :Post)
    end 
    
    # should "have the same column structure as the server-side AR model" do
    #   puts ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    #   b = Object::Blog.new
    # 
    #   c = b.columns.find {|c| c.name == "id"}
    #   assert_column_integrity(c, :integer)   
    #    
    #   c = b.columns.find {|c| c.name == "author_id"}
    #   assert_column_integrity(c, :integer)
    # 
    #   c = b.columns.find {|c| c.name == "title"}
    #   assert_column_integrity(c, :string)      
    # end 
    # 
    # should "have the same associations as the server-side AR model" do
    #   puts ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    #   assert Object::Blog.reflections.size == 1
    #   assert Object::Blog.reflections[:posts].macro == :has_many
    #   assert Object::Blog.reflections[:posts].name == :posts
    #   assert Object::Post.reflections.size == 1
    #   assert Object::Post.reflections[:blog].macro == :belongs_to
    #   assert Object::Post.reflections[:blog].name == :blog      
    # end
    
    context "calling a named-scope" do
      setup do
        puts "\n-------------in setup calling a named-scope\n"
        @meets_both = Object::Blog.create(:publisher => "random house", :published_on => 1.day.ago.to_date, :author_id => 5, :title => "aaa")
        @meets_date = Object::Blog.create(:published_on => 1.day.ago.to_date, :author_id => 6, :title => "bbb")
        @meets_neither = Object::Blog.create(:published_on => 3.week.ago.to_date, :author_id => 7, :title => "ccc")        
        @meets_publisher = Object::Blog.create(:publisher => "miracle", :published_on => 3.week.ago.to_date, :author_id => 8, :title => "ddd")
      end
      
      #  should "return a named-scope" do
      #    puts ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
      #   
      #    assert_equal ActiveRecord::NamedScope::Scope, Object::Blog.with_publisher.class
      #    assert_equal ActiveRecord::NamedScope::Scope, Object::Blog.published_this_week.class
      #  end
      #  
      # should "enable access to array of results, and not leave lingering scopes" do
      #   puts ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> enable access to array of results"
      #   assert_equal 4, Object::Blog.all.size
      #   assert_equal 2, Object::Blog.with_publisher.size
      #   assert_equal 4, Object::Blog.all.size
      #   assert_equal 2, Object::Blog.published_this_week.size
      #   assert_equal 4, Object::Blog.all.size
      # end
      
      should "chain properly regardless of order of named scopes, and not leave lingering scopes" do
        puts ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> chain properly"
        assert_equal 4, Object::Blog.all.size
        assert_equal [@meets_both], Object::Blog.with_publisher.published_this_week
        assert_equal 4, Object::Blog.all.size
        assert_equal [@meets_both], Object::Blog.published_this_week.with_publisher
        assert_equal 4, Object::Blog.all.size
      end
    end
  
    # context "calling a server-side-defined custom class method" do
    #   setup do
    #     @custom_class_method_results = Object::Blog.custom_class_method
    #   end
    #   
    #   should "be executed server side and return proper results" do
    #     puts ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    #     assert @custom_class_method_results == "hello from a class method"
    #   end
    #   
    # end
    # 
    # context "calling a server-side-defined custom instance method" do
    #   setup do    
    #     b = Object::Blog.new 
    #     @custom_instance_method_results = b.custom_instance_method
    #   end
    #   
    #   should "be executed server side and return proper results" do
    #     puts ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    #     assert @custom_instance_method_results == "hello from an instance method"
    #   end
    # end
  
  end

  # def assert_column_integrity(column, expected_type)
  #   assert column.type == expected_type
  # end
  
end