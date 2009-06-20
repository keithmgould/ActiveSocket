require 'test/unit'
require File.dirname(__FILE__) + '/../../client/lib/active_socket'
include ActiveSocket

class CrudTest < Test::Unit::TestCase
  
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
  
  def test_create
    
    # Try to create a record
    b = Object::Blog.new
    b.author_id = 5
    b.title = "testing ActiveSocket"
    assert b.save
    
    # Check that it exists
    assert Object::ARBlog.all.size == 1
  end
  
  def test_read
    
    # first write directly to Db via AR
    writes = 5
    writes.times do
      ar_b = Object::ARBlog.new
      ar_b.author_id = 1
      ar_b.title = "foo"
      ar_b.save
    end
  
    # then read with AS
    bsize = Object::Blog.all.size
    assert writes == bsize
    
    # now lets look at a single record
    b = Object::Blog.first
    assert b.author_id == 1
    assert b.title == "foo"
  end
  
  def test_update
    # first create a record with AR
    b = Object::ARBlog.new
    b.author_id = 4
    b.title = "foo"
    b.save
    
    # now fetch the record with AS
    c = Object::Blog.find_by_author_id(4)
    
    #make sure 'changed_attributes' is empty
    assert c.changed == []
    
    #make sure we have the proper record
    assert c.author_id == 4
    assert c.title == "foo"
  
    #change the data
    c.author_id = 5
    c.title = "bar"
    
    #make sure 'changed_attributes' contains author_id and title
    assert c.changed.include? "author_id"
    assert c.changed.include? "title"
    c.save
    
    #make sure 'changed_attributes' is empty
    assert c.changed == []
    
    #pull data vi ActiveRecord and verify changes
    d = Object::ARBlog.find_by_author_id(5)
    assert d.title == "bar"
  end
  
  def test_delete_all
    # first write directly to Db via AR
    writes = 5
    writes.times do
      ar_b = Object::ARBlog.new
      ar_b.author_id = 1
      ar_b.title = "foo"
      ar_b.save
    end
    
    # make sure the records are there (via AR)
    records = Object::ARBlog.all
    assert records.size == writes
    
    # make sure the records are there (via AS)
    records = Object::Blog.all
    assert records.size == writes
    
    #delete records via AS
    Object::Blog.delete_all("id > 3")
    
    # make sure we still exactly 3 records left
    records = Object::Blog.all
    assert records.size == 3
     
  end
  
  def test_destroy
    # first write a record via AR
    b = Object::ARBlog.new
    b.author_id = 5
    b.title = "foo"
    b.save
    
    # make sure it exists
    c = Object::Blog.find_by_author_id(5)
    assert c.title == "foo"
    
    # slaughter
    c.destroy
    
    # make sure local record frozen
    assert c.frozen?
    
    # make sure record gone via AR
    assert Object::ARBlog.all.size == 0
 
  end
  
end