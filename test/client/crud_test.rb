require 'rubygems'
require 'shoulda'
require 'test/unit'
require File.dirname(__FILE__) + '/../../client/lib/active_socket'
include ActiveSocket

class CrudTest < Test::Unit::TestCase
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

      # Create our Blog < ActiveRecord::Base class
      Object.const_set("ARBlog", Class.new(ActiveRecord::Base)).class_eval do
        set_table_name "blogs"
        establish_connection(
          :adapter => "sqlite3",
          :database => "#{File.dirname(__FILE__)}/../server/test.sqlite3",
          :pool => 3,
          :timeout => 5000)
      end
          
    end
    
    teardown do
      c = Connection.new("Blog","localhost",4010)
      c.communicate("exit", "blog")
      Object.send(:remove_const, :Blog)
      Object.send(:remove_const, :ARBlog)
    end
    
    context "with a local unsaved instance" do
      setup do
        @b = Object::Blog.new
        @b.author_id = 5
        @b.title = "testing ActiveSocket"
      end
      
      should "be able to create records server-side" do
        # Try to create a record
        assert @b.save

        # Check that it exists serverside (w/o using activesocket)
        assert Object::ARBlog.all.size == 1
      end      
    end

    context "with records stored server-side" do
      setup do
         (1..5).each do |x|
            ar_b = Object::ARBlog.new
            ar_b.author_id = x
            ar_b.title = "foo#{x.to_s}"
            ar_b.save
          end
      end
      
      should "be able to read records from server-side" do
          bsize = Object::Blog.all.size
          assert bsize == 5
          
          # now lets look at a single record
          b = Object::Blog.first
          assert b.author_id == 1
          assert b.title == "foo1"
      end
      
      should "be able to delete all server-side records" do
        Object::Blog.delete_all("id>3")
        assert Object::Blog.all.size == 3
        assert Object::ARBlog.all.size == 3
      end
      
      should "be able to delete some server-side records" do
        single = Object::Blog.first
        single.destroy
        assert single.frozen?
        assert Object::ARBlog.find_by_id(single.id) == nil
      end
      
      context "and a local (unchanged) saved instance" do
        setup do
          @b = Object::Blog.find_by_author_id(1)
        end
        
        should "have no 'changed_attributes'" do
          assert @b.changed == []
        end
      end

      context "and a local (changed aka dirty) saved instance" do
        setup do
          @c = Object::Blog.find_by_author_id(2)
          @c.author_id = 100
          @c.title = "bar"
        end
        
        should "have 'changed_attributes'" do
          assert @c.changed.include? "author_id"
          assert @c.changed.include? "title"
        end
      end
      
      context "and a local changed (and afterwards saved) instance" do
        setup do
          @d = Object::Blog.find_by_author_id(3)
          @d.author_id = 200
          @d.title = "AS Rocks!"
          @d.save
        end
        
        should "have no 'changed_attributes'" do
          assert @d.changed == []
        end
        
        should "show changes server-side" do
          # pull down record via ActiveRecord to verify
          e = Object::ARBlog.find_by_author_id(200)
          assert e.title == "AS Rocks!"
        end
      end
      
    end
    
  end
  
end